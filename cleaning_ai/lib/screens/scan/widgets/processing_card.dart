import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';

class ProcessingCard extends StatelessWidget {
  final Animation<double> progressAnimation;

  const ProcessingCard({
    super.key,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassCard(
        baseColor: AppColors.glassWhite,
        glowColor: Colors.transparent,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom subtle circular indicator
            AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: progressAnimation.value * 2 * 3.14159 * 2, // Rotate twice over animation
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryPurple),
                      strokeWidth: 2.5,
                      backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.2),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Processing...', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Almost there. Preparing review.', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
