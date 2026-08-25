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
  final ValueChanged<int>? onTabSelected;

  const BottomNavBar({
    super.key,
    this.activeIndex = 0,
    this.authNotifier,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 14,
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
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: activeIndex == 0,
                onTap: () => _handleTap(context, 0),
              ),
              _NavItem(
                icon: Icons.document_scanner_rounded,
                label: 'Scan',
                active: activeIndex == 1,
                onTap: () => _handleTap(context, 1),
              ),
              _NavItem(
                icon: Icons.assignment_rounded,
                label: 'Plan',
                active: activeIndex == 2,
                onTap: () => _handleTap(context, 2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: activeIndex == 3,
                onTap: () => _handleTap(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    if (index == activeIndex) return;

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = HomeScreen(authNotifier: authNotifier);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
          (route) => route.isFirst,
        );
        return;
      case 1:
        targetScreen = const ScannerScreen();
        break;
      case 2:
        targetScreen = const WeeklyPlanScreen(isManagementMode: true);
        break;
      case 3:
        targetScreen = ProfileScreen(authNotifier: authNotifier);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.primaryTeal : const Color(0x80FFFFFF);
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: widget.active ? 6 : 0,
                height: widget.active ? 6 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Icon(
                widget.icon,
                color: color,
                size: widget.active ? 25 : 23,
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: AppTypography.label.copyWith(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
