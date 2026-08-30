import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// Compact item row inside the Detected Items card.
/// Thumbnail | Name + room + subtitle | Toggle check
class ReviewItemRow extends StatelessWidget {
  final String name;
  final String? roomName;
  final String cleaningAction;
  final String frequency;
  final bool isConfirmed;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final Color categoryAccent;

  const ReviewItemRow({
    super.key,
    required this.name,
    this.roomName,
    required this.cleaningAction,
    required this.frequency,
    required this.isConfirmed,
    required this.onToggle,
    this.onEdit,
    required this.categoryAccent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Thumbnail placeholder — dark glass square with category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surfaceDark.withValues(alpha: 0.85),
                border: Border.all(
                  color: categoryAccent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: categoryAccent.withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                _iconForName(name),
                size: 20,
                color: categoryAccent,
              ),
            ),
            const SizedBox(width: 12),

            // Name + room + cleaning info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (roomName != null && roomName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
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
                            roomName!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryPurple,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cleaningAction • $frequency',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Edit button
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.white.withValues(alpha: 0.5)),
                onPressed: onEdit,
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (onEdit != null) const SizedBox(width: 6),

            // Confirmation toggle
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isConfirmed
                      ? Colors.green.withValues(alpha: 0.25)
                      : AppColors.surfaceDark.withValues(alpha: 0.8),
                  border: Border.all(
                    color: isConfirmed
                        ? Colors.green.withValues(alpha: 0.80)
                        : Colors.white.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                  boxShadow: isConfirmed
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
                child: isConfirmed
                    ? Icon(Icons.check, size: 15, color: Colors.green[400])
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('floor') || lower.contains('rug')) return Icons.grid_on;
    if (lower.contains('window')) return Icons.window;
    if (lower.contains('sofa') || lower.contains('couch')) return Icons.chair;
    if (lower.contains('table')) return Icons.table_restaurant;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv;
    if (lower.contains('plant')) return Icons.local_florist;
    if (lower.contains('stand')) return Icons.tv;
    if (lower.contains('counter')) return Icons.countertops;
    return Icons.category;
  }
}
