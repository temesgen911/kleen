import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleaning_ai/main.dart';
import 'package:cleaning_ai/models/app_state.dart';
import 'package:cleaning_ai/models/cleaning_plan.dart';
import 'package:cleaning_ai/models/cleaning_streak.dart';
import 'package:cleaning_ai/models/scanner_session.dart';
import 'package:cleaning_ai/services/date_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleaning_ai/screens/home/home_screen.dart';
import 'package:cleaning_ai/screens/session/cleaning_session_screen.dart';
import 'package:cleaning_ai/screens/session/daily_completion_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Cleaning Session & Streak Flow End-to-End Test', () {
    late MockDateProvider mockDateProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDateProvider = MockDateProvider(DateTime(2026, 8, 17, 9, 0)); // Monday
      AppState.instance.resetAll();
      AppState.instance.setDateProvider(mockDateProvider);
    });

    testWidgets('Full flow: Home -> Start Reset -> Complete Tasks -> Reset Complete -> Home Day 1 Streak -> Day 2 Streak = 2',
        (WidgetTester tester) async {
      // 1. Setup an active cleaning plan with tasks for Monday and Tuesday
      final mondayTask1 = PlanTask(
        id: 't_mon_1',
        sourceItem: ReviewItem(
          name: 'Coffee Table',
          roomName: 'Living Room',
          category: ItemCategory.furniture,
          cleaningAction: 'Wipe table',
          frequency: '7 days',
        ),
        estimatedMinutes: 2,
        scheduledDay: WeekDay.monday,
      );
      final mondayTask2 = PlanTask(
        id: 't_mon_2',
        sourceItem: ReviewItem(
          name: 'Area Rug',
          roomName: 'Living Room',
          category: ItemCategory.furniture,
          cleaningAction: 'Vacuum rug',
          frequency: '7 days',
        ),
        estimatedMinutes: 4,
        scheduledDay: WeekDay.monday,
      );
      final tuesdayTask1 = PlanTask(
        id: 't_tue_1',
        sourceItem: ReviewItem(
          name: 'Television',
          roomName: 'Living Room',
          category: ItemCategory.electronics,
          cleaningAction: 'Dust television',
          frequency: '7 days',
        ),
        estimatedMinutes: 2,
        scheduledDay: WeekDay.tuesday,
      );

      final plan = CleaningPlan(tasks: [mondayTask1, mondayTask2, tuesdayTask1]);
      AppState.instance.setActivePlan(plan);

      // 2. Build the app directly on HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Home shows "Start reset" with 2 tasks for Monday
      expect(find.text('Start reset'), findsOneWidget);
      expect(find.textContaining('Coffee Table'), findsOneWidget);
      expect(find.textContaining('Area Rug'), findsOneWidget);
      expect(AppState.instance.streak.currentStreak, 0);

      // 3. Tap "Start reset"
      await tester.tap(find.text('Start reset'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Should now be on CleaningSessionScreen (Task 1 of 2)
      expect(find.byType(CleaningSessionScreen), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('✓ DONE'), findsOneWidget);

      // 4. Complete Task 1
      await tester.tap(find.text('✓ DONE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600)); // burst completion
      await tester.pump(const Duration(milliseconds: 200));

      // Task 1 should now be completed, showing Task 2 of 2
      expect(AppState.instance.isTaskCompleted('t_mon_1'), isTrue);
      // Completing 1 of 2 tasks must NOT increment streak yet!
      expect(AppState.instance.streak.currentStreak, 0);
      expect(find.text('2 of 2'), findsOneWidget);

      // 5. Complete Task 2 (Last task of today)
      await tester.tap(find.text('✓ DONE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600)); // burst completion
      await tester.pump(); // allow async completeDailyPlan future to resolve
      await tester.pump(const Duration(milliseconds: 600)); // transition to completion screen

      // Should now be on DailyCompletionScreen
      expect(find.byType(DailyCompletionScreen), findsOneWidget);
      expect(find.text('RESET COMPLETE'), findsOneWidget);
      expect(find.text('Your first streak!'), findsOneWidget);
      expect(AppState.instance.streak.currentStreak, 1);
      expect(AppState.instance.streak.isFirstStreak, isTrue);

      // 6. Tap "Back to Home"
      await tester.ensureVisible(find.text('Back to Home'));
      await tester.tap(find.text('Back to Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Should be on HomeScreen with 100% complete state and 1-day streak
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('1-day streak'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Today\'s reset complete ✨'), findsOneWidget);
      expect(find.text('Review reset'), findsOneWidget);

      // ── Simulate Day 2 (Tuesday) ───────────────────────────────────────────
      mockDateProvider.setDate(DateTime(2026, 8, 18, 9, 30)); // Tuesday
      // Trigger AppState listeners for new date/plan refresh
      AppState.instance.notifyListeners();
      await tester.pump(const Duration(milliseconds: 200));

      // Home shows Tuesday tasks
      expect(find.textContaining('Television'), findsOneWidget);
      expect(find.text('Start reset'), findsOneWidget);

      // Start Tuesday reset
      await tester.tap(find.text('Start reset'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Complete Tuesday task
      expect(find.byType(CleaningSessionScreen), findsOneWidget);
      await tester.tap(find.text('✓ DONE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Reached DailyCompletionScreen for Day 2
      expect(find.byType(DailyCompletionScreen), findsOneWidget);
      expect(AppState.instance.streak.currentStreak, 2);
      expect(AppState.instance.streak.longestStreak, 2);
      expect(AppState.instance.streak.totalCompletedDays, 2);
      expect(find.text('2 days in a row!'), findsOneWidget);
    });

    testWidgets('Pacing adjustment updates task minutes proportionally',
        (WidgetTester tester) async {
      final task1 = PlanTask(
        id: 't1',
        sourceItem: ReviewItem(
          name: 'Counter',
          roomName: 'Kitchen',
          category: ItemCategory.surfaces,
          cleaningAction: 'Wipe counter',
          frequency: '7 days',
        ),
        estimatedMinutes: 6,
        scheduledDay: WeekDay.monday,
      );
      final plan = CleaningPlan(tasks: [task1]);
      AppState.instance.setActivePlan(plan);

      // Build DailyCompletionScreen with 3-minute actual duration (faster by 50%)
      await tester.pumpWidget(
        MaterialApp(
          home: DailyCompletionScreen(
            completedTasksCount: 1,
            totalMinutes: 6,
            streak: const CleaningStreak(currentStreak: 1, totalCompletedDays: 1),
            actualDuration: const Duration(minutes: 3),
            plannedMinutes: 6,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PACING INSIGHT'), findsOneWidget);
      expect(find.textContaining('faster than plan'), findsOneWidget);
      expect(find.text('Adjust plan times'), findsOneWidget);

      // Tap Adjust plan times
      await tester.tap(find.text('Adjust plan times'));
      await tester.pump(const Duration(milliseconds: 200));

      // Task minutes should be scaled (6 * 0.5 = 3 mins)
      expect(plan.tasks.first.estimatedMinutes, 3);
      expect(find.textContaining('Weekly plan times adjusted'), findsOneWidget);
    });
  });
}
