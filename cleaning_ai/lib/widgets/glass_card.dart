import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Premium glassmorphism card with sharp luminous edges and deep dark fills.
///
/// Design principles:
/// • Dark fill — cards are DARKER than the background, not lighter / washed out
/// • Thin specular top-edge — a bright but narrow highlight at the very top
/// • 1px luminous border — crisp edge visibility, not a wide glow
/// • Minimal backdrop blur — just enough frosting to feel glassy, not fuzzy
/// • Optional colored outer glow — halo effect for emphasis
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Color baseColor;
  final Color glowColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = AppConstants.cardPadding,
    this.baseColor = AppColors.glassWhite,
    this.glowColor = Colors.transparent,
    this.borderRadius = AppConstants.radiusLg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Colored halo glow (optional, when glowColor is provided)
          if (glowColor != Colors.transparent)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.20),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          // Subtle dark shadow for depth separation
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          // Reduced blur for less fuzziness — glass feel without the fog
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Dark, opaque glass fill — deeper than background, not washed-out
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withValues(alpha: 0.10),
                  AppColors.surfaceDark.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              // Sharp 1px luminous border — the "edge shine"
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // ── Specular top-edge highlight ──────────────────────────
                // Narrow bright line along the top — mimics reflected light
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        topRight: Radius.circular(borderRadius),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.1, 0.5, 0.9],
                      ),
                    ),
                  ),
                ),
                // ── Subtle corner glint ──────────────────────────────────
                // Tiny top-left specular patch
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                      ),
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          splashColor: Colors.white.withValues(alpha: 0.06),
          child: card,
        ),
      );
    }

    return card;
  }
}
