import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/cleaning_plan.dart';
import 'plan_task_card.dart';

class DaySection extends StatelessWidget {
  final WeekDay day;
  final List<PlanTask> tasks;
  final Function(String taskId, WeekDay newDay, {int? insertIndex})
      onTaskDropped;
  final Function(String taskId) onTaskDeleted;
  final Function(PlanTask task)? onTaskEdited;

  const DaySection({
    super.key,
    required this.day,
    required this.tasks,
    required this.onTaskDropped,
    required this.onTaskDeleted,
    this.onTaskEdited,
  });

  @override
  Widget build(BuildContext context) {
    final int totalMins =
        tasks.fold(0, (sum, t) => sum + t.estimatedMinutes);
    final bool isEmpty = tasks.isEmpty;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onTaskDropped(details.data, day);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.secondaryPurple.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered
                  ? AppColors.secondaryPurple.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      day.displayName,
                      style: AppTypography.heading2.copyWith(
                        color: isHovered
                            ? AppColors.secondaryPurple
                            : AppColors.textPrimary,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isEmpty)
                    Text(
                      '$totalMins min • ${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Tasks or Empty State
              if (isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Rest day',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(tasks.length, (index) {
                  final task = tasks[index];
                  return LongPressDraggable<String>(
                    data: task.id,
                    feedback: SizedBox(
                      width: MediaQuery.of(context).size.width - 48,
                      child: PlanTaskCard(
                        task: task,
                        onDelete: () {},
                        isDragging: true,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: PlanTaskCard(
                        task: task,
                        onDelete: () {},
                      ),
                    ),
                    // Drop target for reordering within the same day
                    child: DragTarget<String>(
                      onAcceptWithDetails: (details) {
                        onTaskDropped(details.data, day, insertIndex: index);
                      },
                      builder: (context, itemCandidateData, itemRejectedData) {
                        return PlanTaskCard(
                          task: task,
                          onDelete: () => onTaskDeleted(task.id),
                          onEdit: onTaskEdited != null ? () => onTaskEdited!(task) : null,
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
