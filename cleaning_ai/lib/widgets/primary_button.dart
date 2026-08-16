import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../theme/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          // Tight, intense glow (not fuzzy)
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.50),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          // Dark underside for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF30F5D6), // Rich teal start
                  Color(0xFF1BFFE0), // Luminous teal end
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(100),
              // Crisp white edge line
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.0,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Narrow specular top highlight
                Positioned(
                  top: -8,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF0A1A1A), // Dark text on bright btn
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppConstants.spacingSm),
                      Icon(icon, size: 18, color: const Color(0xFF0A1A1A)),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
