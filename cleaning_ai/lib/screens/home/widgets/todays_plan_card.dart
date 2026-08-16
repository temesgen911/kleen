import 'package:flutter/material.dart';
import '../../../models/app_state.dart';
import '../../../models/cleaning_plan.dart';
import '../../../models/scanner_session.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/progress_ring.dart';
import '../../session/cleaning_session_screen.dart';

class TodaysPlanCard extends StatefulWidget {
  const TodaysPlanCard({super.key});

  @override
  State<TodaysPlanCard> createState() => _TodaysPlanCardState();
}

class _TodaysPlanCardState extends State<TodaysPlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _shineAnim;
  bool _showEntrance = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnim = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _shineAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    );

    // Check if this is first arrival after accept
    if (AppState.instance.isFirstArrivalAfterAccept) {
      _showEntrance = true;
      AppState.instance.consumeFirstArrival();
      _entranceCtrl.forward();
    } else {
      _entranceCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final plan = AppState.instance.activePlan;
        final today = AppState.instance.dateProvider.currentWeekDay();
        final todayTasks = plan != null
            ? plan.getTasksForDay(today)
            : _getInitialDemoTasks();

        final totalMins = todayTasks.fold<int>(
            0, (sum, task) => sum + task.estimatedMinutes);
        final completedCount = todayTasks
            .where((t) => AppState.instance.isTaskCompleted(t.id))
            .length;
        final totalCount = todayTasks.length;
        final progress =
            totalCount > 0 ? (completedCount / totalCount) : 1.0;
        final percent = (progress * 100).round();
        final isRestDay = todayTasks.isEmpty;

        final isAllCompleted = totalCount > 0 && completedCount == totalCount;

        Widget cardContent = GlassCard(
          baseColor: AppColors.primaryTeal,
          glowColor: AppColors.primaryTeal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Row(
                children: [
                  const Icon(Icons.document_scanner,
                      color: AppColors.primaryTeal, size: 16),
                  const SizedBox(width: 8),
                  Text('TODAY\'S PLAN • ${today.displayName.toUpperCase()}',
                      style: AppTypography.label
                          .copyWith(color: AppColors.primaryTeal)),
                ],
              ),
              const SizedBox(height: 16),

              // Title & Progress Ring
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRestDay
                              ? 'You\'re all caught up ✨'
                              : (isAllCompleted
                                  ? 'Today\'s reset complete ✨'
                                  : 'Today\'s $totalMins-minute reset ✨'),
                          style: AppTypography.heading2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isRestDay
                              ? 'No cleaning scheduled today. Enjoy the clean.'
                              : (isAllCompleted
                                  ? 'All $totalCount tasks done. Awesome consistency!'
                                  : 'Small steps, big impact.'),
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ProgressRing(
                    progress: progress,
                    size: 76,
                    strokeWidth: 5.0,
                    centerChild: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isRestDay ? '100%' : '$percent%',
                          style: AppTypography.heading1.copyWith(
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                color: AppColors.primaryTeal
                                    .withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isRestDay ? 'Rest' : (isAllCompleted ? 'Done' : 'Complete'),
                          style: AppTypography.bodySmall
                              .copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic Tasks or Rest Day message
              if (!isRestDay) ...[
                for (final task in todayTasks) ...[
                  _buildTaskItem(task),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                // Responsive Footer row with estimated time and start reset button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.primaryTeal, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: isAllCompleted ? 'Total: ' : 'Est. time: ',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$totalMins min',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      text: isAllCompleted ? 'Review reset' : 'Start reset',
                      icon: isAllCompleted ? Icons.check_circle_outline : Icons.arrow_forward,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                CleaningSessionScreen(tasks: todayTasks),
                            transitionsBuilder:
                                (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 350),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ] else ...[
                // Rest Day Empty State Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryTeal
                              .withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rest day',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your scheduled tasks are well-spaced.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

        if (_showEntrance) {
          return AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Stack(
                    children: [
                      cardContent,
                      // Subtle shine sweep overlay
                      if (_shineAnim.value > 0.0 && _shineAnim.value < 1.0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Transform.translate(
                                offset: Offset(
                                    (MediaQuery.of(context).size.width * 1.5) *
                                            _shineAnim.value -
                                        MediaQuery.of(context).size.width *
                                            0.5,
                                    0),
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.primaryTeal
                                            .withValues(alpha: 0.15),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return cardContent;
      },
    );
  }

  Widget _buildTaskItem(PlanTask task) {
    final isDone = AppState.instance.isTaskCompleted(task.id);
    final icon = _getIconForTask(task);

    return GestureDetector(
      onTap: () {
        AppState.instance.toggleTaskCompletion(task.id);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Interactive Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primaryTeal
                    : Colors.transparent,
                border: Border.all(
                  color: isDone
                      ? AppColors.primaryTeal
                      : AppColors.primaryTeal.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal
                        .withValues(alpha: isDone ? 0.4 : 0.15),
                    blurRadius: isDone ? 8 : 4,
                  ),
                ],
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),

            // Icon Badge
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.0,
                ),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 18),
            ),
            const SizedBox(width: 12),

            // Task Name and Estimated Duration + Room
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${task.sourceItem.cleaningAction} ${task.sourceItem.name}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryPurple
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.roomName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondaryPurple,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${task.estimatedMinutes} min',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryTeal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PlanTask> _getInitialDemoTasks() {
    final today = AppState.instance.dateProvider.currentWeekDay();
    final fallbackSession = ScannerSession();
    final fallbackPlan = CleaningPlan.generateMockPlan(fallbackSession);
    return fallbackPlan.getTasksForDay(today);
  }
}
