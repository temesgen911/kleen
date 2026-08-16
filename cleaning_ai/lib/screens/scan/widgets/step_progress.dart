import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

class StepProgress extends StatelessWidget {
  final int currentStep;
  
  const StepProgress({super.key, this.currentStep = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(1, 'Capture', currentStep >= 1),
          _buildLine(currentStep >= 2),
          _buildStep(2, 'AI Detect', currentStep >= 2),
          _buildLine(currentStep >= 3),
          _buildStep(3, 'Review', currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.secondaryPurple : Colors.transparent,
            border: Border.all(
              color: isActive ? AppColors.secondaryPurple : AppColors.textMuted,
              width: 1.5,
            ),
            boxShadow: isActive ? [
              BoxShadow(color: AppColors.secondaryPurple.withValues(alpha: 0.6), blurRadius: 12)
            ] : null,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isActive ? AppColors.secondaryPurple : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 24),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondaryPurple : AppColors.textMuted.withValues(alpha: 0.3),
          boxShadow: isActive ? [
            BoxShadow(color: AppColors.secondaryPurple.withValues(alpha: 0.5), blurRadius: 4)
          ] : null,
        ),
      ),
    );
  }
}
