import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/captured_image.dart';

/// Service responsible for persisting, organizing, measuring, and deleting scan images.
class ImageStorageService {
  static final ImageStorageService instance = ImageStorageService._internal();
  factory ImageStorageService() => instance;
  ImageStorageService._internal();

  /// Gets the base directory for all scans: `<app_docs>/scans/`
  Future<Directory> getScansBaseDirectory() async {
    Directory docsDir;
    try {
      docsDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      docsDir = Directory.systemTemp;
    }
    final scansDir = Directory(p.join(docsDir.path, 'scans'));
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    return scansDir;
  }

  /// Gets the target directory for a specific scan session and room:
  /// `<app_docs>/scans/<sessionId>/<roomId>/`
  Future<Directory> getRoomDirectory({
    required String sessionId,
    required String roomId,
  }) async {
    final scansBase = await getScansBaseDirectory();
    final sanitizedSession = _sanitizeName(sessionId);
    final sanitizedRoom = _sanitizeName(roomId);
    final roomDir = Directory(p.join(scansBase.path, sanitizedSession, sanitizedRoom));
    if (!await roomDir.exists()) {
      await roomDir.create(recursive: true);
    }
    return roomDir;
  }

  /// Copies a captured/imported photo from temporary cache to persistent app storage,
  /// extracts image dimensions and metadata, and returns a reliable [CapturedImage].
  Future<CapturedImage> persistAndNormalizeImage({
    required String sourceFilePath,
    required String sessionId,
    required String roomId,
    required String roomName,
    required int orderIndex,
    ImageSourceType sourceType = ImageSourceType.camera,
  }) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source image file not found', sourceFilePath);
    }

    final roomDir = await getRoomDirectory(sessionId: sessionId, roomId: roomId);
    final imageId = 'img_${DateTime.now().millisecondsSinceEpoch}_$orderIndex';
    final targetPath = p.join(roomDir.path, '$imageId.jpg');

    // 1. Copy to persistent destination
    final persistentFile = await sourceFile.copy(targetPath);
    final fileBytes = await persistentFile.readAsBytes();
    final fileSizeBytes = fileBytes.length;

    // 2. Decode image dimensions asynchronously using Flutter's native decoder
    double? width;
    double? height;
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image decodedImage = frameInfo.image;
      width = decodedImage.width.toDouble();
      height = decodedImage.height.toDouble();
      decodedImage.dispose();
    } catch (e) {
      debugPrint('[ImageStorageService] Could not decode image dimensions: $e');
    }

    // 3. Return fully populated domain entity
    return CapturedImage(
      id: imageId,
      filePath: persistentFile.path,
      roomName: roomName,
      orderIndex: orderIndex,
      capturedAt: DateTime.now(),
      width: width,
      height: height,
      orientationDegrees: (width != null && height != null && width > height) ? 90 : 0,
      fileSizeBytes: fileSizeBytes,
      sourceType: sourceType,
    );
  }

  /// Safely deletes the local file associated with a [CapturedImage].
  Future<bool> deleteImage(CapturedImage image) async {
    try {
      final file = File(image.filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('[ImageStorageService] Error deleting image file ${image.filePath}: $e');
    }
    return false;
  }

  /// Deletes all image files for a specific room.
  Future<void> deleteRoomImages({
    required String sessionId,
    required String roomId,
  }) async {
    try {
      final roomDir = await getRoomDirectory(sessionId: sessionId, roomId: roomId);
      if (await roomDir.exists()) {
        await roomDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[ImageStorageService] Error deleting room directory: $e');
    }
  }

  /// Deletes an entire scan session directory and all its images.
  Future<void> deleteSessionImages(String sessionId) async {
    try {
      final scansBase = await getScansBaseDirectory();
      final sessionDir = Directory(p.join(scansBase.path, _sanitizeName(sessionId)));
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[ImageStorageService] Error deleting session directory: $e');
    }
  }

  static String _sanitizeName(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }
}
