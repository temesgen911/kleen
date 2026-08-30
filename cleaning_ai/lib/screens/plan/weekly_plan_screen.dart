import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/app_state.dart';
import '../../../models/cleaning_plan.dart';
import '../../../models/scanner_session.dart';
import '../scan/scanner_screen.dart';
import 'widgets/day_section.dart';
import 'widgets/plan_success_dialog.dart';
import 'widgets/task_edit_sheet.dart';
import '../../services/local_db_service.dart';

class WeeklyPlanScreen extends StatefulWidget {
  final ScannerSession? session;
  final bool isManagementMode;

  const WeeklyPlanScreen({
    super.key,
    this.session,
    this.isManagementMode = false,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late CleaningPlan _plan;
  bool _isAccepting = false;
  int _selectedWeek = 1;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _plan = CleaningPlan.generateMockPlan(widget.session!);
    } else if (AppState.instance.activePlan != null) {
      _plan = AppState.instance.activePlan!;
    } else {
      final fallbackSession = ScannerSession();
      _plan = CleaningPlan.generateMockPlan(fallbackSession);
    }
    _plan.addListener(_onPlanChanged);
  }

  @override
  void dispose() {
    _plan.removeListener(_onPlanChanged);
    super.dispose();
  }

  void _onPlanChanged() {
    setState(() {}); // Rebuild on plan changes
  }

  void _handleTaskDropped(String taskId, WeekDay newDay, {int? insertIndex}) {
    _plan.moveTaskToDay(taskId, newDay, insertIndex: insertIndex);
  }

  void _handleTaskDeleted(String taskId) {
    final taskIndex = _plan.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final deletedTask = _plan.tasks[taskIndex];
    _plan.removeTask(taskId);
    LocalDbService.instance.deleteTask(taskId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1F2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          'Task removed',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.secondaryPurple,
          onPressed: () {
            _plan.addTask(deletedTask);
            LocalDbService.instance.saveSingleTask(deletedTask);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleTaskEdited(PlanTask task) {
    TaskEditSheet.show(
      context,
      existingTask: task,
      onSaveTask: (updatedTask) {
        final idx = _plan.tasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          _plan.tasks[idx] = updatedTask;
          _plan.notifyListeners();
          LocalDbService.instance.saveSingleTask(updatedTask);
        }
      },
      onDelete: () => _handleTaskDeleted(task.id),
    );
  }

  void _handleAddTask() {
    TaskEditSheet.show(
      context,
      onSaveTask: (newTask) {
        _plan.addTask(newTask);
        LocalDbService.instance.saveSingleTask(newTask);
      },
    );
  }

  void _onRescheduleMissedDays() {
    _plan.autoRescheduleMissedDays(weekNumber: _selectedWeek);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Text(
          '⚡ Missed tasks auto-redistributed across remaining days!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _onAcceptPlan() {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    // Save finalized plan and session to AppState
    AppState.instance.setActivePlan(_plan, session: widget.session);

    if (widget.isManagementMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Text(
            'Plan updated successfully!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      // Show the dedicated success transition
      PlanSuccessDialog.show(context);
    }
  }

  void _onStartOver() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Start over?', style: AppTypography.heading2),
        content: Text(
          'This will discard your current scan and generated plan.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
                (route) => route.isFirst,
              );
            },
            child: const Text('Start Over', style: TextStyle(color: AppColors.categoryOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missedDays = _plan.getMissedDays(weekNumber: _selectedWeek);

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddTask,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.backgroundStart,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (missedDays.isNotEmpty) _buildMissedDaysBanner(missedDays),
            Expanded(
              child: Stack(
                children: [
                  // Plan List
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                        .copyWith(bottom: 130),
                    children: WeekDay.values.map((day) {
                      return DaySection(
                        day: day,
                        tasks: _plan.getTasksForDay(day, weekNumber: _selectedWeek),
                        onTaskDropped: _handleTaskDropped,
                        onTaskDeleted: _handleTaskDeleted,
                        onTaskEdited: _handleTaskEdited,
                      );
                    }).toList(),
                  ),

                  // Bottom Actions (gradient overlay)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.backgroundStart.withValues(alpha: 0.0),
                            AppColors.backgroundStart.withValues(alpha: 0.85),
                            AppColors.backgroundStart,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAcceptButton(),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _onStartOver,
                            child: Text(
                              widget.isManagementMode ? 'Rescan Rooms' : 'Start Over',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedDaysBanner(List<WeekDay> missedDays) {
    final dayStr = missedDays.map((d) => d.displayName).join(', ');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.categoryOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.categoryOrange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.categoryOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Missed $dayStr tasks.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: _onRescheduleMissedDays,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '⚡ Catch Up',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.backgroundStart,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.isManagementMode ? 'Weekly Cleaning Plan' : 'Your Cleaning Plan',
                  style: AppTypography.heading1.copyWith(fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Multi-Week Schedule & Recurrence Load Balancing',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Multi-Week Selector (Week 1 - Week 4)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(4, (index) {
                      final weekNum = index + 1;
                      final isSelected = _selectedWeek == weekNum;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            'Week $weekNum',
                            style: AppTypography.caption.copyWith(
                              color: isSelected ? AppColors.backgroundStart : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: AppColors.surfaceDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryTeal : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedWeek = weekNum);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Weekly Overview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildOverviewStat('${_plan.totalMinutes} min', 'total'),
                      Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.1)),
                      _buildOverviewStat('${_plan.activeDaysCount} days', 'active'),
                      Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.1)),
                      _buildOverviewStat(
                        '~${_plan.activeDaysCount > 0 ? (_plan.totalMinutes / _plan.activeDaysCount).round() : 0} min',
                        'per day',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.drag_indicator, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Drag tasks between days to adjust your week.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondaryPurple,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptButton() {
    return GestureDetector(
      onTap: _isAccepting ? null : _onAcceptPlan,
      child: Opacity(
        opacity: _isAccepting ? 0.7 : 1.0,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [AppColors.secondaryPurple, AppColors.accentIndigo],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.40),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryPurple.withValues(alpha: 0.40),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Specular top highlight line
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Container(
                  height: 1.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  widget.isManagementMode ? 'Save Changes' : 'Accept Plan',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
