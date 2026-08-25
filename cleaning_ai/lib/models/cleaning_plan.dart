import 'package:flutter/foundation.dart';
import 'scanner_session.dart';
import 'task_frequency.dart';

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
  skipped,
  missed,
  rescheduled;

  bool get isCompleted => this == TaskStatus.completed;
  bool get isSkipped => this == TaskStatus.skipped;
  bool get isPending => this == TaskStatus.pending;
  bool get isMissed => this == TaskStatus.missed;
  bool get isRescheduled => this == TaskStatus.rescheduled;
}

class PlanTask {
  final String id;
  final ReviewItem sourceItem;
  final int estimatedMinutes;
  WeekDay scheduledDay;
  TaskStatus status;
  final TaskFrequency frequency;
  final String? aiTip;
  final int weekNumber;

  PlanTask({
    required this.id,
    required this.sourceItem,
    required this.estimatedMinutes,
    required this.scheduledDay,
    this.status = TaskStatus.pending,
    TaskFrequency? frequency,
    this.aiTip,
    this.weekNumber = 1,
  }) : frequency = frequency ?? TaskFrequency.parse(sourceItem.frequency);

  String get roomName => sourceItem.roomName;

  bool get isCompleted => status == TaskStatus.completed;
  bool get isSkipped => status == TaskStatus.skipped;
  bool get isPending => status == TaskStatus.pending;
  bool get isRescheduled => status == TaskStatus.rescheduled;

  PlanTask copyWith({
    String? id,
    ReviewItem? sourceItem,
    int? estimatedMinutes,
    WeekDay? scheduledDay,
    TaskStatus? status,
    TaskFrequency? frequency,
    String? aiTip,
    int? weekNumber,
  }) {
    return PlanTask(
      id: id ?? this.id,
      sourceItem: sourceItem ?? this.sourceItem,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      aiTip: aiTip ?? this.aiTip,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }
}

class CleaningPlan extends ChangeNotifier {
  final List<PlanTask> tasks;
  double _userPacingRatio = 1.0;

  CleaningPlan({required this.tasks});

  double get userPacingRatio => _userPacingRatio;

  List<PlanTask> getTasksForDay(WeekDay day, {int weekNumber = 1}) {
    return tasks.where((task) => task.scheduledDay == day && task.weekNumber == weekNumber).toList();
  }

  List<PlanTask> getCompletedTasksForDay(WeekDay day, {int weekNumber = 1}) {
    return getTasksForDay(day, weekNumber: weekNumber).where((t) => t.isCompleted).toList();
  }

  List<PlanTask> getPendingTasksForDay(WeekDay day, {int weekNumber = 1}) {
    return getTasksForDay(day, weekNumber: weekNumber).where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.rescheduled).toList();
  }

  /// True if the day has scheduled tasks and every task has been completed (not skipped or pending).
  bool isDayFullyCompleted(WeekDay day, {int weekNumber = 1}) {
    final dayTasks = getTasksForDay(day, weekNumber: weekNumber);
    if (dayTasks.isEmpty) return false;
    return dayTasks.every((t) => t.isCompleted);
  }

  /// Finds missed days prior to today where tasks were left pending.
  List<WeekDay> getMissedDays({int weekNumber = 1}) {
    final today = WeekDay.today;
    final missed = <WeekDay>[];
    for (final day in WeekDay.values) {
      if (day.index >= today.index) break;
      final dayTasks = getTasksForDay(day, weekNumber: weekNumber);
      if (dayTasks.isNotEmpty && dayTasks.any((t) => t.status == TaskStatus.pending)) {
        missed.add(day);
      }
    }
    return missed;
  }

