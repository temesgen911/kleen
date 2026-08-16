import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleaning_ai/models/captured_image.dart';
import 'package:cleaning_ai/models/scanner_session.dart';
import 'package:cleaning_ai/services/image_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDirectory;
  FakePathProviderPlatform(this.tempDirectory);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDirectory.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDocsDir;

  setUp(() async {
    testDocsDir = await Directory.systemTemp.createTemp('cleaning_ai_test_docs_');
    PathProviderPlatform.instance = FakePathProviderPlatform(testDocsDir);
  });

  tearDown(() async {
    if (await testDocsDir.exists()) {
      await testDocsDir.delete(recursive: true);
    }
  });

  group('CapturedImage Entity & Normalization Pipeline', () {
    test('CapturedImage model holds complete metadata and supports JSON serialization', () {
      final img = CapturedImage(
        id: 'img_test_123',
        filePath: '/data/app/scans/session_1/living_room/img_test_123.jpg',
        roomName: 'Living Room',
        orderIndex: 1,
        width: 1920,
        height: 1080,
        orientationDegrees: 90,
        fileSizeBytes: 2048500,
        sourceType: ImageSourceType.camera,
      );

      expect(img.id, 'img_test_123');
      expect(img.isPortrait, isFalse);
      expect(img.aspectRatio, closeTo(1920 / 1080, 0.001));
      expect(img.sourceType, ImageSourceType.camera);
      expect(img.fileSizeBytes, 2048500);

      final json = img.toJson();
      final restored = CapturedImage.fromJson(json);

      expect(restored.id, img.id);
      expect(restored.filePath, img.filePath);
      expect(restored.width, 1920);
      expect(restored.height, 1080);
      expect(restored.orientationDegrees, 90);
      expect(restored.sourceType, ImageSourceType.camera);
    });

    test('Gallery source type is properly tagged and formatted', () {
      final galleryImg = CapturedImage(
        filePath: '/data/app/gallery_import.jpg',
        sourceType: ImageSourceType.gallery,
      );

      expect(galleryImg.sourceType, ImageSourceType.gallery);
      expect(galleryImg.sourceType.displayName, 'Photo Library');
    });
  });

  group('ImageStorageService Persistence, Organization & Lifecycle', () {
    test('persistAndNormalizeImage copies source file into structured scan directory', () async {
      // 1. Create a dummy source file
      final tempSource = File('${testDocsDir.path}/raw_camera_capture.jpg');
      await tempSource.writeAsBytes(const [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
        0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9
      ]);

      // 2. Persist using service
      final capturedImage = await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: tempSource.path,
        sessionId: 'scan_session_42',
        roomId: 'living_room',
        roomName: 'Living Room',
        orderIndex: 0,
        sourceType: ImageSourceType.camera,
      );

      expect(capturedImage.filePath.contains('scans'), isTrue);
      expect(capturedImage.filePath.contains('scan_session_42'), isTrue);
      expect(capturedImage.filePath.contains('living_room'), isTrue);
      expect(await File(capturedImage.filePath).exists(), isTrue);
      expect(capturedImage.fileSizeBytes, greaterThan(0));
    });

    test('deleteImage removes the file from disk', () async {
      final tempSource = File('${testDocsDir.path}/temp_delete_test.jpg');
      await tempSource.writeAsBytes([1, 2, 3, 4, 5]);

      final capturedImage = await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: tempSource.path,
        sessionId: 'session_del',
        roomId: 'bedroom',
        roomName: 'Bedroom',
        orderIndex: 0,
      );

      expect(await File(capturedImage.filePath).exists(), isTrue);

      final deleted = await ImageStorageService.instance.deleteImage(capturedImage);
      expect(deleted, isTrue);
      expect(await File(capturedImage.filePath).exists(), isFalse);
    });

    test('deleteSessionImages clears entire scan session tree', () async {
      final tempSource = File('${testDocsDir.path}/temp_multi_test.jpg');
      await tempSource.writeAsBytes([1, 2, 3]);

      final img1 = await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: tempSource.path,
        sessionId: 'session_purge',
        roomId: 'kitchen',
        roomName: 'Kitchen',
        orderIndex: 0,
      );

      expect(await File(img1.filePath).exists(), isTrue);

      await ImageStorageService.instance.deleteSessionImages('session_purge');

      expect(await File(img1.filePath).exists(), isFalse);
    });
  });

  group('Multi-Photo ScannerSession & RoomData Management', () {
    test('Captures 0/3 -> 1/3 -> 2/3 -> 3/3 without overwriting previous photos', () async {
      final session = ScannerSession(sessionId: 'session_test_room');
      final room = session.currentRoom;

      expect(room.photoCount, 0);
      expect(room.hasSufficientPhotos, isFalse);

      final img1 = CapturedImage(id: '1', filePath: '/path/1.jpg', orderIndex: 0);
      final img2 = CapturedImage(id: '2', filePath: '/path/2.jpg', orderIndex: 1);
      final img3 = CapturedImage(id: '3', filePath: '/path/3.jpg', orderIndex: 2);

      room.addCapturedImage(img1);
      expect(room.photoCount, 1);
      expect(room.hasSufficientPhotos, isFalse);

      room.addCapturedImage(img2);
      expect(room.photoCount, 2);
      expect(room.hasSufficientPhotos, isTrue);

      room.addCapturedImage(img3);
      expect(room.photoCount, 3);
      expect(room.images.length, 3);
      expect(room.images.map((i) => i.id).toList(), ['1', '2', '3']);
    });

    test('removeImageById removes capture from room and updates count', () async {
      final tempSource = File('${testDocsDir.path}/remove_test.jpg');
      await tempSource.writeAsBytes([10, 20, 30]);

      final img = await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: tempSource.path,
        sessionId: 'session_remove',
        roomId: 'living_room',
        roomName: 'Living Room',
        orderIndex: 0,
      );

      final room = RoomData(name: 'Living Room');
      room.addCapturedImage(img);
      expect(room.photoCount, 1);

      final removed = await room.removeImageById(img.id);
      expect(removed?.id, img.id);
      expect(room.photoCount, 0);
      expect(await File(img.filePath).exists(), isFalse);
    });

    test('resetSession clears photos in all rooms and removes session storage', () async {
      final tempSource = File('${testDocsDir.path}/reset_test.jpg');
      await tempSource.writeAsBytes([1, 2, 3]);

      final session = ScannerSession(sessionId: 'session_reset_all');
      final img = await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: tempSource.path,
        sessionId: session.sessionId,
        roomId: session.currentRoom.id,
        roomName: session.currentRoom.name,
        orderIndex: 0,
      );
      session.currentRoom.addCapturedImage(img);

      expect(session.currentRoom.photoCount, 1);

      await session.resetSession();

      expect(session.currentRoom.photoCount, 0);
      expect(session.currentRoomIndex, 0);
      expect(session.isConfirmed, isFalse);
      expect(await File(img.filePath).exists(), isFalse);
    });
  });
}
