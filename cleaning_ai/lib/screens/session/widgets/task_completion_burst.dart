import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// 450ms micro-celebration overlay for completing an individual cleaning task.
class TaskCompletionBurst extends StatefulWidget {
  final VoidCallback onComplete;
  final Widget child;

  const TaskCompletionBurst({
    super.key,
    required this.onComplete,
    required this.child,
  });

  @override
  State<TaskCompletionBurst> createState() => TaskCompletionBurstState();
}

class TaskCompletionBurstState extends State<TaskCompletionBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstCtrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _edgeSweep;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  bool _isBursting = false;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkScale = Tween<double>(begin: 0.2, end: 1.15).animate(
      CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _checkOpacity = CurvedAnimation(
      parent: _burstCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );

    _edgeSweep = CurvedAnimation(
      parent: _burstCtrl,
      curve: const Interval(0.15, 0.65, curve: Curves.easeInOut),
    );

    _cardScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    _cardOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.60, 1.0, curve: Curves.easeInQuad),
      ),
    );

    _burstCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  void triggerBurst() {
    setState(() => _isBursting = true);
    _burstCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBursting) return widget.child;

    return AnimatedBuilder(
      animation: _burstCtrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Collapsing Card
            Transform.scale(
              scale: _cardScale.value,
              child: Opacity(
                opacity: _cardOpacity.value,
                child: CustomPaint(
                  foregroundPainter: _EdgeSweepPainter(sweepProgress: _edgeSweep.value),
                  child: widget.child,
                ),
              ),
            ),

            // Expanding Cyan Pulse Ring & Popping Checkmark
            if (_checkOpacity.value > 0.0)
              Transform.scale(
                scale: _checkScale.value,
                child: Opacity(
                  opacity: (1.0 - _burstCtrl.value).clamp(0.0, 1.0),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EdgeSweepPainter extends CustomPainter {
  final double sweepProgress;

  _EdgeSweepPainter({required this.sweepProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (sweepProgress <= 0.0 || sweepProgress >= 1.0) return;

    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.5 + sweepProgress * 3.0, -1.0),
        end: Alignment(-0.5 + sweepProgress * 3.0, 1.0),
        colors: [
          Colors.transparent,
          AppColors.primaryTeal.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
          AppColors.primaryTeal.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );
    canvas.drawRRect(rrect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _EdgeSweepPainter oldDelegate) =>
      oldDelegate.sweepProgress != sweepProgress;
}