  /// Automatically reschedules uncompleted tasks from missed days to remaining available days.
  void autoRescheduleMissedDays({int weekNumber = 1}) {
    final missedDays = getMissedDays(weekNumber: weekNumber);
    if (missedDays.isEmpty) return;

    final today = WeekDay.today;
    final futureDays = WeekDay.values.where((d) => d.index >= today.index).toList();
    if (futureDays.isEmpty) return;

    // Distribute pending tasks from missed days across future days
    final pendingMissedTasks = tasks.where((t) => t.weekNumber == weekNumber && missedDays.contains(t.scheduledDay) && t.status == TaskStatus.pending).toList();

    for (int i = 0; i < pendingMissedTasks.length; i++) {
      final task = pendingMissedTasks[i];
      final targetDay = futureDays[i % futureDays.length];
      final taskIndex = tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        tasks[taskIndex] = task.copyWith(
          scheduledDay: targetDay,
          status: TaskStatus.rescheduled,
          aiTip: 'Smart Rescheduled: Moved from ${task.scheduledDay.displayName} to balance load.',
        );
      }
    }
    notifyListeners();
  }

  void setTaskStatus(String taskId, TaskStatus newStatus) {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index].status = newStatus;
      notifyListeners();
    }
  }

  bool isTaskCompleted(String taskId) {
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    return task?.isCompleted ?? false;
  }

  bool isTaskSkipped(String taskId) {
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    return task?.isSkipped ?? false;
  }

  /// Adjusts all task estimated times based on learned user cleaning speed ratio.
  void applyPacingAdjustment(double ratio) {
    if (ratio <= 0) return;
    _userPacingRatio = ratio.clamp(0.5, 2.0);
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final newMins = (task.estimatedMinutes * _userPacingRatio).round().clamp(1, 45);
      tasks[i] = task.copyWith(estimatedMinutes: newMins);
    }
    notifyListeners();
  }

  int getMinutesForDay(WeekDay day, {int weekNumber = 1}) {
    return getTasksForDay(day, weekNumber: weekNumber).fold(0, (sum, task) => sum + task.estimatedMinutes);
  }

  int get totalMinutes => tasks.fold(0, (sum, task) => sum + task.estimatedMinutes);

  int get activeDaysCount => WeekDay.values.where((day) => getTasksForDay(day).isNotEmpty).length;

  void moveTaskToDay(String taskId, WeekDay newDay, {int? insertIndex}) {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = tasks.removeAt(taskIndex);
    final updatedTask = task.copyWith(scheduledDay: newDay, status: TaskStatus.pending);

    if (insertIndex != null) {
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

  /// Intelligent Multi-Week Plan Generation Logic
  static CleaningPlan generateMockPlan(ScannerSession session, {int totalWeeks = 4}) {
    final confirmedItems = session.reviewItems.where((i) => i.isConfirmed).toList();
    final List<PlanTask> generatedTasks = [];

    int estimateMinutes(String action) {
      if (action.contains('Vacuum / Mop')) return 6;
      if (action.contains('Vacuum')) return 4;
      if (action.contains('Wipe')) return 3;
      if (action.contains('Dust')) return 2;
      return 3;
    }

    // Group items by room
    final roomItemsMap = <String, List<ReviewItem>>{};
    for (final item in confirmedItems) {
      roomItemsMap.putIfAbsent(item.roomName, () => []).add(item);
    }

    final rooms = roomItemsMap.keys.toList();
    final days = WeekDay.values;

    for (int week = 1; week <= totalWeeks; week++) {
      for (int rIdx = 0; rIdx < rooms.length; rIdx++) {
        final roomName = rooms[rIdx];
        final roomItems = roomItemsMap[roomName]!;
        final primaryDay = days[(rIdx * 2) % 7];
        final secondaryDay = days[((rIdx * 2) + 3) % 7];

        for (final item in roomItems) {
          final freq = TaskFrequency.parse(item.frequency);
          bool includeInWeek = false;

          switch (freq) {
            case TaskFrequency.daily:
              includeInWeek = true;
              break;
            case TaskFrequency.twiceWeekly:
              includeInWeek = true;
              break;
            case TaskFrequency.weekly:
              includeInWeek = true;
              break;
            case TaskFrequency.biWeekly:
            case TaskFrequency.twiceMonthly:
              includeInWeek = (week % 2 == hashString(item.id) % 2);
              break;
            case TaskFrequency.monthly:
              includeInWeek = (week == (hashString(item.id) % totalWeeks) + 1);
              break;
            case TaskFrequency.quarterly:
              includeInWeek = (week == 1);
              break;
          }

          if (includeInWeek) {
            final scheduledDay = (freq == TaskFrequency.twiceWeekly)
                ? (item.name.length % 2 == 0 ? primaryDay : secondaryDay)
                : primaryDay;

            generatedTasks.add(PlanTask(
              id: 'task_${item.id}_w$week',
              sourceItem: item,
              estimatedMinutes: estimateMinutes(item.cleaningAction),
              scheduledDay: scheduledDay,
              frequency: freq,
              weekNumber: week,
              aiTip: _generateAiTip(item, freq),
            ));
          }
        }
      }
    }

    return CleaningPlan(tasks: generatedTasks);
  }

  static int hashString(String str) {
    return str.codeUnits.fold(0, (prev, curr) => prev + curr);
  }

  static String _generateAiTip(ReviewItem item, TaskFrequency freq) {
    if (freq == TaskFrequency.biWeekly || freq == TaskFrequency.twiceMonthly) {
      return 'Bi-weekly routine: Focus on deep dusting surface corners.';
    }
    if (freq == TaskFrequency.monthly || freq == TaskFrequency.quarterly) {
      return 'Deep Maintenance: Check for grime build-up and use microfiber cloth.';
    }
    if (item.cleaningAction.contains('Vacuum')) {
      return 'Efficiency tip: Clear floor objects before starting vacuuming.';
    }
    return 'Quick wipe: Use S-pattern motion for streak-free cleaning.';
  }
}
