import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/icon_badge.dart';
import '../../../theme/app_colors.dart';

class HeaderSection extends StatelessWidget {
  final String displayName;

  const HeaderSection({
    super.key,
    this.displayName = 'Emma',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassTeal,
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryTeal,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning,\n$displayName ✨',
                      style: AppTypography.greeting,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI cleaning assistant',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Stack(
          children: [
            const IconBadge(
              icon: Icons.notifications_none,
              size: 48,
              iconColor: Colors.white,
              backgroundColor: AppColors.glassWhite,
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
