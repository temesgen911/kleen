import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/glass_card.dart';

class NextScanCard extends StatelessWidget {
  const NextScanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      baseColor: AppColors.secondaryPurple,
      glowColor: AppColors.secondaryPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.document_scanner, color: AppColors.secondaryPurple, size: 16),
              const SizedBox(width: 8),
              Text('NEXT SCAN', style: AppTypography.label.copyWith(color: AppColors.secondaryPurple)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Living room scan', style: AppTypography.heading2),
                    const SizedBox(height: 4),
                    Text('Last scan: May 12, 9:30 AM', style: AppTypography.bodySmall),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondaryPurple.withValues(alpha: 0.30),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.secondaryPurple, size: 14),
                          const SizedBox(width: 8),
                          Text('Tomorrow, 9:00 AM', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.85),
                  border: Border.all(
                    color: AppColors.secondaryPurple.withValues(alpha: 0.40),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.view_in_ar, color: AppColors.secondaryPurple, size: 40),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scanned rooms', style: AppTypography.bodySmall),
                  Text('4 / 6', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _buildRoomIcon(Icons.chair, true),
                  _buildRoomIcon(Icons.bed, true),
                  _buildRoomIcon(Icons.bathtub, true),
                  _buildRoomIcon(Icons.restaurant, true),
                  _buildRoomIcon(Icons.door_sliding, false),
                  _buildRoomIcon(Icons.garage, false),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRoomIcon(IconData icon, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: active ? AppColors.secondaryPurple : Colors.white24, size: 20),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppColors.secondaryPurple : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: active ? [BoxShadow(color: AppColors.secondaryPurple, blurRadius: 4)] : null,
            ),
          )
        ],
      ),
    );
  }
}
