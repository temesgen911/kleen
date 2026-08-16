import 'package:flutter_test/flutter_test.dart';
import 'package:cleaning_ai/models/cleaning_plan.dart';
import 'package:cleaning_ai/models/cleaning_streak.dart';
import 'package:cleaning_ai/models/scanner_session.dart';
import 'package:cleaning_ai/services/date_provider.dart';

void main() {
  group('CleaningStreak Calculation & Edge Cases', () {
    late MockDateProvider dateProvider;

    setUp(() {
      dateProvider = MockDateProvider(DateTime(2026, 8, 17, 10, 0)); // Monday
    });

    test('Initial streak starts at 0', () {
      final streak = CleaningStreak.initial();
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastCompletedDate, isNull);
      expect(streak.totalCompletedDays, 0);
      expect(streak.isFirstStreak, isFalse);
    });

    test('First ever completed daily plan results in streak = 1', () {
      final initial = CleaningStreak.initial();
      final updated = initial.registerCompletedDay(
        completionDate: dateProvider.now(),
        dateProvider: dateProvider,
      );

      expect(updated.currentStreak, 1);
      expect(updated.longestStreak, 1);
      expect(updated.totalCompletedDays, 1);
      expect(updated.isFirstStreak, isTrue);
      expect(updated.lastCompletedDate, DateTime(2026, 8, 17));
    });

    test('Reopening or completing same day twice does NOT increment streak', () {
      final initial = CleaningStreak.initial();
      final day1 = initial.registerCompletedDay(
        completionDate: dateProvider.now(),
        dateProvider: dateProvider,
      );
      expect(day1.currentStreak, 1);

      // Same day at 23:55
      dateProvider.setDate(DateTime(2026, 8, 17, 23, 55));
      final duplicate = day1.registerCompletedDay(
        completionDate: dateProvider.now(),
        dateProvider: dateProvider,
      );

      expect(duplicate.currentStreak, 1);
      expect(duplicate.totalCompletedDays, 1);
    });

    test('Consecutive daily plans (Monday -> Tuesday) increments streak to 2', () {
      final initial = CleaningStreak.initial();
      final day1 = initial.registerCompletedDay(
        completionDate: dateProvider.now(), // Monday
        dateProvider: dateProvider,
      );
      expect(day1.currentStreak, 1);

      // Advance to Tuesday 08:30 (crossing midnight)
      dateProvider.setDate(DateTime(2026, 8, 18, 8, 30));
      final day2 = day1.registerCompletedDay(
        completionDate: dateProvider.now(),
        dateProvider: dateProvider,
      );

      expect(day2.currentStreak, 2);
      expect(day2.longestStreak, 2);
      expect(day2.totalCompletedDays, 2);
      expect(day2.isFirstStreak, isFalse);
    });

    test('Rest days (no scheduled tasks) do NOT break streak', () {
      // Create a plan with tasks on Monday and Wednesday, Tuesday is a REST DAY
      final taskMon = PlanTask(
        id: 't_mon',
        sourceItem: ReviewItem(name: 'Table', category: ItemCategory.other, cleaningAction: 'Wipe', frequency: '7d'),
        estimatedMinutes: 2,
        scheduledDay: WeekDay.monday,
      );
      final taskWed = PlanTask(
        id: 't_wed',
        sourceItem: ReviewItem(name: 'Rug', category: ItemCategory.other, cleaningAction: 'Vacuum', frequency: '7d'),
        estimatedMinutes: 4,
        scheduledDay: WeekDay.wednesday,
      );
      final plan = CleaningPlan(tasks: [taskMon, taskWed]);

      // Complete Monday
      dateProvider.setDate(DateTime(2026, 8, 17)); // Mon
      final streakMon = CleaningStreak.initial().registerCompletedDay(
        completionDate: dateProvider.now(),
        plan: plan,
        dateProvider: dateProvider,
      );
      expect(streakMon.currentStreak, 1);

      // Tuesday (2026-08-18) is a rest day (0 tasks scheduled)
      // User returns on Wednesday (2026-08-19)
      dateProvider.setDate(DateTime(2026, 8, 19)); // Wed
      final streakWed = streakMon.registerCompletedDay(
        completionDate: dateProvider.now(),
        plan: plan,
        dateProvider: dateProvider,
      );

      // Streak should successfully continue (+1) because Tuesday was a rest day!
      expect(streakWed.currentStreak, 2);
      expect(streakWed.totalCompletedDays, 2);
    });

    test('Missed scheduled day resets streak to 1', () {
      // Create a plan with tasks on Monday and Tuesday
      final taskMon = PlanTask(
        id: 't_mon',
        sourceItem: ReviewItem(name: 'Table', category: ItemCategory.other, cleaningAction: 'Wipe', frequency: '7d'),
        estimatedMinutes: 2,
        scheduledDay: WeekDay.monday,
      );
      final taskTue = PlanTask(
        id: 't_tue',
        sourceItem: ReviewItem(name: 'Sofa', category: ItemCategory.other, cleaningAction: 'Vacuum', frequency: '7d'),
        estimatedMinutes: 3,
        scheduledDay: WeekDay.tuesday,
      );
      final plan = CleaningPlan(tasks: [taskMon, taskTue]);

      // Complete Monday
      dateProvider.setDate(DateTime(2026, 8, 17)); // Mon
      final streakMon = CleaningStreak.initial().registerCompletedDay(
        completionDate: dateProvider.now(),
        plan: plan,
        dateProvider: dateProvider,
      );
      expect(streakMon.currentStreak, 1);

      // User skips Tuesday (which had scheduled tasks) and comes on Wednesday
      dateProvider.setDate(DateTime(2026, 8, 19)); // Wed
      final streakWed = streakMon.registerCompletedDay(
        completionDate: dateProvider.now(),
        plan: plan,
        dateProvider: dateProvider,
      );

      // Streak resets to 1 because Tuesday had scheduled cleaning and was missed
      expect(streakWed.currentStreak, 1);
      expect(streakWed.longestStreak, 1);
      expect(streakWed.totalCompletedDays, 2);
    });

    test('JSON serialization roundtrip preserves streak fields', () {
      final original = CleaningStreak(
        currentStreak: 5,
        longestStreak: 12,
        lastCompletedDate: DateTime(2026, 8, 16),
        totalCompletedDays: 14,
        completedDates: [
          DateTime(2026, 8, 14),
          DateTime(2026, 8, 15),
          DateTime(2026, 8, 16),
        ],
      );

      final json = original.toJson();
      final restored = CleaningStreak.fromJson(json);

      expect(restored.currentStreak, 5);
      expect(restored.longestStreak, 12);
      expect(restored.totalCompletedDays, 14);
      expect(restored.lastCompletedDate, DateTime(2026, 8, 16));
      expect(restored.completedDates.length, 3);
    });
  });
}
