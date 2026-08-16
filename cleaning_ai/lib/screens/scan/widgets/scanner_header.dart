import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';

class ScannerHeader extends StatelessWidget {
  const ScannerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GlassCard(
            width: 44,
            height: 44,
            padding: EdgeInsets.zero,
            borderRadius: 12,
            baseColor: AppColors.glassWhite,
            onTap: () => Navigator.pop(context),
            child: const Center(
              child: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
            ),
          ),
          
          // Title
          Text(
            'Scan Your Room',
            style: AppTypography.heading2.copyWith(color: AppColors.textPrimary, fontSize: 20),
          ),

          // Cancel text button
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
