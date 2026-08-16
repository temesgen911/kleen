import 'package:flutter/material.dart';

class AppConstants {
  // Padding & Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const EdgeInsets defaultPadding = EdgeInsets.all(spacingLg);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingLg);

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  static final BorderRadius defaultBorderRadius = BorderRadius.circular(radiusMd);
  static final BorderRadius cardBorderRadius = BorderRadius.circular(radiusLg);
  static final BorderRadius pillBorderRadius = BorderRadius.circular(100.0);
}
