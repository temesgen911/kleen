import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';

class AnalysisGlassCard extends StatelessWidget {
  final Animation<double> progressAnimation;
  final List<String> detectedObjects;

  const AnalysisGlassCard({
    super.key,
    required this.progressAnimation,
    required this.detectedObjects,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      baseColor: AppColors.glassWhite,
      glowColor: AppColors.secondaryPurple,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Mock Spatial Viz
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.85),
                  border: Border.all(
                    color: AppColors.secondaryPurple.withValues(alpha: 0.40),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(40, 40),
                      painter: _MockSpatialPainter(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Text & Progress Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Analyzing room ', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        const Icon(Icons.auto_awesome, color: AppColors.secondaryPurple, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Identifying cleaning-relevant\nsurfaces and objects.',
                      style: AppTypography.bodySmall.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: AnimatedBuilder(
                              animation: progressAnimation,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryPurple,
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.secondaryPurple.withValues(alpha: 0.5), blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedBuilder(
                          animation: progressAnimation,
                          builder: (context, child) {
                            return Text(
                              '${(progressAnimation.value * 100).toInt()}%',
                              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
                            );
                          }
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text('Detected so far', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detectedObjects.map((obj) => _buildChip(obj)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _MockSpatialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryPurple.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    final faintPaint = Paint()
      ..color = AppColors.accentIndigo.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Outer wireframe box
    canvas.drawRect(Rect.fromCenter(center: center, width: 30, height: 30), paint);
    canvas.drawLine(Offset(center.dx - 15, center.dy - 15), Offset(center.dx - 5, center.dy - 25), faintPaint);
    canvas.drawLine(Offset(center.dx + 15, center.dy - 15), Offset(center.dx + 25, center.dy - 25), faintPaint);
    canvas.drawLine(Offset(center.dx - 5, center.dy - 25), Offset(center.dx + 25, center.dy - 25), paint);
    
    // Inner floor grid
    for (int i = 0; i < 3; i++) {
      final y = center.dy + (i * 5);
      canvas.drawLine(Offset(center.dx - 15, y), Offset(center.dx + 15, y), faintPaint);
    }
    
    // Glowing nodes (purple and cyan)
    final purpleGlow = Paint()
      ..color = AppColors.secondaryPurple
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
    final cyanGlow = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(Offset(center.dx - 5, center.dy + 5), 2, purpleGlow);
    canvas.drawCircle(Offset(center.dx + 10, center.dy - 5), 1.5, cyanGlow);
    canvas.drawCircle(Offset(center.dx + 20, center.dy - 20), 2, purpleGlow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
