import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../widgets/progress_ring.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final double captureProgress;

  const CameraControls({
    super.key,
    required this.onCapture,
    required this.captureProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), // Reduced vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tips Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassCard(
                width: 56,
                height: 56,
                padding: EdgeInsets.zero,
                borderRadius: 16,
                baseColor: AppColors.glassWhite,
                child: const Center(
                  child: Icon(Icons.lightbulb_outline, color: AppColors.textPrimary, size: 28),
                ),
              ),
              const SizedBox(height: 8),
              Text('Tips', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
            ],
          ),

          // Capture Button
          GestureDetector(
            onTap: onCapture,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.secondaryPurple.withValues(alpha: 0.4), blurRadius: 20),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner white circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Progress Ring around it
                  ProgressRing(
                    progress: captureProgress,
                    size: 80,
                    strokeWidth: 4,
                    centerChild: const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

          // Gallery Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassCard(
                width: 56,
                height: 56,
                padding: EdgeInsets.zero,
                borderRadius: 16,
                baseColor: AppColors.glassWhite,
                child: const Center(
                  child: Icon(Icons.photo_library_outlined, color: AppColors.textPrimary, size: 28),
                ),
              ),
              const SizedBox(height: 8),
              Text('Gallery', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
