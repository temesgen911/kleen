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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassTeal,
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.2),
                      blurRadius: 10,
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
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Good morning, $displayName ✨',
                      style: AppTypography.greeting.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'AI cleaning assistant',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.75),
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
        const SizedBox(width: 12),
        Stack(
          children: [
            const IconBadge(
              icon: Icons.notifications_none,
              size: 40,
              iconColor: Colors.white,
              backgroundColor: AppColors.glassWhite,
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 7,
                height: 7,
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
