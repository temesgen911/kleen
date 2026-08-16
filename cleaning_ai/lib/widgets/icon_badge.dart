import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    this.iconColor = AppColors.primaryTeal,
    this.backgroundColor = AppColors.glassTeal,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        // Crisp 1px luminous edge
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          // Subtle colored glow
          BoxShadow(
            color: iconColor.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
