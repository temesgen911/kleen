import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../widgets/progress_ring.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onTipsTap;
  final double captureProgress;
  final bool isCaptureDisabled;

  const CameraControls({
    super.key,
    required this.onCapture,
    this.onGalleryTap,
    this.onTipsTap,
    required this.captureProgress,
    this.isCaptureDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tips Button
          GestureDetector(
            onTap: onTipsTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassCard(
                  width: 56,
                  height: 56,
                  padding: EdgeInsets.zero,
                  borderRadius: 16,
                  baseColor: AppColors.glassWhite,
                  child: const Center(
                    child: Icon(Icons.lightbulb_outline,
                        color: AppColors.textPrimary, size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Tips',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),

          // Capture Button
          GestureDetector(
            onTap: isCaptureDisabled ? null : onCapture,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCaptureDisabled ? 0.6 : 1.0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryPurple
                          .withValues(alpha: isCaptureDisabled ? 0.15 : 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner white circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isCaptureDisabled
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
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
          ),

          // Gallery Button
          GestureDetector(
            onTap: onGalleryTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassCard(
                  width: 56,
                  height: 56,
                  padding: EdgeInsets.zero,
                  borderRadius: 16,
                  baseColor: AppColors.glassWhite,
                  child: const Center(
                    child: Icon(Icons.photo_library_outlined,
                        color: AppColors.textPrimary, size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Gallery',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
