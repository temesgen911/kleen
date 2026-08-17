import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/plan/weekly_plan_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/scan/scanner_screen.dart';
import '../services/auth_state_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final AuthStateNotifier? authNotifier;

  const BottomNavBar({
    super.key,
    this.activeIndex = 0,
    this.authNotifier,
  });

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
            color: AppColors.backgroundEnd.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(
                color: Color(0x30FFFFFF),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, 'Home', activeIndex == 0, () {
                if (activeIndex != 0) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen(authNotifier: authNotifier)),
                    (route) => route.isFirst,
                  );
                }
              }),
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
              _buildNavItem(Icons.person, 'Profile', activeIndex == 3, () {
                if (activeIndex != 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(authNotifier: authNotifier),
                    ),
                  );
                }
              }),
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
