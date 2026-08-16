import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';

class AiScanCompleteCard extends StatelessWidget {
  final int itemCount;
  final String roomName;
  final int roomCount;

  const AiScanCompleteCard({
    super.key,
    required this.itemCount,
    required this.roomName,
    this.roomCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final String locationText = roomCount > 1
        ? 'across $roomCount rooms'
        : 'in your $roomName';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassCard(
        baseColor: AppColors.glassWhite,
        glowColor: AppColors.secondaryPurple,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Sparkle icon in glowing circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryPurple.withValues(alpha: 0.35),
                    AppColors.accentIndigo.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryPurple.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI scan complete!',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Found $itemCount items $locationText.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Review and confirm what\'s here.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // High accuracy badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 12, color: Colors.green[400]),
                  const SizedBox(width: 4),
                  Text(
                    'High\naccuracy',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.green[400],
                      fontSize: 9.5,
                      height: 1.2,
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
