import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../services/camera_service.dart';

class ScannerFrame extends StatelessWidget {
  final CameraController? cameraController;
  final CameraStatus cameraStatus;
  final String? errorMessage;
  final VoidCallback? onRetryPermission;

  const ScannerFrame({
    super.key,
    this.cameraController,
    this.cameraStatus = CameraStatus.ready,
    this.errorMessage,
    this.onRetryPermission,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReady = cameraStatus == CameraStatus.ready &&
        cameraController != null &&
        cameraController!.value.isInitialized;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.secondaryPurple.withValues(alpha: 0.5),
          width: 1.5,
        ),
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
            // 1. Camera Layer or Fallback / Error Display
            if (isReady)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: cameraController!.value.previewSize?.height ?? 1,
                    height: cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(cameraController!),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundStart.withValues(alpha: 0.8),
                      const Color(0xFF2A2D3E),
                      AppColors.backgroundStart,
                    ],
                  ),
                ),
                child: cameraStatus.hasError
                    ? _buildErrorState(context)
                    : _buildInitializingState(),
              ),

            // 2. Grid Layer
            CustomPaint(
              painter: _GridPainter(
                  color: Colors.white.withValues(alpha: 0.15)),
            ),

            // 3. Corner Brackets
            CustomPaint(
              painter: _BracketsPainter(color: AppColors.secondaryPurple),
            ),

            // 4. Good Lighting Badge
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundStart.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isReady
                              ? Colors.greenAccent
                              : (cameraStatus.hasError
                                  ? Colors.amberAccent
                                  : Colors.cyanAccent),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isReady
                                  ? Colors.greenAccent
                                  : (cameraStatus.hasError
                                      ? Colors.amberAccent
                                      : Colors.cyanAccent),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isReady
                            ? 'Good lighting'
                            : (cameraStatus.hasError
                                ? 'Simulation Mode'
                                : 'Initializing camera...'),
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Floating Instruction Overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GlassCard(
                baseColor: AppColors.glassWhite,
                glowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryPurple
                            .withValues(alpha: 0.15),
                        border: Border.all(
                            color: AppColors.secondaryPurple
                                .withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.share,
                            color: AppColors.secondaryPurple, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start in one corner',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Then move to the opposite side\nand capture another angle.',
                            style:
                                AppTypography.bodySmall.copyWith(height: 1.3),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.view_in_ar,
                        color: AppColors.secondaryPurple
                            .withValues(alpha: 0.4),
                        size: 36),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInitializingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.secondaryPurple),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Starting camera...',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDenied = cameraStatus == CameraStatus.permissionDenied ||
        cameraStatus == CameraStatus.permissionPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDenied ? Icons.no_photography_outlined : Icons.camera_alt_outlined,
              color: Colors.white60,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              isDenied ? 'Camera Access Required' : 'Camera Unavailable',
              style: AppTypography.heading3.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage ??
                  'You can still import photos from your gallery or test on the simulator.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.3),
              textAlign: TextAlign.center,
            ),
            if (isDenied && onRetryPermission != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetryPermission,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry Permission'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    canvas.drawLine(
        Offset(cellWidth, 0), Offset(cellWidth, size.height), paint);
    canvas.drawLine(
        Offset(cellWidth * 2, 0), Offset(cellWidth * 2, size.height), paint);

    canvas.drawLine(
        Offset(0, cellHeight), Offset(size.width, cellHeight), paint);
    canvas.drawLine(
        Offset(0, cellHeight * 2), Offset(size.width, cellHeight * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BracketsPainter extends CustomPainter {
  final Color color;
  _BracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    const double length = 40;
    const double padding = 20;
    const double radius = 12;

    // Top Left
    var path = Path()
      ..moveTo(padding, padding + length)
      ..lineTo(padding, padding + radius)
      ..arcToPoint(Offset(padding + radius, padding),
          radius: const Radius.circular(radius))
      ..lineTo(padding + length, padding);
    canvas.drawPath(path, paint);

    // Top Right
    path = Path()
      ..moveTo(size.width - padding - length, padding)
      ..lineTo(size.width - padding - radius, padding)
      ..arcToPoint(Offset(size.width - padding, padding + radius),
          radius: const Radius.circular(radius))
      ..lineTo(size.width - padding, padding + length);
    canvas.drawPath(path, paint);

    // Bottom Left
    path = Path()
      ..moveTo(padding, size.height - padding - length)
      ..lineTo(padding, size.height - padding - radius)
      ..arcToPoint(Offset(padding + radius, size.height - padding),
          radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(padding + length, size.height - padding);
    canvas.drawPath(path, paint);

    // Bottom Right
    path = Path()
      ..moveTo(size.width - padding - length, size.height - padding)
      ..lineTo(size.width - padding - radius, size.height - padding)
      ..arcToPoint(
          Offset(size.width - padding, size.height - padding - radius),
          radius: const Radius.circular(radius),
          clockwise: false)
      ..lineTo(size.width - padding, size.height - padding - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
