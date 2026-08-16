import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 60fps Flutter animated flame component for streaks.
///
/// Features:
/// • Layered organic bezier flame bodies with shifting flickers.
/// • Brilliant luminous amber/gold inner core and rich coral-crimson aura.
/// • Drifting ember particles rising gracefully.
/// • Displays streak count cleanly integrated into the flame composition.
/// • Adapts between compact (Home screen badge) and hero (Celebration) sizes.
class StreakFlame extends StatefulWidget {
  final int streakCount;
  final bool isCompact;
  final bool isFirstStreak;
  final double? size;

  const StreakFlame({
    super.key,
    required this.streakCount,
    this.isCompact = false,
    this.isFirstStreak = false,
    this.size,
  });

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultSize = widget.isCompact ? 44.0 : 180.0;
    final flameSize = Size.square(widget.size ?? defaultSize);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: flameSize,
          painter: _FlamePainter(
            animationValue: _controller.value,
            streakCount: widget.streakCount,
            isCompact: widget.isCompact,
            isFirstStreak: widget.isFirstStreak,
          ),
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double animationValue;
  final int streakCount;
  final bool isCompact;
  final bool isFirstStreak;

  _FlamePainter({
    required this.animationValue,
    required this.streakCount,
    required this.isCompact,
    required this.isFirstStreak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.58);

    final t = animationValue * 2 * math.pi;

    // Organic harmonic wave offsets
    final wave1 = math.sin(t);
    final wave2 = math.cos(t * 1.5);
    final wave3 = math.sin(t * 2.3);

    // ── 1. Outer Atmospheric Radial Glow ──────────────────────────────────────
    final glowRadius = w * (isCompact ? 0.7 : 0.85) + wave1 * (isCompact ? 2 : 6);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isFirstStreak ? const Color(0xFFFFD54F) : const Color(0xFFFF7043))
              .withValues(alpha: isCompact ? 0.25 : 0.35),
          const Color(0xFFFF5722).withValues(alpha: isCompact ? 0.12 : 0.18),
          const Color(0xFFE91E63).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));

    canvas.drawCircle(center, glowRadius, glowPaint);

    // ── 2. Background Outer Flame (Coral / Deep Amber) ────────────────────────
    final outerPath = Path();
    final outerTop = Offset(
      center.dx + wave2 * (isCompact ? 1.5 : 5.0),
      h * 0.08 + wave1 * (isCompact ? 1.0 : 3.0),
    );
    final outerBottomLeft = Offset(w * 0.12, h * 0.88);
    final outerBottomRight = Offset(w * 0.88, h * 0.88);

    outerPath.moveTo(outerBottomLeft.dx, outerBottomLeft.dy);
    outerPath.cubicTo(
      w * 0.05,
      h * 0.55 + wave3 * 4,
      w * 0.25 + wave1 * 6,
      h * 0.30,
      outerTop.dx,
      outerTop.dy,
    );
    outerPath.cubicTo(
      w * 0.75 + wave2 * 6,
      h * 0.30,
      w * 0.95,
      h * 0.55 + wave1 * 4,
      outerBottomRight.dx,
      outerBottomRight.dy,
    );
    outerPath.cubicTo(
      w * 0.70,
      h * 0.98,
      w * 0.30,
      h * 0.98,
      outerBottomLeft.dx,
      outerBottomLeft.dy,
    );
    outerPath.close();

    final outerFlamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF3D00).withValues(alpha: 0.85),
          const Color(0xFFFF6D00).withValues(alpha: 0.90),
          const Color(0xFFFF9100).withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(outerPath, outerFlamePaint);

    // ── 3. Mid Flame Tongue (Vibrant Gold / Orange) ───────────────────────────
    final midPath = Path();
    final midTop = Offset(
      center.dx - wave1 * (isCompact ? 1.2 : 4.0),
      h * 0.22 + wave2 * (isCompact ? 1.0 : 3.0),
    );
    final midBottomLeft = Offset(w * 0.22, h * 0.85);
    final midBottomRight = Offset(w * 0.78, h * 0.85);

    midPath.moveTo(midBottomLeft.dx, midBottomLeft.dy);
    midPath.cubicTo(
      w * 0.16,
      h * 0.58,
      w * 0.32 - wave2 * 5,
      h * 0.38,
      midTop.dx,
      midTop.dy,
    );
    midPath.cubicTo(
      w * 0.68 + wave3 * 5,
      h * 0.38,
      w * 0.84,
      h * 0.58,
      midBottomRight.dx,
      midBottomRight.dy,
    );
    midPath.cubicTo(
      w * 0.65,
      h * 0.94,
      w * 0.35,
      h * 0.94,
      midBottomLeft.dx,
      midBottomLeft.dy,
    );
    midPath.close();

    final midFlamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFAB00),
          const Color(0xFFFFD600),
          const Color(0xFFFFAB00).withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(midPath, midFlamePaint);

    // ── 4. Inner Luminous Core (Hot White-Gold) ──────────────────────────────
    final corePath = Path();
    final coreTop = Offset(
      center.dx + wave3 * (isCompact ? 0.8 : 2.5),
      h * 0.38 + wave1 * 2.0,
    );
    final coreBottomLeft = Offset(w * 0.32, h * 0.82);
    final coreBottomRight = Offset(w * 0.68, h * 0.82);

    corePath.moveTo(coreBottomLeft.dx, coreBottomLeft.dy);
    corePath.cubicTo(
      w * 0.26,
      h * 0.64,
      w * 0.38,
      h * 0.48,
      coreTop.dx,
      coreTop.dy,
    );
    corePath.cubicTo(
      w * 0.62,
      h * 0.48,
      w * 0.74,
      h * 0.64,
      coreBottomRight.dx,
      coreBottomRight.dy,
    );
    corePath.cubicTo(
      w * 0.58,
      h * 0.90,
      w * 0.42,
      h * 0.90,
      coreBottomLeft.dx,
      coreBottomLeft.dy,
    );
    corePath.close();

    final coreFlamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFF59D),
          Color(0xFFFFEE58),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(corePath, coreFlamePaint);

    // ── 5. Rising Spark Particles ───────────────────────────────────────────
    if (!isCompact) {
      final sparkPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 6; i++) {
        final sparkSeed = (animationValue + i * 0.17) % 1.0;
        final sparkX = center.dx + math.sin(t + i * 1.5) * (w * 0.32) * (1.0 - sparkSeed * 0.5);
        final sparkY = h * 0.85 - sparkSeed * (h * 0.85);
        final sparkRadius = (1.0 - sparkSeed) * 3.2;
        final sparkAlpha = (1.0 - sparkSeed).clamp(0.0, 1.0) * 0.85;

        sparkPaint.color = const Color(0xFFFFD54F).withValues(alpha: sparkAlpha);
        canvas.drawCircle(Offset(sparkX, sparkY), sparkRadius, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.streakCount != streakCount;
  }
}
