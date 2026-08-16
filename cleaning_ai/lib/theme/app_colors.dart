import 'package:flutter/material.dart';

class AppColors {
  // ─── Backgrounds ───────────────────────────────────────────────────────────
  // Near-black for maximum contrast against luminous edges
  static const Color backgroundStart = Color(0xFF060810);
  static const Color backgroundEnd   = Color(0xFF030406);
  static const Color surfaceDark     = Color(0xFF0A0D16); // card interior tint

  // ─── Primary Accents ───────────────────────────────────────────────────────
  static const Color primaryTeal      = Color(0xFF1BFFE0);
  static const Color secondaryPurple  = Color(0xFFB180FF);
  static const Color accentIndigo     = Color(0xFF4A4E9E);

  // ─── Warm Accents ─────────────────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentCoral  = Color(0xFFFF6B7A);
  static const Color accentGold   = Color(0xFFFFB84C);

  // ─── Category Accents ─────────────────────────────────────────────────────
  static const Color categoryBlue   = Color(0xFF5AB4FF);
  static const Color categoryPurple = Color(0xFFB180FF);
  static const Color categoryOrange = Color(0xFFFF8C42);
  static const Color categoryGold   = Color(0xFFFFB84C);

  // ─── Glass Surfaces ───────────────────────────────────────────────────────
  // Dark glass — opaque enough to read against, not washed-out
  static const Color glassWhite  = Color(0x0DFFFFFF); // 5%
  static const Color glassTeal   = Color(0x141BFFE0); // 8%
  static const Color glassPurple = Color(0x14B180FF); // 8%

  // ─── Borders — Sharp Edge Lines ───────────────────────────────────────────
  // Higher alpha = crisper edge shine
  static const Color borderWhite  = Color(0x40FFFFFF); // 25%
  static const Color borderTeal   = Color(0x661BFFE0); // 40%
  static const Color borderPurple = Color(0x66B180FF); // 40%

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xB3F0F4F8); // 70%
  static const Color textMuted     = Color(0x73F0F4F8); // 45%
  static const Color textTeal      = Color(0xFF1BFFE0);
}
