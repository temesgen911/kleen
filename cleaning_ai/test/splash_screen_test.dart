import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleaning_ai/main.dart';
import 'package:cleaning_ai/screens/splash/splash_screen.dart';
import 'package:cleaning_ai/screens/splash/cleaning_logo_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cleaning AI Logo Geometry Tests', () {
    test('Paths generate correctly for non-empty size', () {
      const testSize = Size(200, 200);
      final star = CleaningLogoGeometry.getStarPath(testSize);
      final crescent = CleaningLogoGeometry.getCrescentPath(testSize);
      final fullLogo = CleaningLogoGeometry.getFullLogoPath(testSize);
      final spine = CleaningLogoGeometry.getSpinePath(testSize);
      final metric = CleaningLogoGeometry.getSpineMetric(testSize);

      expect(star.getBounds().isEmpty, isFalse);
      expect(crescent.getBounds().isEmpty, isFalse);
      expect(fullLogo.getBounds().isEmpty, isFalse);
      expect(spine.getBounds().isEmpty, isFalse);
      expect(metric, isNotNull);
      expect(metric!.length, greaterThan(50.0));
    });
  });

  group('Splash Screen Animation & Flow Tests', () {
    testWidgets('SplashScreen renders and transitions to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const KleenAIApp());

      // Should initially display SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance through animation phases:
      // Phase 1: Dark arrival (0.5s)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Phase 2: Draw the curve (1.5s)
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Phase 3: Create the sparkle (2.2s)
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Phase 4: Settle & breathe (2.8s)
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Phase 5: Transition into AuthGate (3.2s)
      await tester.pump(const Duration(milliseconds: 1000));
      // Route push transition (450ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Should now be on AuthGate
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
