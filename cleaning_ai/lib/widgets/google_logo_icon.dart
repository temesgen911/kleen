import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Official Google "G" 4-color Vector Logo Widget.
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double center = s / 2.0;
    final double radius = s * 0.46;
    final double strokeWidth = s * 0.20;

    final Rect rect = Rect.fromCircle(
      center: Offset(center, center),
      radius: radius - (strokeWidth / 2),
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // 1. Red Arc (Top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.50, false, paint);

    // 2. Yellow Arc (Left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 0.50, false, paint);

    // 3. Green Arc (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.50, false, paint);

    // 4. Blue Arc (Right / Crossbar transition)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.25, math.pi * 0.50, false, paint);

    // 5. Blue Horizontal Crossbar
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double barHeight = strokeWidth;
    final double barWidth = radius + (strokeWidth * 0.1);
    final Rect barRect = Rect.fromLTWH(
      center - (strokeWidth * 0.1),
      center - (barHeight / 2),
      barWidth,
      barHeight,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
