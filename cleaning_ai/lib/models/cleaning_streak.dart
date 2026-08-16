import 'dart:math' as math;
import 'cleaning_plan.dart';
import '../services/date_provider.dart';

/// Represents the user's consecutive daily cleaning streak state.
class CleaningStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int totalCompletedDays;
  final List<DateTime> completedDates;

  const CleaningStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.totalCompletedDays = 0,
    this.completedDates = const [],
  });

  /// Factory for an initial zero-state streak.
  factory CleaningStreak.initial() => const CleaningStreak();

  /// True if this represents the user's very first streak ever (Day 1).
  bool get isFirstStreak => currentStreak == 1 && totalCompletedDays <= 1;

  /// Evaluates today's completed daily plan and returns an updated [CleaningStreak].
  ///
  /// Rules:
  /// • Local calendar days are strictly used (no 24-hr elapsed timers).
  /// • Completing today's plan more than once never increments streak twice.
  /// • First ever completed daily plan yields currentStreak = 1.
  /// • Consecutive scheduled day completion increments currentStreak (+1).
  /// • Rest days (days with no scheduled cleaning) do NOT break the streak.
  /// • Missed days with scheduled cleaning reset currentStreak to 1.
  CleaningStreak registerCompletedDay({
    required DateTime completionDate,
    CleaningPlan? plan,
    DateProvider? dateProvider,
  }) {
    final provider = dateProvider ?? SystemDateProvider();
    final today = DateTime(completionDate.year, completionDate.month, completionDate.day);

    // 1. Prevent duplicate same-day increments
    if (lastCompletedDate != null && provider.isSameDay(lastCompletedDate!, today)) {
      return this;
    }

    final newTotalDays = totalCompletedDays + 1;
    final newHistory = List<DateTime>.from(completedDates)..add(today);

    // 2. First ever streak completion
    if (lastCompletedDate == null) {
      return CleaningStreak(
        currentStreak: 1,
        longestStreak: math.max(longestStreak, 1),
        lastCompletedDate: today,
        totalCompletedDays: newTotalDays,
        completedDates: newHistory,
      );
    }

    final lastDate = DateTime(
      lastCompletedDate!.year,
      lastCompletedDate!.month,
      lastCompletedDate!.day,
    );

    // 3. Immediate consecutive calendar day
    final daysDifference = today.difference(lastDate).inDays;
    if (daysDifference == 1) {
      final newStreak = currentStreak + 1;
      return CleaningStreak(
        currentStreak: newStreak,
        longestStreak: math.max(longestStreak, newStreak),
        lastCompletedDate: today,
        totalCompletedDays: newTotalDays,
        completedDates: newHistory,
      );
    }

    // 4. Intervening days check (Rest days vs missed cleaning days)
    if (daysDifference > 1) {
      bool missedScheduledDay = false;

      if (plan != null) {
        // Iterate through all intervening calendar days
        for (int i = 1; i < daysDifference; i++) {
          final checkDate = lastDate.add(Duration(days: i));
          final weekdayInt = checkDate.weekday; // 1 (Mon) .. 7 (Sun)
          final weekdayEnum = WeekDay.values[(weekdayInt - 1) % 7];
          final tasksOnDay = plan.getTasksForDay(weekdayEnum);

          // If an intervening day had scheduled tasks, it was missed
          if (tasksOnDay.isNotEmpty) {
            missedScheduledDay = true;
            break;
          }
        }
      } else {
        // Without plan info, assume missing more than 1 calendar day is a break
        missedScheduledDay = true;
      }

      final newStreak = missedScheduledDay ? 1 : (currentStreak + 1);
      return CleaningStreak(
        currentStreak: newStreak,
        longestStreak: math.max(longestStreak, newStreak),
        lastCompletedDate: today,
        totalCompletedDays: newTotalDays,
        completedDates: newHistory,
      );
    }

    // Fallback in case of past date calculation
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'totalCompletedDays': totalCompletedDays,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory CleaningStreak.fromJson(Map<String, dynamic> json) {
    return CleaningStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.tryParse(json['lastCompletedDate'] as String)
          : null,
      totalCompletedDays: json['totalCompletedDays'] as int? ?? 0,
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((d) => DateTime.tryParse(d as String))
              .whereType<DateTime>()
              .toList() ??
          const [],
    );
  }

  CleaningStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    int? totalCompletedDays,
    List<DateTime>? completedDates,
  }) {
    return CleaningStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      totalCompletedDays: totalCompletedDays ?? this.totalCompletedDays,
      completedDates: completedDates ?? this.completedDates,
    );
  }
}
