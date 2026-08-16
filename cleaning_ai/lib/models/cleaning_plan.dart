import 'package:flutter/foundation.dart';
import 'scanner_session.dart';

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  static WeekDay get today {
    final now = DateTime.now();
    return WeekDay.values[(now.weekday - 1) % 7];
  }

  String get displayName {
    switch (this) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
      case WeekDay.saturday:
        return 'Saturday';
      case WeekDay.sunday:
        return 'Sunday';
    }
  }
}

enum TaskStatus {
  pending,
  completed,
  skipped;

  bool get isCompleted => this == TaskStatus.completed;
  bool get isSkipped => this == TaskStatus.skipped;
  bool get isPending => this == TaskStatus.pending;
}

class PlanTask {
  final String id;
  final ReviewItem sourceItem;
  final int estimatedMinutes;
  WeekDay scheduledDay;
  TaskStatus status;

  PlanTask({
    required this.id,
    required this.sourceItem,
    required this.estimatedMinutes,
    required this.scheduledDay,
    this.status = TaskStatus.pending,
  });

  String get roomName => sourceItem.roomName;

  bool get isCompleted => status == TaskStatus.completed;
  bool get isSkipped => status == TaskStatus.skipped;

  PlanTask copyWith({
    String? id,
    ReviewItem? sourceItem,
    int? estimatedMinutes,
    WeekDay? scheduledDay,
    TaskStatus? status,
  }) {
    return PlanTask(
      id: id ?? this.id,
      sourceItem: sourceItem ?? this.sourceItem,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      status: status ?? this.status,
    );
  }
}

class CleaningPlan extends ChangeNotifier {
  final List<PlanTask> tasks;

  CleaningPlan({required this.tasks});

  List<PlanTask> getTasksForDay(WeekDay day) {
    return tasks.where((task) => task.scheduledDay == day).toList();
  }

  List<PlanTask> getCompletedTasksForDay(WeekDay day) {
    return getTasksForDay(day).where((t) => t.isCompleted).toList();
  }

  List<PlanTask> getPendingTasksForDay(WeekDay day) {
    return getTasksForDay(day).where((t) => t.status == TaskStatus.pending).toList();
  }

  /// True if the day has scheduled tasks and every task has been completed (not skipped or pending).
  bool isDayFullyCompleted(WeekDay day) {
    final dayTasks = getTasksForDay(day);
    if (dayTasks.isEmpty) return false;
    return dayTasks.every((t) => t.isCompleted);
  }

  void setTaskStatus(String taskId, TaskStatus newStatus) {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index].status = newStatus;
      notifyListeners();
    }
  }

  /// Adjusts all task estimated times by [ratio] based on actual cleaning pace.
  void applyPacingAdjustment(double ratio) {
    if (ratio <= 0) return;
    final clampedRatio = ratio.clamp(0.5, 2.0);
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final newMins = (task.estimatedMinutes * clampedRatio).round().clamp(1, 30);
      tasks[i] = task.copyWith(estimatedMinutes: newMins);
    }
    notifyListeners();
  }

  int getMinutesForDay(WeekDay day) {
    return getTasksForDay(day).fold(0, (sum, task) => sum + task.estimatedMinutes);
  }

  int get totalMinutes => tasks.fold(0, (sum, task) => sum + task.estimatedMinutes);

  int get activeDaysCount => WeekDay.values.where((day) => getTasksForDay(day).isNotEmpty).length;

  void moveTaskToDay(String taskId, WeekDay newDay, {int? insertIndex}) {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = tasks.removeAt(taskIndex);
    final updatedTask = task.copyWith(scheduledDay: newDay);

    if (insertIndex != null) {
        // Find absolute index in the main list corresponding to the insertIndex in the newDay list
        final dayTasks = getTasksForDay(newDay);
        if (insertIndex >= dayTasks.length) {
            tasks.add(updatedTask);
        } else {
           final targetTask = dayTasks[insertIndex];
           final targetGlobalIndex = tasks.indexWhere((t) => t.id == targetTask.id);
           tasks.insert(targetGlobalIndex, updatedTask);
        }
    } else {
        tasks.add(updatedTask);
    }
    notifyListeners();
  }

  void removeTask(String taskId) {
    tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void addTask(PlanTask task) {
    tasks.add(task);
    notifyListeners();
  }

  /// Mock Generation Logic
  static CleaningPlan generateMockPlan(ScannerSession session) {
    final confirmedItems = session.reviewItems.where((i) => i.isConfirmed).toList();
    final List<PlanTask> generatedTasks = [];

    // Assign a mock minute value based on cleaning action
    int estimateMinutes(String action) {
      if (action.contains('Vacuum / Mop')) return 6;
      if (action.contains('Vacuum')) return 4;
      if (action.contains('Wipe')) return 3;
      if (action.contains('Dust')) return 2;
      return 2;
    }

    // Attempt a rough distribution across the week for the mock
    final dayCycle = [
      WeekDay.monday,
      WeekDay.thursday,
      WeekDay.tuesday,
      WeekDay.friday,
      WeekDay.wednesday,
      WeekDay.saturday,
    ];

    for (int i = 0; i < confirmedItems.length; i++) {
        final item = confirmedItems[i];
        final day = dayCycle[i % dayCycle.length];
        generatedTasks.add(PlanTask(
            id: 'task_${item.id}',
            sourceItem: item,
            estimatedMinutes: estimateMinutes(item.cleaningAction),
            scheduledDay: day,
        ));
    }

    // Force a specific mock for testing if it matches our items, otherwise use generic distribution
    if (confirmedItems.any((i) => i.name == 'Coffee Table') && confirmedItems.any((i) => i.name == 'Area Rug')) {
       return _buildSpecificMockPlan(confirmedItems);
    }

    return CleaningPlan(tasks: generatedTasks);
  }

  static CleaningPlan _buildSpecificMockPlan(List<ReviewItem> items) {
      final List<PlanTask> tasks = [];
      int getMinutes(String action) {
          if (action.contains('Vacuum / Mop')) return 6;
          if (action.contains('Vacuum')) return 4;
          if (action.contains('Wipe')) return 3;
          if (action.contains('Dust')) return 2;
          return 2;
      }

      void assign(String name, WeekDay day, [int? customMins]) {
          final item = items.firstWhere((i) => i.name == name, orElse: () => ReviewItem(name: name, category: ItemCategory.other, cleaningAction: 'Clean', frequency: '7 days'));
          tasks.add(PlanTask(
              id: 'mock_$name',
              sourceItem: item,
              estimatedMinutes: customMins ?? getMinutes(item.cleaningAction),
              scheduledDay: day
          ));
      }

      try {
          assign('Coffee Table', WeekDay.monday, 2);
          assign('Area Rug', WeekDay.monday, 4);
          assign('Television', WeekDay.tuesday, 2);
          assign('House Plant', WeekDay.wednesday, 2);
          assign('TV Stand', WeekDay.thursday, 2);
          assign('Windowsill', WeekDay.thursday, 3);
          assign('Sofa', WeekDay.friday, 4);
          assign('Hardwood Floor', WeekDay.saturday, 6);
      } catch (e) {
          // If items don't match, fallback is handled earlier. This try-catch is just in case.
      }

      return CleaningPlan(tasks: tasks);
  }
}
