import 'package:flutter/material.dart';
import '../../../models/app_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/streak_flame.dart';

/// Fullscreen transparent overlay displaying animated jumping streak flame
/// and motivational message upon tapping the streak card.
class StreakOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const StreakOverlay({
    super.key,
    required this.onClose,
  });

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StreakOverlay',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return StreakOverlay(onClose: () => Navigator.of(context).pop());
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<StreakOverlay> createState() => _StreakOverlayState();
}

class _StreakOverlayState extends State<StreakOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = AppState.instance.streak;
    final currentStreak = streak.currentStreak;

    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Jumping Flame Container
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFF9100),
                          Color(0xFFFF3D00),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: StreakFlame(
                        streakCount: currentStreak,
                        isCompact: false,
                        size: 80,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Streak Count Title
                Text(
                  '$currentStreak Day Streak! 🔥',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Motivational Message Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF9100).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        currentStreak > 0
                            ? 'You\'re on fire! Keep up the amazing momentum to keep your home glowing clean.'
                            : 'Start your daily reset scan to ignite your streak today!',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFFFFE0B2),
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: AppColors.textMuted, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Tap anywhere to return home',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
