import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/cleaning_plan.dart';
import '../../../../models/scanner_session.dart';

class PlanTaskCard extends StatelessWidget {
  final PlanTask task;
  final VoidCallback onDelete;
  final bool isDragging;

  const PlanTaskCard({
    super.key,
    required this.task,
    required this.onDelete,
    this.isDragging = false,
  });

  IconData get _icon {
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

  Color get _accent {
    switch (task.sourceItem.category) {
      case ItemCategory.surfaces:
        return AppColors.categoryBlue;
      case ItemCategory.furniture:
        return AppColors.categoryPurple;
      case ItemCategory.electronics:
        return AppColors.categoryOrange;
      case ItemCategory.other:
        return AppColors.categoryGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // Darker glass fill
        color: isDragging
            ? _accent.withValues(alpha: 0.08)
            : AppColors.surfaceDark.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDragging
              ? _accent.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
        boxShadow: [
          if (isDragging)
            BoxShadow(
              color: _accent.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          // Always apply subtle depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Drag Handle
              Icon(
                Icons.drag_indicator,
                color: Colors.white.withValues(alpha: 0.3),
                size: 18,
              ),
              const SizedBox(width: 8),

              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.30),
                    width: 1.0,
                  ),
                ),
                child: Icon(_icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${task.sourceItem.cleaningAction} ${task.sourceItem.name}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Room Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryPurple
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.secondaryPurple
                                  .withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            task.roomName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryPurple,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.schedule,
                            size: 11, color: AppColors.primaryTeal),
                        const SizedBox(width: 3),
                        Text(
                          '${task.estimatedMinutes} min',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${task.sourceItem.frequency}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.7),
                              fontSize: 10,
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

              // Delete Action
              IconButton(
                icon: Icon(Icons.close,
                    color: Colors.white.withValues(alpha: 0.35), size: 18),
                onPressed: onDelete,
                splashRadius: 18,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
