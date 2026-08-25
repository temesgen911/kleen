import 'package:flutter/material.dart';
import '../services/auth_state_notifier.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'plan/weekly_plan_screen.dart';
import 'profile/profile_screen.dart';
import 'scan/scanner_screen.dart';

/// Luxury Main Navigation Container managing directional tab sliding transitions
/// and persistent AuthStateNotifier across all main app screens.
class MainNavigationScreen extends StatefulWidget {
  final AuthStateNotifier? authNotifier;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.authNotifier,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _previousIndex = widget.initialIndex;
  }

  void _onTabSelected(int newIndex) {
    if (newIndex == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(authNotifier: widget.authNotifier, showBottomNav: false);
      case 1:
        return const ScannerScreen();
      case 2:
        return const WeeklyPlanScreen(isManagementMode: true);
      case 3:
        return ProfileScreen(authNotifier: widget.authNotifier, showBottomNav: false);
      default:
        return HomeScreen(authNotifier: widget.authNotifier, showBottomNav: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMovingRight = _currentIndex > _previousIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isNewChild = child.key == ValueKey<int>(_currentIndex);
          
          final double beginOffset = isNewChild
              ? (isMovingRight ? 1.0 : -1.0)
              : (isMovingRight ? -1.0 : 1.0);

          final slideAnimation = Tween<Offset>(
            begin: Offset(beginOffset, 0.0),
            end: Offset.zero,
          ).animate(animation);

          final fadeAnimation = Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(animation);

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _buildScreen(_currentIndex),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        activeIndex: _currentIndex,
        authNotifier: widget.authNotifier,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
