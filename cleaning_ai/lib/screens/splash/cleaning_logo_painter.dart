import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'cleaning_logo_geometry.dart';

/// 60fps CustomPainter rendering the Cleaning AI luminous symbol creation animation.
class CleaningLogoPainter extends CustomPainter {
  /// Curve draw progress along the spine: 0.0 (dark start) to 1.0 (reached star)
  final double curveProgress;

  /// Sparkle scale / expansion: 0.0 to 1.0 (settled)
  final double sparkleProgress;

  /// Sparkle center white flash glint intensity: 0.0 to 1.0
  final double sparkleFlash;

  /// Sparkle shockwave pulse progress: 0.0 to 1.0
  final double shockwaveProgress;

  /// Ambient background violet/cyan glow intensity: 0.0 to 1.0
  final double ambientGlowAlpha;

  /// Breathing scale: 1.0 to ~1.02
  final double breathScale;

  /// Overall logo opacity
  final double logoOpacity;

  /// Overall scaling (for exit dissolve)
  final double globalScale;

  CleaningLogoPainter({
    required this.curveProgress,
    required this.sparkleProgress,
    required this.sparkleFlash,
    required this.shockwaveProgress,
    required this.ambientGlowAlpha,
    required this.breathScale,
    required this.logoOpacity,
    required this.globalScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);

    // ── 1. Ambient Atmosphere (Subtle violet & cyan depth) ───────────────────
    _paintAmbientGlow(canvas, size, center);

    if (curveProgress <= 0.0 && sparkleProgress <= 0.0) return;

    // Apply global scaling & breathing transforms around center
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(globalScale * breathScale, globalScale * breathScale);
    canvas.translate(-center.dx, -center.dy);

    final s = CleaningLogoGeometry.getScale(size);
    final offset = CleaningLogoGeometry.getOffset(size);
    final starCenterGlobal = Offset(
      offset.dx + CleaningLogoGeometry.starCenter.dx * s,
      offset.dy + CleaningLogoGeometry.starCenter.dy * s,
    );

    // ── 2. Draw The Crescent Curve ──────────────────────────────────────────
    if (curveProgress > 0.0) {
      _paintCrescent(canvas, size, s, offset);
    }

    // ── 3. Draw The 4-Point Star Sparkle ────────────────────────────────────
    if (sparkleProgress > 0.0) {
      _paintStar(canvas, size, starCenterGlobal, s);
    }

    // ── 4. Shockwave Ripple from Sparkle ────────────────────────────────────
    if (shockwaveProgress > 0.0 && shockwaveProgress < 1.0) {
      _paintShockwave(canvas, starCenterGlobal, s);
    }

    // ── 5. Lens Glint Flash ─────────────────────────────────────────────────
    if (sparkleFlash > 0.0) {
      _paintSparkleFlash(canvas, starCenterGlobal, s);
    }

    // ── 6. Moving Light Head (Tracing Beam Point) ───────────────────────────
    if (curveProgress > 0.0 && curveProgress < 1.0) {
      _paintLightHead(canvas, size, s);
    }

    canvas.restore();
  }

  // ── Ambient Glow Background ───────────────────────────────────────────────
  void _paintAmbientGlow(Canvas canvas, Size size, Offset center) {
    if (ambientGlowAlpha <= 0.0) return;

    // Deep violet-indigo ambient aura
    final violetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.secondaryPurple.withValues(alpha: 0.12 * ambientGlowAlpha),
          AppColors.accentIndigo.withValues(alpha: 0.06 * ambientGlowAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.65));
    canvas.drawCircle(center, size.shortestSide * 0.65, violetPaint);

