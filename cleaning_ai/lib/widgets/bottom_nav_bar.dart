import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../screens/scan/scanner_screen.dart';
import '../screens/plan/weekly_plan_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int activeIndex;

  const BottomNavBar({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 16,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            // Darker, more opaque nav bg — not washed out
            color: AppColors.backgroundEnd.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(
                color: Color(0x30FFFFFF), // crisp thin top rule
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, 'Home', activeIndex == 0, () {}),
              _buildNavItem(Icons.document_scanner, 'Scan', activeIndex == 1, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerScreen()),
                );
              }),
              _buildNavItem(Icons.assignment, 'Plan', activeIndex == 2, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeeklyPlanScreen(isManagementMode: true),
                  ),
                );
              }),
              _buildNavItem(Icons.person, 'Profile', activeIndex == 3, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? AppColors.primaryTeal : const Color(0x80FFFFFF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active glow dot above icon
          if (active)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.label.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
