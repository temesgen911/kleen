import 'package:flutter_test/flutter_test.dart';
import 'package:cleaning_ai/models/app_state.dart';
import 'package:cleaning_ai/models/captured_image.dart';
import 'package:cleaning_ai/models/cleaning_plan.dart';
import 'package:cleaning_ai/models/cleaning_requirement.dart';
import 'package:cleaning_ai/models/confirmed_item.dart';
import 'package:cleaning_ai/models/detected_item.dart';
import 'package:cleaning_ai/models/scanner_session.dart';
import 'package:cleaning_ai/services/date_provider.dart';
import 'package:cleaning_ai/services/scheduling_service.dart';
import 'package:cleaning_ai/services/vision_analysis_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain Architecture & Entity Boundaries', () {
    late MockDateProvider mockDateProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDateProvider = MockDateProvider(DateTime(2026, 8, 17, 9, 0)); // Monday
      AppState.instance.resetAll();
      AppState.instance.setDateProvider(mockDateProvider);
    });

    test('CapturedImage preserves full metadata and serializes cleanly', () {
      final img = CapturedImage(
        filePath: '/data/camera/living_room_1.jpg',
        roomName: 'Living Room',
        orderIndex: 0,
        width: 1920,
        height: 1080,
      );

      expect(img.filePath, '/data/camera/living_room_1.jpg');
      expect(img.roomName, 'Living Room');
      expect(img.width, 1920);
      expect(img.height, 1080);

      final json = img.toJson();
      final restored = CapturedImage.fromJson(json);

      expect(restored.filePath, img.filePath);
      expect(restored.roomName, img.roomName);
      expect(restored.width, 1920);
    });

    test('DetectedItem transitions to ConfirmedItem with AI provenance preserved', () {
      final detected = DetectedItem(
        id: 'det_table_1',
        name: 'Coffee Table',
        category: ItemCategory.furniture,
        roomName: 'Living Room',
        confidence: 0.96,
        material: 'Wood',
        normalizedBoundingBox: [0.2, 0.4, 0.5, 0.3],
      );

      final confirmed = ConfirmedItem.fromDetectedItem(detected);

      expect(confirmed.name, 'Coffee Table');
      expect(confirmed.roomName, 'Living Room');
      expect(confirmed.provenance, ItemProvenance.aiDetected);
      expect(confirmed.detectedItemId, 'det_table_1');
      expect(confirmed.isConfirmed, isTrue);
    });

    test('Manually created item records userAdded provenance', () {
      final userItem = ConfirmedItem.userCreated(
        name: 'Air Purifier',
        roomName: 'Bedroom',
        category: ItemCategory.electronics,
      );

      expect(userItem.name, 'Air Purifier');
      expect(userItem.provenance, ItemProvenance.userAdded);
      expect(userItem.confidence, 1.0);
    });

    test('CleaningRequirement cleanly decouples cleaning rules from physical items', () {
      final requirement = CleaningRequirement(
        itemId: 'item_coffee_table',
        action: 'Wipe',
        frequencyDays: 3,
        estimatedMinutes: 2,
        priority: TaskPriority.high,
      );

      expect(requirement.action, 'Wipe');
      expect(requirement.frequencyDays, 3);
      expect(requirement.frequencyLabel, 'Every 3 days');
      expect(requirement.priority, TaskPriority.high);

      final json = requirement.toJson();
      final restored = CleaningRequirement.fromJson(json);
      expect(restored.action, 'Wipe');
      expect(restored.frequencyDays, 3);
    });

    test('VisionAnalysisService produces structured detections for multiple rooms', () async {
      const visionService = MockVisionAnalysisService();
      final rooms = [
        RoomData(name: 'Living Room'),
        RoomData(name: 'Bedroom'),
      ];

      final detections = await visionService.analyzeMultiRoomScan(rooms);

      expect(detections.isNotEmpty, isTrue);
      expect(detections.any((d) => d.roomName == 'Living Room'), isTrue);
      expect(detections.any((d) => d.roomName == 'Bedroom'), isTrue);
    });

    test('SchedulingService generates balanced CleaningPlan from ConfirmedItems', () async {
      const schedulingService = MockSchedulingService();
      final items = [
        ConfirmedItem(
          name: 'Coffee Table',
          roomName: 'Living Room',
          category: ItemCategory.furniture,
        ),
        ConfirmedItem(
          name: 'Area Rug',
          roomName: 'Bedroom',
          category: ItemCategory.surfaces,
        ),
      ];

      final plan = await schedulingService.generatePlan(confirmedItems: items);

      expect(plan.tasks.length, 2);
      expect(plan.totalMinutes, greaterThan(0));
      expect(plan.activeDaysCount, greaterThan(0));
    });

    test('AppState maintains single source of truth for task status & records completion history', () {
      final reviewItem = ReviewItem(
        id: 'rev_couch',
        name: 'Sofa',
        roomName: 'Living Room',
        category: ItemCategory.furniture,
        cleaningAction: 'Vacuum',
        frequency: 'Every 7 days',
      );
      final task = PlanTask(
        id: 'task_couch_1',
        sourceItem: reviewItem,
        estimatedMinutes: 4,
        scheduledDay: WeekDay.monday,
      );
      final plan = CleaningPlan(tasks: [task]);

      AppState.instance.setActivePlan(plan);

      expect(AppState.instance.isTaskCompleted('task_couch_1'), isFalse);
      expect(AppState.instance.completionHistory.isEmpty, isTrue);

      // Complete task
      AppState.instance.completeTask('task_couch_1', duration: const Duration(minutes: 3));

      expect(AppState.instance.isTaskCompleted('task_couch_1'), isTrue);
      expect(plan.isTaskCompleted('task_couch_1'), isTrue);
      expect(AppState.instance.completionHistory.length, 1);
      expect(AppState.instance.completionHistory.first.taskId, 'task_couch_1');
      expect(AppState.instance.completionHistory.first.actualDuration?.inMinutes, 3);
      expect(AppState.instance.completionHistory.first.status, TaskStatus.completed);
    });

    test('ScannerSession reset clears photo state and resets room pointers', () async {
      final session = ScannerSession();
      session.currentRoom.addPhoto(CapturedImage(filePath: '/tmp/test.jpg').toXFile());
      expect(session.currentRoom.photoCount, 1);

      await session.resetSession();

      expect(session.currentRoom.photoCount, 0);
      expect(session.currentRoomIndex, 0);
      expect(session.isConfirmed, isFalse);
    });
  });
}
