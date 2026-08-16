import 'package:flutter/material.dart';

/// Utility wrapper that adds a glowing box-shadow behind its child.
/// Refined: tighter blur, optional inner ring.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.blurRadius = 20.0,
    this.spreadRadius = -2.0,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
            offset: offset,
          ),
        ],
      ),
      child: child,
    );
  }
}
