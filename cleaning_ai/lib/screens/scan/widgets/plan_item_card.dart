import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/scanner_session.dart';

/// A single luminous glass card representing a detected item during plan generation.
class PlanItemCard extends StatelessWidget {
  final ReviewItem item;
  static const double cardW = 146.0;
  static const double cardH = 46.0;

  const PlanItemCard({super.key, required this.item});

  Color get _accent {
    switch (item.category) {
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

  IconData get _icon {
    final name = item.name.toLowerCase();
    if (name.contains('floor') || name.contains('rug')) return Icons.grid_on;
    if (name.contains('window')) return Icons.window;
    if (name.contains('sofa') || name.contains('couch')) return Icons.chair;
    if (name.contains('table')) return Icons.table_restaurant;
    if (name.contains('tv') || name.contains('television')) return Icons.tv;
    if (name.contains('plant')) return Icons.local_florist;
    if (name.contains('stand')) return Icons.tv;
    if (name.contains('counter')) return Icons.countertops;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: cardW,
        height: cardH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Dark glass body
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accent.withValues(alpha: 0.12),
              AppColors.surfaceDark.withValues(alpha: 0.80),
            ],
          ),
          // Luminous edge
          border: Border.all(
            color: _accent.withValues(alpha: 0.55),
            width: 1.0,
          ),
          boxShadow: [
            // Outer glow
            BoxShadow(
              color: _accent.withValues(alpha: 0.22),
              blurRadius: 12,
              spreadRadius: 0,
            ),
            // Inner edge highlight (simulated)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top-left specular highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.0,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.30),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.1, 0.5, 0.9],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(_icon, size: 14, color: _accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.roomName,
                          style: AppTypography.bodySmall.copyWith(
                            color: _accent.withValues(alpha: 0.85),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}
