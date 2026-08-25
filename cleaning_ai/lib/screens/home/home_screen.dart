import 'package:flutter/material.dart';
import '../../services/auth_state_notifier.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'widgets/header_section.dart';
import 'widgets/next_scan_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/todays_plan_card.dart';

class HomeScreen extends StatelessWidget {
  final AuthStateNotifier? authNotifier;
  final bool showBottomNav;

  const HomeScreen({
    super.key,
    this.authNotifier,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildBody(BuildContext context) {
      final user = authNotifier?.currentUser;
      final displayName = user?.effectiveDisplayName ?? 'User';
      final photoUrl = user?.photoUrl;

      return Scaffold(
        extendBody: true,
        backgroundColor: AppColors.backgroundStart,
        bottomNavigationBar: showBottomNav ? BottomNavBar(authNotifier: authNotifier) : null,
        body: Stack(
          children: [
            // Deep background base
            Container(color: AppColors.backgroundStart),
            
            // Huge ambient radial glow - Teal (Top Right)
            Positioned(
              top: -100,
              right: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryTeal.withValues(alpha: 0.08),
                      AppColors.primaryTeal.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            // Huge ambient radial glow - Purple (Middle Left)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: -200,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryPurple.withValues(alpha: 0.06),
                      AppColors.secondaryPurple.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Huge ambient radial glow - Indigo (Bottom Center)
            Positioned(
              bottom: -100,
              left: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: 400,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentIndigo.withValues(alpha: 0.08),
                      AppColors.accentIndigo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16, 
                right: 16, 
                top: MediaQuery.of(context).padding.top + 16,
                bottom: MediaQuery.of(context).padding.bottom + 120, // Accounts for nav bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderSection(
                    displayName: displayName,
                    photoUrl: photoUrl,
                  ),
                  const SizedBox(height: 24),
                  const TodaysPlanCard(),
                  const SizedBox(height: 16),
                  const NextScanCard(),
                  const SizedBox(height: 16),
                  const StreakCard(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (authNotifier != null) {
      return ListenableBuilder(
        listenable: authNotifier!,
        builder: (context, _) => buildBody(context),
      );
    }

    return buildBody(context);
  }
}
