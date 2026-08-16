import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      primaryColor: AppColors.primaryTeal,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryTeal,
        secondary: AppColors.secondaryPurple,
        surface: AppColors.backgroundStart,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.greeting,
        displayMedium: AppTypography.heading1,
        displaySmall: AppTypography.heading2,
        headlineMedium: AppTypography.heading3,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelSmall: AppTypography.label,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
    );
  }
}
