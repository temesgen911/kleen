import '../models/cleaning_plan.dart';
import '../models/cleaning_requirement.dart';
import '../models/confirmed_item.dart';
import '../models/scanner_session.dart' show ReviewItem;
import 'local_db_service.dart';
import 'notification_service.dart';

/// Contract for the scheduling engine that generates, balances, and adapts weekly cleaning plans.
abstract class SchedulingService {
  Future<CleaningPlan> generatePlan({
    required List<ConfirmedItem> confirmedItems,
    List<CleaningRequirement>? requirements,
    Map<String, dynamic>? userPreferences,
  });
}

/// Mock scheduling service that balances tasks across the week using clean domain models.
class MockSchedulingService implements SchedulingService {
  const MockSchedulingService();

  @override
  Future<CleaningPlan> generatePlan({
    required List<ConfirmedItem> confirmedItems,
    List<CleaningRequirement>? requirements,
    Map<String, dynamic>? userPreferences,
  }) async {
    final activeItems = confirmedItems.where((i) => i.isConfirmed).toList();
    final List<PlanTask> tasks = [];

    final dayCycle = [
      WeekDay.monday,
      WeekDay.thursday,
      WeekDay.tuesday,
      WeekDay.friday,
      WeekDay.wednesday,
      WeekDay.saturday,
    ];

    int estimateMinutes(String name) {
      final n = name.toLowerCase();
      if (n.contains('floor') || n.contains('rug')) return 4;
      if (n.contains('sofa') || n.contains('counter')) return 3;
      if (n.contains('table') || n.contains('window')) return 2;
      return 2;
    }

    for (int i = 0; i < activeItems.length; i++) {
      final item = activeItems[i];
      final day = dayCycle[i % dayCycle.length];
      tasks.add(
        PlanTask(
          id: 'task_${item.id}',
          sourceItem: ReviewItem(
            id: item.id,
            name: item.name,
            roomName: item.roomName,
            category: item.category,
            cleaningAction: _defaultActionFor(item.name),
            frequency: 'Every 7 days',
            isConfirmed: true,
          ),
          estimatedMinutes: estimateMinutes(item.name),
          scheduledDay: day,
        ),
      );
    }

    final plan = CleaningPlan(tasks: tasks);

    // Persist tasks locally and schedule push notifications
    try {
      await LocalDbService.instance.saveTasks(tasks);
      for (final t in tasks) {
        NotificationService.instance.scheduleTaskNotification(t);
      }
    } catch (_) {}

    return plan;
  }

  static String _defaultActionFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('floor')) return 'Vacuum / Mop';
    if (n.contains('rug') || n.contains('sofa')) return 'Vacuum';
    if (n.contains('table') || n.contains('counter') || n.contains('window')) {
      return 'Wipe';
    }
    return 'Dust';
  }
}
