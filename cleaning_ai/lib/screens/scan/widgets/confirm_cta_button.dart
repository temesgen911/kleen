import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// The orange → coral gradient CTA button for finalizing the room scan.
class ConfirmCtaButton extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmCtaButton({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: onConfirm,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(
              colors: [AppColors.accentOrange, AppColors.accentCoral],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.40),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.40),
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
              // Upper highlight specular line
              Positioned(
                top: 0,
                left: 24,
                right: 24,
                child: Container(
                  height: 1.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Label
              Center(
                child: Text(
                  'Confirm Room & Continue',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
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
