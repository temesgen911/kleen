import 'package:flutter/material.dart';
import '../../../models/app_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/streak_flame.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final streak = AppState.instance.streak;
        final currentStreak = streak.currentStreak;
        final hasStreak = currentStreak > 0;

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 100, // Pill shape
          baseColor: AppColors.glassWhite,
          glowColor: hasStreak ? const Color(0xFFFF9100) : AppColors.glassWhite,
          child: Row(
            children: [
              // Animated Flame Pill Icon
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasStreak
                          ? const Color(0xFFFF9100).withValues(alpha: 0.12)
                          : AppColors.primaryTeal.withValues(alpha: 0.1),
                      border: Border.all(
                        color: hasStreak
                            ? const Color(0xFFFF9100).withValues(alpha: 0.4)
                            : AppColors.primaryTeal.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasStreak
                              ? const Color(0xFFFF9100).withValues(alpha: 0.25)
                              : AppColors.primaryTeal.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: StreakFlame(
                        streakCount: currentStreak,
                        isCompact: true,
                        size: 38,
                      ),
                    ),
                  ),
                  if (hasStreak)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundStart,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$currentStreak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasStreak
                          ? '$currentStreak-day streak'
                          : 'Cleaning streak',
                      style: AppTypography.heading2.copyWith(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      hasStreak
                          ? (currentStreak == 1
                              ? 'Day 1 complete. Keep it going!'
                              : 'You\'re on a roll! Keep it going 🔥')
                          : 'Start today\'s reset to begin!',
                      style: AppTypography.bodySmall.copyWith(
                        color: hasStreak
                            ? const Color(0xFFFFCC80)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        );
      },
    );
  }
}
