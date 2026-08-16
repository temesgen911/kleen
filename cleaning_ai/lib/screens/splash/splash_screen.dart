import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'cleaning_logo_painter.dart';

/// Premium animated startup splash screen for Cleaning AI.
///
/// Sequence:
/// • 0.0–0.25s: Dark arrival with subtle ambient violet depth.
/// • 0.25–1.05s: Progressive curve drawing via intelligent beam of light with bloom & trail.
/// • 1.05–1.45s: 4-point sparkle creation with diamond glint flash & shockwave ring.
/// • 1.45–1.80s: Fully settled logo with subtle breathing pulse & ambient cyan halo.
/// • 1.80–2.20s: Continuous seamless dissolve into the main application.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase Animations
  late final Animation<double> _ambientFade;
  late final Animation<double> _curveProgress;
  late final Animation<double> _sparkleProgress;
  late final Animation<double> _sparkleFlashIn;
  late final Animation<double> _sparkleFlashOut;
  late final Animation<double> _shockwaveProgress;
  late final Animation<double> _breathPulse;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // ── Phase 1: 0.0–0.45s (0.00 – 0.15) Dark Arrival ─────────────────────────
    _ambientFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.15, curve: Curves.easeIn),
    );

    // ── Phase 2: 0.40–1.65s (0.12 – 0.52) Draw The Curve ──────────────────────
    _curveProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.52, curve: Curves.easeInOutCubic),
    );

    // ── Phase 3: 1.60–2.20s (0.50 – 0.68) Create The Sparkle ──────────────────
    _sparkleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.68, curve: Curves.easeOutBack),
    );

    _sparkleFlashIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.58, curve: Curves.easeInQuad),
    );

    _sparkleFlashOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.70, curve: Curves.easeOutQuad),
    );

    _shockwaveProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.70, curve: Curves.easeOutCubic),
    );

    // ── Phase 4: 2.18–2.82s (0.68 – 0.88) Logo Settles & Breathes ─────────────
    _breathPulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.025)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.025, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.88),
      ),
    );

    // ── Phase 5: 2.82–3.20s (0.88 – 1.00) Transition into App ─────────────────
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.00, curve: Curves.easeInOutCubic),
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.00, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNavigated && mounted) {
        _hasNavigated = true;
        _navigateToHome();
      }
    });

    _controller.forward();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final symbolSize = Size.square(screenSize.shortestSide * 0.58);

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Compute flash glint intensity from in/out curves
          double flashIntensity = 0.0;
          if (_controller.value >= 0.50 && _controller.value < 0.56) {
            flashIntensity = _sparkleFlashIn.value;
          } else if (_controller.value >= 0.56 && _controller.value <= 0.68) {
            flashIntensity = 1.0 - _sparkleFlashOut.value;
          }

          final curveVal = _curveProgress.value;
          final sparkleVal = _sparkleProgress.value;
          final shockwaveVal = _shockwaveProgress.value;
          final ambientVal = _ambientFade.value;
          final breathVal = _breathPulse.value;
          final logoOpac = _exitFade.value;
          final scaleVal = _exitScale.value;

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.backgroundStart,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Ambient Background Layer
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: CleaningLogoPainter(
                        curveProgress: curveVal,
                        sparkleProgress: sparkleVal,
                        sparkleFlash: flashIntensity,
                        shockwaveProgress: shockwaveVal,
                        ambientGlowAlpha: ambientVal,
                        breathScale: breathVal,
                        logoOpacity: logoOpac,
                        globalScale: scaleVal,
                      ),
                      size: screenSize,
                    ),
                  ),
                ),

                // 2. Focused Center Symbol Layer
                Center(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: symbolSize,
                      painter: CleaningLogoPainter(
                        curveProgress: curveVal,
                        sparkleProgress: sparkleVal,
                        sparkleFlash: flashIntensity,
                        shockwaveProgress: shockwaveVal,
                        ambientGlowAlpha: ambientVal,
                        breathScale: breathVal,
                        logoOpacity: logoOpac,
                        globalScale: scaleVal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
