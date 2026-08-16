import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Exact mathematical representation and paths for the Cleaning AI logo symbol.
/// Normalized to a 200x200 design grid, automatically scaled and centered to any target Size.
class CleaningLogoGeometry {
  static const double designSize = 200.0;

  // Star center anchor in the 200x200 grid
  static const Offset starCenter = Offset(142.0, 76.0);

  // Starting needle-tip of the crescent
  static const Offset crescentStart = Offset(76.0, 68.0);

  /// Computes the transform matrix / scale to fit and center within [size].
  static double getScale(Size size) {
    return math.min(size.width, size.height) / designSize;
  }

  static Offset getOffset(Size size) {
    final scale = getScale(size);
    final dx = (size.width - designSize * scale) / 2.0;
    final dy = (size.height - designSize * scale) / 2.0;
    return Offset(dx, dy);
  }

  /// Returns the complete filled 4-point star sparkle path.
  /// [scale] can be used to animate the star creation expansion.
  static Path getStarPath(Size size, {double scale = 1.0}) {
    final s = getScale(size);
    final offset = getOffset(size);
    final cx = starCenter.dx;
    final cy = starCenter.dy;

    // Star needle radii
    final topR = 30.0 * scale;
    final botR = 30.0 * scale;
    final rightR = 24.0 * scale;
    final leftR = 24.0 * scale;

    final path = Path();
    if (scale <= 0.001) return path;

    // Top tip
    path.moveTo(cx, cy - topR);

    // Top to Right (concave arc pulling toward center)
    path.cubicTo(
      cx + 0.5 * scale,
      cy - topR * 0.38,
      cx + rightR * 0.46,
      cy - 0.5 * scale,
      cx + rightR,
      cy,
    );

    // Right to Bottom
    path.cubicTo(
      cx + rightR * 0.46,
      cy + 0.5 * scale,
      cx + 0.5 * scale,
      cy + botR * 0.38,
      cx,
      cy + botR,
    );

    // Bottom to Left
    path.cubicTo(
      cx - 0.5 * scale,
      cy + botR * 0.38,
      cx - leftR * 0.46,
      cy + 0.5 * scale,
      cx - leftR,
      cy,
    );

    // Left to Top
    path.cubicTo(
      cx - leftR * 0.46,
      cy - 0.5 * scale,
      cx - 0.5 * scale,
      cy - topR * 0.38,
      cx,
      cy - topR,
    );

    path.close();

    // Scale & translate to target canvas
    final matrix = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0.0, 1.0)
      ..scaleByDouble(s, s, 1.0, 1.0);
    return path.transform(matrix.storage);
  }

  /// Returns the solid filled crescent path matching the reference logo.
  static Path getCrescentPath(Size size) {
    final s = getScale(size);
    final offset = getOffset(size);

    final path = Path();

    // Start at sharp tip
    path.moveTo(76.0, 68.0);

    // Outer curve: sweeping down and left, around bottom, and up to bottom of star
    path.cubicTo(46.0, 84.0, 28.0, 112.0, 34.0, 134.0);
    path.cubicTo(40.0, 154.0, 64.0, 168.0, 88.0, 164.0);
    path.cubicTo(112.0, 160.0, 132.0, 138.0, 142.0, 106.0);

    // Inner curve: returning smoothly from star anchor to sharp tip
    path.cubicTo(126.0, 100.0, 108.0, 142.0, 76.0, 142.0);
    path.cubicTo(56.0, 142.0, 46.0, 124.0, 50.0, 106.0);
    path.cubicTo(54.0, 88.0, 64.0, 74.0, 76.0, 68.0);

    path.close();

    final matrix = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0.0, 1.0)
      ..scaleByDouble(s, s, 1.0, 1.0);
    return path.transform(matrix.storage);
  }

  /// Returns the combined unified logo symbol path (crescent + star).
  static Path getFullLogoPath(Size size) {
    final crescent = getCrescentPath(size);
    final star = getStarPath(size);
    return Path.combine(PathOperation.union, crescent, star);
  }

  /// Centerline spine curve along which the beam of light travels from tip to star center.
  static Path getSpinePath(Size size) {
    final s = getScale(size);
    final offset = getOffset(size);

    final path = Path();
    path.moveTo(76.0, 68.0);
    path.cubicTo(40.0, 96.0, 36.0, 136.0, 64.0, 153.0);
    path.cubicTo(88.0, 166.0, 126.0, 148.0, 142.0, 76.0);

    final matrix = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0.0, 1.0)
      ..scaleByDouble(s, s, 1.0, 1.0);
    return path.transform(matrix.storage);
  }

  /// Get position and angle of light head along the spine curve at normalized [progress] (0.0 to 1.0).
  static PathMetric? getSpineMetric(Size size) {
    final spine = getSpinePath(size);
    final metrics = spine.computeMetrics().toList();
    if (metrics.isEmpty) return null;
    return metrics.first;
  }
}
