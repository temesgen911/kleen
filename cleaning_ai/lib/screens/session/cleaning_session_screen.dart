import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../models/cleaning_plan.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import 'daily_completion_screen.dart';
import 'widgets/task_completion_burst.dart';

/// Minimalist, high-focus cleaning session screen for executing today's cleaning tasks.
class CleaningSessionScreen extends StatefulWidget {
  final List<PlanTask> tasks;

  const CleaningSessionScreen({super.key, required this.tasks});

  @override
  State<CleaningSessionScreen> createState() => _CleaningSessionScreenState();
}

class _CleaningSessionScreenState extends State<CleaningSessionScreen> {
  late final List<PlanTask> _sessionTasks;
  int _currentIndex = 0;
  final GlobalKey<TaskCompletionBurstState> _burstKey = GlobalKey();

  final Stopwatch _sessionStopwatch = Stopwatch();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Copy the tasks to preserve session order
    _sessionTasks = List.from(widget.tasks);
    
    // Find the first uncompleted task
    final firstPendingIndex = _sessionTasks.indexWhere(
      (t) => !AppState.instance.isTaskCompleted(t.id),
    );
    if (firstPendingIndex != -1) {
      _currentIndex = firstPendingIndex;
    }

    _sessionStopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sessionStopwatch.stop();
    _ticker?.cancel();
    super.dispose();
  }

  PlanTask get _currentTask => _sessionTasks[_currentIndex];

  int get _plannedTotalMinutes =>
      _sessionTasks.fold<int>(0, (sum, t) => sum + t.estimatedMinutes);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  IconData _getIconForTask(PlanTask task) {
    final name = task.sourceItem.name.toLowerCase();
    if (name.contains('floor') || name.contains('rug')) return Icons.grid_on;
    if (name.contains('window')) return Icons.window;
    if (name.contains('sofa') || name.contains('couch')) return Icons.chair;
    if (name.contains('table')) return Icons.table_restaurant;
    if (name.contains('tv') || name.contains('television')) return Icons.tv;
    if (name.contains('plant')) return Icons.local_florist;
    if (name.contains('stand')) return Icons.tv;
    if (name.contains('counter')) return Icons.countertops;
    return Icons.cleaning_services;
  }

  String _getInstructionForTask(PlanTask task) {
    final action = task.sourceItem.cleaningAction;
    final name = task.sourceItem.name;
    if (action.toLowerCase().contains('wipe')) {
      return 'Wipe $name surface and remove visible dust.';
    }
    if (action.toLowerCase().contains('vacuum')) {
      return 'Vacuum $name thoroughly for a fresh clean feel.';
    }
    if (action.toLowerCase().contains('dust')) {
      return 'Gently dust $name with a microfiber cloth.';
    }
    return 'Complete cleaning reset for $name.';
  }

  void _onDoneTapped() {
    _burstKey.currentState?.triggerBurst();
  }

  void _handleTaskCompleted() async {
    final task = _currentTask;
    AppState.instance.completeTask(task.id);

    _advanceToNext();
  }

  void _onSkipTapped() {
    final task = _currentTask;
    AppState.instance.skipTask(task.id);

    _advanceToNext();
  }

  void _advanceToNext() async {
    if (_currentIndex + 1 < _sessionTasks.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _sessionStopwatch.stop();
      final actualDuration = _sessionStopwatch.elapsed;

      // All tasks for today processed
      final completedCount = _sessionTasks
          .where((t) => AppState.instance.isTaskCompleted(t.id))
          .length;
      final totalMins = _plannedTotalMinutes;

      final streak = await AppState.instance.completeDailyPlan();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DailyCompletionScreen(
            completedTasksCount: completedCount,
            totalMinutes: totalMins > 0 ? totalMins : 1,
            streak: streak,
            actualDuration: actualDuration,
            plannedMinutes: totalMins > 0 ? totalMins : 1,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _sessionTasks.length;
    final displayIndex = _currentIndex + 1;
    final progress = displayIndex / totalCount;
    final task = _currentTask;

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // Ambient backglow
          Container(color: AppColors.backgroundStart),

          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryTeal.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Top Header Bar ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Exit (X)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: 'Exit session',
                      ),

                      // Session Title & Step Counter
                      Column(
                        children: [
                          Text(
                            'TODAY\'S RESET',
                            style: AppTypography.label.copyWith(
                              color: AppColors.primaryTeal,
                              letterSpacing: 1.5,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$displayIndex of $totalCount',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Right side: Live Stopwatch Timer Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.primaryTeal
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                color: AppColors.primaryTeal, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              _formatDuration(_sessionStopwatch.elapsed),
                              style: AppTypography.label.copyWith(
                                color: AppColors.primaryTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Segmented Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            AppColors.glassWhite.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryTeal),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // ── Main Focused Task Card with Completion Burst ───────────
                  TaskCompletionBurst(
                    key: _burstKey,
                    onComplete: _handleTaskCompleted,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      borderRadius: 24,
                      baseColor: AppColors.glassWhite,
                      glowColor: AppColors.primaryTeal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Room Badge Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: AppColors.primaryTeal
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room_outlined,
                                    color: AppColors.primaryTeal, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  task.roomName.toUpperCase(),
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.primaryTeal,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Large Object Icon with illuminated background
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppColors.primaryTeal.withValues(alpha: 0.12),
                              border: Border.all(
                                color: AppColors.primaryTeal
                                    .withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryTeal
                                      .withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIconForTask(task),
                              color: AppColors.primaryTeal,
                              size: 48,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Task Name
                          Text(
                            task.sourceItem.name,
                            style: AppTypography.heading1.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 6),

                          // Estimated Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '~${task.estimatedMinutes} min',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Secondary Concise Cleaning Instruction
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.glassWhite.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              _getInstructionForTask(task),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // ── Prominent Action: ✓ DONE ───────────────────────────────
                  PrimaryButton(
                    text: '✓ DONE',
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onTap: _onDoneTapped,
                  ),

                  const SizedBox(height: 12),

                  // Secondary Action: Skip
                  TextButton(
                    onPressed: _onSkipTapped,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Skip task',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
