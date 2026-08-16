import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/scanner_session.dart';
import 'analysis_glass_card.dart';

class MockDetection {
  final String roomName;
  final String label;
  final IconData icon;
  final Offset anchor; // Normalized coordinates (0 to 1)
  final double revealAtProgress; // When to reveal this detection (0.0 to 1.0)

  const MockDetection({
    required this.roomName,
    required this.label,
    required this.icon,
    required this.anchor,
    required this.revealAtProgress,
  });
}

const List<MockDetection> _mockDetections = [
  MockDetection(
      roomName: 'Living Room',
      label: 'Sofa',
      icon: Icons.chair,
      anchor: Offset(0.25, 0.58),
      revealAtProgress: 0.1),
  MockDetection(
      roomName: 'Living Room',
      label: 'Coffee table',
      icon: Icons.table_restaurant,
      anchor: Offset(0.52, 0.68),
      revealAtProgress: 0.28),
  MockDetection(
      roomName: 'Bedroom',
      label: 'Area rug',
      icon: Icons.grid_on,
      anchor: Offset(0.78, 0.78),
      revealAtProgress: 0.48),
  MockDetection(
      roomName: 'Living Room',
      label: 'TV stand',
      icon: Icons.tv,
      anchor: Offset(0.8, 0.35),
      revealAtProgress: 0.68),
  MockDetection(
      roomName: 'Bedroom',
      label: 'Windowsill',
      icon: Icons.window,
      anchor: Offset(0.3, 0.25),
      revealAtProgress: 0.84),
  MockDetection(
      roomName: 'Kitchen',
      label: 'Countertop',
      icon: Icons.countertops,
      anchor: Offset(0.55, 0.44),
      revealAtProgress: 0.93),
];

class AIDetectFrame extends StatefulWidget {
  final String imagePath;
  final ScannerSession? session;
  final Animation<double> progressAnimation;

  const AIDetectFrame({
    super.key,
    required this.imagePath,
    this.session,
    required this.progressAnimation,
  });

  @override
  State<AIDetectFrame> createState() => _AIDetectFrameState();
}

class _AIDetectFrameState extends State<AIDetectFrame> {
  List<String> _detectedObjects = [];

  @override
  void initState() {
    super.initState();
    widget.progressAnimation.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    widget.progressAnimation.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    final currentProgress = widget.progressAnimation.value;
    final currentlyDetected = _mockDetections
        .where((d) => currentProgress >= d.revealAtProgress)
        .map((d) => '${d.roomName}: ${d.label}')
        .toList();

    if (currentlyDetected.length != _detectedObjects.length) {
      setState(() {
        _detectedObjects = currentlyDetected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final String currentRoomDisplay = session != null && session.rooms.isNotEmpty
        ? session.rooms.first.name
        : 'Living Room';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.secondaryPurple.withValues(alpha: 0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPurple.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Captured Image Background
            Positioned.fill(
              child: widget.imagePath.isNotEmpty
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: Image.file(File(widget.imagePath)),
                    )
                  : FittedBox(
                      fit: BoxFit.cover,
                      child: Image.network(
                        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(color: AppColors.backgroundStart);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: AppColors.backgroundStart),
                      ),
                    ),
            ),

            // Active Room Pill in Top Left
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.backgroundStart.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          AppColors.secondaryPurple.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_in_ar,
                        size: 13, color: AppColors.primaryTeal),
                    const SizedBox(width: 5),
                    Text(
                      currentRoomDisplay,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Detection Lines / Glows Overlay
            Positioned.fill(
              child: AnimatedBuilder(
                animation: widget.progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DetectionPainter(
                      progress: widget.progressAnimation.value,
                      detections: _mockDetections,
                    ),
                  );
                },
              ),
            ),

            // 3. Floating Label Chips with Room Tag
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: _mockDetections.map((detection) {
                      final dx = constraints.maxWidth * detection.anchor.dx;
                      final dy = constraints.maxHeight * detection.anchor.dy;

                      return Positioned(
                        left: (dx - 55).clamp(8.0, constraints.maxWidth - 130),
                        top: (dy - 44).clamp(8.0, constraints.maxHeight - 80),
                        child: AnimatedBuilder(
                          animation: widget.progressAnimation,
                          builder: (context, child) {
                            final isVisible = widget.progressAnimation.value >=
                                detection.revealAtProgress;
                            return AnimatedOpacity(
                              opacity: isVisible ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: _DetectionLabel(
                                roomName: detection.roomName,
                                label: detection.label,
                                icon: detection.icon,
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // 4. Analysis Glass Card Overlay
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: AnalysisGlassCard(
                progressAnimation: widget.progressAnimation,
                detectedObjects: _detectedObjects,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionLabel extends StatelessWidget {
  final String roomName;
  final String label;
  final IconData icon;

  const _DetectionLabel({
    required this.roomName,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundStart.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.secondaryPurple.withValues(alpha: 0.6),
            width: 1.0),
        boxShadow: [
          BoxShadow(
              color: AppColors.secondaryPurple.withValues(alpha: 0.35),
              blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.secondaryPurple.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: AppColors.secondaryPurple),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                roomName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primaryTeal,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final double progress;
  final List<MockDetection> detections;

  _DetectionPainter({required this.progress, required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.secondaryPurple.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.secondaryPurple.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppColors.secondaryPurple
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (var detection in detections) {
      if (progress >= detection.revealAtProgress) {
        final cx = size.width * detection.anchor.dx;
        final cy = size.height * detection.anchor.dy;

        // Bounding box size based on label for mock variety
        final boxWidth = size.width * 0.25;
        final boxHeight = size.height * 0.15;
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: boxWidth, height: boxHeight);
        final rrect =
            RRect.fromRectAndRadius(rect, const Radius.circular(12));

        // Draw fill and border
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, linePaint);

        // Draw the glowing anchor point
        canvas.drawCircle(Offset(cx, cy), 4, glowPaint);

        // Draw a vertical connecting line to where the label sits
        canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 40), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
