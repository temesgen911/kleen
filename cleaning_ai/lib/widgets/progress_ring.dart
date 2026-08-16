import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Widget centerChild;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.size,
    required this.centerChild,
    this.strokeWidth = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              strokeWidth: strokeWidth,
              color: AppColors.primaryTeal.withValues(alpha: 0.15),
            ),
          ),
          // Glow effect
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              color: AppColors.primaryTeal.withValues(alpha: 0.4),
              blurRadius: 10,
            ),
          ),
          // Foreground progress
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              color: AppColors.primaryTeal,
              isGradient: true,
            ),
          ),
          centerChild,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final bool isGradient;
  final double blurRadius;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    this.isGradient = false,
    this.blurRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
      paint.color = color;
    } else if (isGradient) {
      paint.shader = const SweepGradient(
        colors: [Color(0xFF28E0B3), Color(0xFF9B6FE6)],
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        tileMode: TileMode.clamp,
      ).createShader(rect);
    } else {
      paint.color = color;
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