    // Soft cyan backlight halo behind the symbol
    final cyanPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryTeal.withValues(alpha: 0.16 * ambientGlowAlpha * logoOpacity),
          AppColors.primaryTeal.withValues(alpha: 0.04 * ambientGlowAlpha * logoOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.45));
    canvas.drawCircle(center, size.shortestSide * 0.45, cyanPaint);
  }

  // ── Paint Crescent Stroke with Progressive Reveal ─────────────────────────
  void _paintCrescent(Canvas canvas, Size size, double scale, Offset offset) {
    final crescentPath = CleaningLogoGeometry.getCrescentPath(size);
    final metric = CleaningLogoGeometry.getSpineMetric(size);
    if (metric == null) return;

    final currentLen = metric.length * curveProgress.clamp(0.0, 1.0);
    final bounds = crescentPath.getBounds();

    // If still in drawing phase (curveProgress < 1.0), mask by revealed spine envelope
    if (curveProgress < 1.0) {
      final extracted = metric.extractPath(0.0, currentLen);
      final tangent = metric.getTangentForOffset(currentLen);

      // Create a smooth stroke mask that encapsulates the revealed portion
      final maskPath = Path();
      maskPath.addPath(extracted, Offset.zero);

      // Expand mask along extracted path to cover the varying width of the crescent
      final strokeMask = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 44.0 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.saveLayer(bounds.inflate(30 * scale), Paint());

      // Draw the progressive stroke path as the clipping mask
      canvas.drawPath(extracted, strokeMask);

      // Also add circle at current head position to ensure clean forward edge
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 22.0 * scale, Paint()..style = PaintingStyle.fill);
      }

      // Intersect with the crescent shape
      final fillPaint = Paint()
        ..blendMode = BlendMode.srcIn
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF00E5FF),
            Color(0xFF1BFFE0),
            Color(0xFF6AFFFF),
          ],
          stops: [0.0, 0.65, 1.0],
        ).createShader(bounds);

      // Outer glow of crescent
      final glowPaint = Paint()
        ..blendMode = BlendMode.srcIn
        ..color = const Color(0xFF1BFFE0).withValues(alpha: 0.6 * logoOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * scale);
      canvas.drawPath(crescentPath, glowPaint);

      // Solid body of crescent
      canvas.drawPath(crescentPath, fillPaint);

      // Trailing hot white core near the head during drawing
      final trailStart = math.max(0.0, currentLen - metric.length * 0.22);
      final trailPath = metric.extractPath(trailStart, currentLen);
      final trailPaint = Paint()
        ..blendMode = BlendMode.srcIn
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 * scale
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.85),
          ],
        ).createShader(bounds);
      canvas.drawPath(trailPath, trailPaint);

      canvas.restore();
    } else {
      // Fully formed crescent: Render with multi-layer glowing gradients
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: logoOpacity),
            const Color(0xFF1BFFE0).withValues(alpha: logoOpacity),
            const Color(0xFF8BFFFF).withValues(alpha: logoOpacity),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(bounds);

      // 1. Deep outer halo
      final deepGlow = Paint()
        ..color = const Color(0xFF1BFFE0).withValues(alpha: 0.25 * logoOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * scale);
      canvas.drawPath(crescentPath, deepGlow);

      // 2. Medium bloom
      final midGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45 * logoOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * scale);
      canvas.drawPath(crescentPath, midGlow);

      // 3. Solid body
      canvas.drawPath(crescentPath, fillPaint);

      // 4. Subtle inner bright spine
      final spinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Colors.white.withValues(alpha: 0.1 * logoOpacity),
            Colors.white.withValues(alpha: 0.6 * logoOpacity),
            Colors.white.withValues(alpha: 0.9 * logoOpacity),
          ],
        ).createShader(bounds);
      final fullSpine = CleaningLogoGeometry.getSpinePath(size);
      canvas.drawPath(fullSpine, spinePaint);
    }
  }

  // ── Paint 4-Point Star Sparkle ────────────────────────────────────────────
  void _paintStar(Canvas canvas, Size size, Offset starCenter, double scale) {
    final starPath = CleaningLogoGeometry.getStarPath(size, scale: sparkleProgress);
    final bounds = starPath.getBounds();

    // Multi-layer star rendering
    final starGlow = Paint()
      ..color = const Color(0xFF1BFFE0).withValues(alpha: 0.55 * logoOpacity * sparkleProgress.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale);
    canvas.drawPath(starPath, starGlow);

    final starFill = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: logoOpacity),
          const Color(0xFF1BFFE0).withValues(alpha: logoOpacity),
          const Color(0xFF00E5FF).withValues(alpha: logoOpacity),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(bounds);
    canvas.drawPath(starPath, starFill);

    // Center radiant diamond core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: logoOpacity * sparkleProgress.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * scale);
    canvas.drawCircle(starCenter, 3.5 * scale * sparkleProgress, corePaint);
  }

  // ── Moving Light Head (Point of Intelligent Light) ────────────────────────
  void _paintLightHead(Canvas canvas, Size size, double scale) {
    final metric = CleaningLogoGeometry.getSpineMetric(size);
    if (metric == null) return;

    final currentLen = metric.length * curveProgress.clamp(0.0, 1.0);
    final tangent = metric.getTangentForOffset(currentLen);
    if (tangent == null) return;

    final pos = tangent.position;

    // 1. Soft wide outer halo
    final outerHalo = Paint()
      ..color = const Color(0xFF1BFFE0).withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * scale);
    canvas.drawCircle(pos, 16.0 * scale, outerHalo);

    // 2. Focused cyan bloom
    final cyanBloom = Paint()
      ..color = const Color(0xFF38E5FF).withValues(alpha: 0.85)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale);
    canvas.drawCircle(pos, 8.5 * scale, cyanBloom);

    // 3. Bright white-cyan core pinpoint
    final whiteCore = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 3.5 * scale, whiteCore);

    // 4. Tiny trailing forward glow
    final forwardPos = pos + Offset.fromDirection(tangent.angle, 2.0 * scale);
    final tinyGlint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(forwardPos, 2.0 * scale, tinyGlint);
  }

  // ── Shockwave Pulse from Star Creation ────────────────────────────────────
  void _paintShockwave(Canvas canvas, Offset center, double scale) {
    final radius = (12.0 + shockwaveProgress * 48.0) * scale;
    final alpha = (1.0 - shockwaveProgress) * 0.45;

    final shockPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * (1.0 - shockwaveProgress * 0.5)
      ..color = const Color(0xFF1BFFE0).withValues(alpha: alpha.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(center, radius, shockPaint);
  }

  // ── Sparkle Lens Glint Flash ──────────────────────────────────────────────
  void _paintSparkleFlash(Canvas canvas, Offset center, double scale) {
    final intensity = sparkleFlash.clamp(0.0, 1.0);
    if (intensity <= 0.0) return;

    final armLen = 32.0 * scale * (0.5 + intensity * 0.5);
    final flareWidth = 1.8 * scale;

    final flarePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: intensity * 0.95),
          const Color(0xFF1BFFE0).withValues(alpha: intensity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: armLen))
      ..strokeCap = StrokeCap.round;

    // Horizontal flare
    canvas.drawLine(
      Offset(center.dx - armLen, center.dy),
      Offset(center.dx + armLen, center.dy),
      flarePaint..strokeWidth = flareWidth,
    );

    // Vertical flare
    canvas.drawLine(
      Offset(center.dx, center.dy - armLen * 1.1),
      Offset(center.dx, center.dy + armLen * 1.1),
      flarePaint..strokeWidth = flareWidth,
    );

    // Intense central glint star
    final glintCircle = Paint()
      ..color = Colors.white.withValues(alpha: intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);
    canvas.drawCircle(center, 6.0 * scale * intensity, glintCircle);
  }

  @override
  bool shouldRepaint(covariant CleaningLogoPainter oldDelegate) {
    return oldDelegate.curveProgress != curveProgress ||
        oldDelegate.sparkleProgress != sparkleProgress ||
        oldDelegate.sparkleFlash != sparkleFlash ||
        oldDelegate.shockwaveProgress != shockwaveProgress ||
        oldDelegate.ambientGlowAlpha != ambientGlowAlpha ||
        oldDelegate.breathScale != breathScale ||
        oldDelegate.logoOpacity != logoOpacity ||
        oldDelegate.globalScale != globalScale;
  }
}
