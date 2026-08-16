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
  final Duration? actualDuration;
  final int? plannedMinutes;

  const DailyCompletionScreen({
    super.key,
    required this.completedTasksCount,
    required this.totalMinutes,
    required this.streak,
    this.actualDuration,
    this.plannedMinutes,
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

  bool _hasAdjustedPlan = false;
  bool _hasDismissedPacing = false;

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

  void _applyPacingAdjustment(double ratio) {
    final plan = AppState.instance.activePlan;
    if (plan != null) {
      plan.applyPacingAdjustment(ratio);
      setState(() {
        _hasAdjustedPlan = true;
      });
    }
  }

  String _formatActualDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds.remainder(60);
    if (mins > 0 && secs > 0) return '${mins}m ${secs}s';
    if (mins > 0) return '$mins min';
    return '$secs s';
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStreak = widget.streak.isFirstStreak;
    final currentStreak = widget.streak.currentStreak;

    final plannedMins = widget.plannedMinutes ?? widget.totalMinutes;
    final actual = widget.actualDuration ?? Duration(minutes: plannedMins);
    final plannedDuration = Duration(minutes: plannedMins);
    final diffSeconds = actual.inSeconds - plannedDuration.inSeconds;

    final isSignificantlyFaster = diffSeconds < -20;
    final isSignificantlyLonger = diffSeconds > 20;
    final isOnTime = !isSignificantlyFaster && !isSignificantlyLonger;

    final pacingRatio = actual.inSeconds > 0 && plannedDuration.inSeconds > 0
        ? (actual.inSeconds / plannedDuration.inSeconds)
        : 1.0;

    String deltaLabel;
    Color deltaColor;
    if (isSignificantlyFaster) {
      final savedSec = -diffSeconds;
      final sm = savedSec ~/ 60;
      final ss = savedSec % 60;
      deltaLabel = sm > 0
          ? '$sm min ${ss > 0 ? '$ss s ' : ''}faster than plan ⚡'
          : '$ss s faster than plan ⚡';
      deltaColor = const Color(0xFF00E676);
    } else if (isSignificantlyLonger) {
      final extraSec = diffSeconds;
      final em = extraSec ~/ 60;
      final es = extraSec % 60;
      deltaLabel = em > 0
          ? '$em min ${es > 0 ? '$es s ' : ''}longer than plan ⏳'
          : '$es s longer than plan ⏳';
      deltaColor = const Color(0xFFFF9100);
    } else {
      deltaLabel = 'Spot on with the plan estimate! 🎯';
      deltaColor = AppColors.primaryTeal;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // Background ambient gradient
          Container(color: AppColors.backgroundStart),

          // Warm golden/amber ambient radial aura behind the flame
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

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

                  const SizedBox(height: 20),

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
                              size: 180,
                            ),
                            Positioned(
                              bottom: 20,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$currentStreak',
                                    style: AppTypography.heading1.copyWith(
                                      fontSize: 46,
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

                  const SizedBox(height: 18),

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
                                  fontSize: 24,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  isFirstStreak
                                      ? 'You showed up today. Keep it going tomorrow.'
                                      : 'You showed up and took care of your space. Keep the momentum going!',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Session Summary Glass Card ─────────────────────────────
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    baseColor: AppColors.glassWhite,
                    glowColor: AppColors.primaryTeal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          icon: Icons.timer_outlined,
                          value: _formatActualDuration(actual),
                          label: 'Actual time',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        _buildStatColumn(
                          icon: Icons.schedule,
                          value: '$plannedMins min',
                          label: 'Planned',
                        ),
                        Container(
                          width: 1,
                          height: 30,
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

                  const SizedBox(height: 14),

                  // ── Pacing Insight & Readjustment Card ───────────────────────
                  if (!_hasDismissedPacing) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      baseColor: AppColors.glassWhite,
                      glowColor: _hasAdjustedPlan
                          ? const Color(0xFF00E676)
                          : deltaColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Tag with Delta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _hasAdjustedPlan
                                        ? Icons.check_circle
                                        : (isSignificantlyFaster
                                            ? Icons.bolt
                                            : Icons.speed),
                                    color: _hasAdjustedPlan
                                        ? const Color(0xFF00E676)
                                        : deltaColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PACING INSIGHT',
                                    style: AppTypography.label.copyWith(
                                      color: _hasAdjustedPlan
                                          ? const Color(0xFF00E676)
                                          : deltaColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: deltaColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: deltaColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  deltaLabel,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: deltaColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          if (_hasAdjustedPlan) ...[
                            // Confirmation banner
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Color(0xFF00E676), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Weekly plan times adjusted to match your actual pace! ✨',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              isSignificantlyFaster
                                  ? 'You finished faster than scheduled. Would you like to adjust your weekly plan with shorter estimated times?'
                                  : (isSignificantlyLonger
                                      ? 'Cleaning took longer than scheduled. Would you like to adjust your weekly plan with more generous task times?'
                                      : 'Your pace matches the plan perfectly. Keep it going!'),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),

                            if (!isOnTime) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: PrimaryButton(
                                      text: 'Adjust plan times',
                                      icon: Icons.tune,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      onTap: () =>
                                          _applyPacingAdjustment(pacingRatio),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _hasDismissedPacing = true;
                                      });
                                    },
                                    child: Text(
                                      'Keep as is',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Primary Button "Back to Home" ───────────────────────────
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
        Icon(icon, color: AppColors.primaryTeal, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
