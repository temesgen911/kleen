import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// Step progress indicator for the Review screen.
/// Steps 1 & 2 appear as completed (purple with ✓).
/// Step 3 is active (orange/gold).
class ReviewStepProgress extends StatelessWidget {
  const ReviewStepProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(1, 'Capture',   StepState.completed),
          _buildLine(isActive: true),
          _buildStep(2, 'AI Detect', StepState.completed),
          _buildLine(isActive: true, useOrange: true),
          _buildStep(3, 'Review',    StepState.active),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, StepState state) {
    final isCompleted = state == StepState.completed;
    final isActive    = state == StepState.active;

    final Color circleColor = isActive
        ? AppColors.accentOrange
        : isCompleted
            ? AppColors.secondaryPurple
            : Colors.transparent;

    final Color labelColor = isActive
        ? AppColors.accentOrange
        : isCompleted
            ? AppColors.secondaryPurple
            : AppColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(color: circleColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: circleColor.withValues(alpha: 0.55),
                blurRadius: 12,
              )
            ],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
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
            color: labelColor,
            fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isActive, bool useOrange = false}) {
    final Color lineColor = useOrange
        ? AppColors.accentOrange
        : isActive
            ? AppColors.secondaryPurple
            : AppColors.textMuted.withValues(alpha: 0.3);

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 24),
        decoration: BoxDecoration(
          color: lineColor,
          boxShadow: isActive
              ? [BoxShadow(color: lineColor.withValues(alpha: 0.5), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}

enum StepState { inactive, active, completed }
