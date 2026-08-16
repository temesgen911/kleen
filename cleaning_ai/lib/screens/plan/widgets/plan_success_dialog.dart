import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../screens/home/home_screen.dart';

class PlanSuccessDialog extends StatefulWidget {
  const PlanSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const PlanSuccessDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  State<PlanSuccessDialog> createState() => _PlanSuccessDialogState();
}

class _PlanSuccessDialogState extends State<PlanSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowExpand;
  late final Animation<double> _checkScale;
  late final Animation<double> _textFade;
  late final Animation<double> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glowExpand = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.55, curve: Curves.elasticOut),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
    );

    _particles = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.80, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Auto navigate to Home on completion
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient Expanding Glow
                  CustomPaint(
                    size: const Size(360, 360),
                    painter: _SuccessGlowPainter(
                      glowProgress: _glowExpand.value,
                      particlesProgress: _particles.value,
                    ),
                  ),

                  // Center Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Luminous Checkmark Container
                        Transform.scale(
                          scale: _checkScale.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  AppColors.primaryTeal,
                                  AppColors.secondaryPurple,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryTeal
                                      .withValues(alpha: 0.5 * _checkScale.value),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: AppColors.secondaryPurple
                                      .withValues(alpha: 0.4 * _checkScale.value),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 2.0,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Title
                        Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - _textFade.value)),
                            child: Column(
                              children: [
                                Text(
                                  'Your plan is ready',
                                  style: AppTypography.heading1.copyWith(
                                    fontSize: 24,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.primaryTeal
                                            .withValues(alpha: 0.4),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'We\'ll keep your cleaning on track.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SuccessGlowPainter extends CustomPainter {
  final double glowProgress;
  final double particlesProgress;

  _SuccessGlowPainter({
    required this.glowProgress,
    required this.particlesProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer subtle expanding wave
    final outerRadius = 70 + (glowProgress * 100);
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryTeal.withValues(alpha: 0.25 * (1.0 - glowProgress * 0.5)),
          AppColors.secondaryPurple.withValues(alpha: 0.15 * (1.0 - glowProgress * 0.7)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawCircle(center, outerRadius, outerPaint);

    // Settling subtle luminous particles / glass node rings
    const particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi / particleCount) + (particlesProgress * 0.2);
      final dist = 85 + (1 - particlesProgress) * 35;
      final px = center.dx + dist * math.cos(angle);
      final py = center.dy + dist * math.sin(angle);

      final pAlpha = (particlesProgress * 0.6).clamp(0.0, 0.6);
      final nodePaint = Paint()
        ..color = (i % 2 == 0 ? AppColors.primaryTeal : AppColors.secondaryPurple)
            .withValues(alpha: pAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), 2.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessGlowPainter old) =>
      old.glowProgress != glowProgress ||
      old.particlesProgress != particlesProgress;
}
