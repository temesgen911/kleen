import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../models/cleaning_streak.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/streak_flame.dart';
import '../home/home_screen.dart';

/// Screen displayed immediately upon completing the last required daily task.
class DailyCompletionScreen extends StatefulWidget {
  final int completedTasksCount;
  final int totalMinutes;
  final CleaningStreak streak;

  const DailyCompletionScreen({
    super.key,
    required this.completedTasksCount,
    required this.totalMinutes,
    required this.streak,
  });

  @override
  State<DailyCompletionScreen> createState() => _DailyCompletionScreenState();
}

class _DailyCompletionScreenState extends State<DailyCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _flameScale;
  late final Animation<double> _contentFade;
  late final Animation<double> _badgeSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _flameScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
    );

    _badgeSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.40, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _returnHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStreak = widget.streak.isFirstStreak;
    final currentStreak = widget.streak.currentStreak;

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // Background ambient gradient
          Container(color: AppColors.backgroundStart),

          // Warm golden/amber ambient radial aura behind the flame
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9100).withValues(alpha: 0.18),
                    const Color(0xFFFF3D00).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Top Header Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.primaryTeal, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'RESET COMPLETE',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primaryTeal,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Animated Flame & Streak Counter
                  AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _flameScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            StreakFlame(
                              streakCount: currentStreak,
                              isFirstStreak: isFirstStreak,
                              size: 190,
                            ),
                            Positioned(
                              bottom: 22,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$currentStreak',
                                    style: AppTypography.heading1.copyWith(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.8),
                                          blurRadius: 16,
                                        ),
                                        Shadow(
                                          color: const Color(0xFFFF9100)
                                              .withValues(alpha: 0.8),
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currentStreak == 1
                                        ? 'DAY STREAK'
                                        : 'DAYS STREAK',
                                    style: AppTypography.label.copyWith(
                                      color: const Color(0xFFFFE082),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Motivational Typography
                  AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _contentFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _badgeSlide.value),
                          child: Column(
                            children: [
                              Text(
                                isFirstStreak
                                    ? 'Your first streak!'
                                    : '$currentStreak days in a row!',
                                style: AppTypography.heading1.copyWith(
                                  fontSize: 26,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  isFirstStreak
                                      ? 'You showed up today. Keep it going tomorrow.'
                                      : 'You showed up and took care of your space. Keep the momentum going!',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Session Summary Glass Card
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    baseColor: AppColors.glassWhite,
                    glowColor: AppColors.primaryTeal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          icon: Icons.timer_outlined,
                          value: '${widget.totalMinutes} min',
                          label: 'Cleaned',
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        _buildStatColumn(
                          icon: Icons.check_circle_outline,
                          value: '${widget.completedTasksCount} tasks',
                          label: 'Completed',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Primary Button "Back to Home"
                  PrimaryButton(
                    text: 'Back to Home',
                    icon: Icons.arrow_forward,
                    onTap: _returnHome,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
