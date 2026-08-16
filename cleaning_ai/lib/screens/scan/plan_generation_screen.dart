import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/scanner_session.dart';
import '../../theme/app_typography.dart';
import '../plan/weekly_plan_screen.dart';
import 'widgets/plan_item_card.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _cardW = PlanItemCard.cardW;
const _cardH = PlanItemCard.cardH;

// Connector pair sets — different relationships shown at different stages
const List<(int, int)> _connSetA = [
  (0, 2), // Hardwood Floor ↔ Area Rug       (surfaces)
  (3, 4), // Coffee Table ↔ TV Stand         (furniture)
  (6, 4), // Television ↔ TV Stand           (electronics-furniture)
];
const List<(int, int)> _connSetB = [
  (2, 5), // Area Rug ↔ Sofa                 (floor/furniture)
  (0, 1), // Hardwood Floor ↔ Windowsill     (surfaces)
  (3, 5), // Coffee Table ↔ Sofa             (furniture)
];
const List<(int, int)> _connSetC = [
  (0, 2), (1, 7), (3, 6), (4, 5), // mixed cross-relationships
];

// ─── Plan Generation Screen ───────────────────────────────────────────────────

class PlanGenerationScreen extends StatefulWidget {
  final ScannerSession session;

  const PlanGenerationScreen({super.key, required this.session});

  @override
  State<PlanGenerationScreen> createState() => _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends State<PlanGenerationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;

  bool _isComplete = false;

  static const List<String> _phrases = [
    'Evaluating detected items',
    'Grouping similar tasks',
    'Comparing cleaning priorities',
    'Balancing effort distribution',
    'Checking cleaning frequency',
    'Optimising today\'s workload',
    'Testing different sequences',
    'Reducing unnecessary repetition',
    'Considering material types',
    'Building your best-fit plan',
  ];
  int _phraseIdx = 0;
  bool _phraseVisible = false;

  List<ReviewItem> get _items =>
      widget.session.reviewItems.where((i) => i.isConfirmed).toList();

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _isComplete = true);
        }
      });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _cyclePhrases();
  }

  Future<void> _cyclePhrases() async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (var i = 0; i < _phrases.length; i++) {
      if (!mounted) return;
      setState(() {
        _phraseIdx = i;
        _phraseVisible = true;
      });
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() => _phraseVisible = false);
      await Future.delayed(const Duration(milliseconds: 220));
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  // ── 10-stage position choreography ─────────────────────────────────────────
  //
  // Items: 0=Hardwood Floor  1=Windowsill  2=Area Rug  3=Coffee Table
  //        4=TV Stand        5=Sofa        6=Television  7=House Plant

  // Stage 0: spawn — all stacked at centre
  static const _spawn = [
    Offset(0.50, 0.48), Offset(0.50, 0.48), Offset(0.50, 0.48), Offset(0.50, 0.48),
    Offset(0.50, 0.48), Offset(0.50, 0.48), Offset(0.50, 0.48), Offset(0.50, 0.48),
  ];

  // Stage 1: scattered float — organic spread
  static const _scatter = [
    Offset(0.18, 0.12), Offset(0.75, 0.08), Offset(0.12, 0.38),
    Offset(0.82, 0.34), Offset(0.20, 0.62), Offset(0.78, 0.58),
    Offset(0.15, 0.85), Offset(0.80, 0.82),
  ];

  // Stage 2: group by CATEGORY — surfaces top-left, furniture top-right
  static const _catGroup = [
    Offset(0.22, 0.15), Offset(0.22, 0.28), Offset(0.22, 0.41), // Surfaces
    Offset(0.72, 0.15), Offset(0.72, 0.28), Offset(0.72, 0.41), // Furniture
    Offset(0.47, 0.68), Offset(0.47, 0.82),                      // Elec + Other
  ];

  // Stage 3: cross-shuffle — items swap across categories
  static const _crossShuffle = [
    Offset(0.70, 0.40), Offset(0.50, 0.10), Offset(0.78, 0.14),
    Offset(0.18, 0.36), Offset(0.50, 0.55), Offset(0.22, 0.70),
    Offset(0.78, 0.70), Offset(0.50, 0.86),
  ];

  // Stage 4: single row — testing linear arrangement
  static const _singleRow = [
    Offset(0.14, 0.44), Offset(0.27, 0.44), Offset(0.40, 0.44), Offset(0.53, 0.44),
    Offset(0.66, 0.44), Offset(0.79, 0.44), Offset(0.36, 0.58), Offset(0.62, 0.58),
  ];

  // Stage 5: priority reorder — items rearrange in estimated priority
  static const _priorityOrder = [
    Offset(0.50, 0.10), Offset(0.28, 0.28), Offset(0.72, 0.28),
    Offset(0.28, 0.46), Offset(0.72, 0.46), Offset(0.28, 0.64),
    Offset(0.72, 0.64), Offset(0.50, 0.82),
  ];

  // Stage 6: tight centre cluster — everything pulls inward
  static const _tightCenter = [
    Offset(0.38, 0.30), Offset(0.62, 0.30), Offset(0.38, 0.44),
    Offset(0.62, 0.44), Offset(0.38, 0.58), Offset(0.62, 0.58),
    Offset(0.38, 0.72), Offset(0.62, 0.72),
  ];

  // Stage 7: ring spread — items form a circle
  static List<Offset> get _ring {
    const count = 8;
    const cx = 0.50;
    const cy = 0.48;
    const rx = 0.30;
    const ry = 0.30;
    return List.generate(count, (i) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / count);
      return Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
    });
  }

  // Stage 8: two-column attempt — surfaces left, everything else right
  static const _twoColA = [
    Offset(0.27, 0.12), Offset(0.27, 0.28), Offset(0.27, 0.44),
    Offset(0.73, 0.12), Offset(0.73, 0.28), Offset(0.73, 0.44),
    Offset(0.73, 0.60), Offset(0.27, 0.60),
  ];

  // Stage 9: frequency regroup — items near same frequency cluster together
  static const _freqGroup = [
    Offset(0.50, 0.10), Offset(0.72, 0.50), Offset(0.28, 0.10),
    Offset(0.28, 0.38), Offset(0.72, 0.10), Offset(0.72, 0.36),
    Offset(0.50, 0.38), Offset(0.50, 0.64),
  ];

  // Stage 10: final optimised grid — settled arrangement
  static const _finalGrid = [
    Offset(0.27, 0.10), Offset(0.73, 0.10),
    Offset(0.27, 0.28), Offset(0.73, 0.28),
    Offset(0.27, 0.46), Offset(0.73, 0.46),
    Offset(0.27, 0.64), Offset(0.73, 0.64),
  ];

  // ── Keyframe timeline ──────────────────────────────────────────────────────

  List<(double, Offset)> _keyframes(int idx) {
    Offset at(List<Offset> layout) =>
        idx < layout.length ? layout[idx] : Offset(0.5, 0.5 + idx * 0.09);

    return [
      // Intake
      (0.000, at(_spawn)),
      (0.015, at(_spawn)),
      (0.070, at(_scatter)),

      // Category grouping
      (0.120, at(_scatter)),
      (0.180, at(_catGroup)),
      (0.220, at(_catGroup)),

      // Cross-shuffle
      (0.280, at(_crossShuffle)),
      (0.320, at(_crossShuffle)),

      // Linear row test
      (0.370, at(_singleRow)),
      (0.400, at(_singleRow)),

      // Priority reorder
      (0.450, at(_priorityOrder)),
      (0.490, at(_priorityOrder)),

      // Tight centre pull
      (0.530, at(_tightCenter)),
      (0.555, at(_tightCenter)),

      // Ring spread
      (0.600, at(_ring)),
      (0.640, at(_ring)),

      // Two-column attempt
      (0.695, at(_twoColA)),
      (0.730, at(_twoColA)),

      // Frequency regroup
      (0.780, at(_freqGroup)),
      (0.820, at(_freqGroup)),

      // Final settle
      (0.880, at(_finalGrid)),
      (1.000, at(_finalGrid)),
    ];
  }

  Offset _interpPos(int idx, double t) {
    final kfs = _keyframes(idx);
    for (var i = 0; i < kfs.length - 1; i++) {
      final (t0, p0) = kfs[i];
      final (t1, p1) = kfs[i + 1];
      if (t >= t0 && t < t1) {
        final local = Curves.easeInOutCubic.transform((t - t0) / (t1 - t0));
        return Offset.lerp(p0, p1, local)!;
      }
    }
    return kfs.last.$2;
  }

  double _cardScale(int idx, double t) {
    final delay = idx * 0.007;
    final appear = ((t - 0.01 - delay) / 0.06).clamp(0.0, 1.0);
    return Curves.elasticOut.transform(appear).clamp(0.0, 1.0);
  }

  double _cardOpacity(int idx, double t) {
    final delay = idx * 0.007;
    return ((t - 0.01 - delay) / 0.05).clamp(0.0, 1.0);
  }

  // ── Connector set selection based on time ──────────────────────────────────

  List<(int, int)> _activeConnectors(double t) {
    if (t >= 0.14 && t < 0.24) return _connSetA;
    if (t >= 0.44 && t < 0.56) return _connSetB;
    if (t >= 0.62 && t < 0.72) return _connSetC;
    return const [];
  }

  double _connectorOpacity(double t) {
    if (t >= 0.14 && t < 0.17) return (t - 0.14) / 0.03;
    if (t >= 0.17 && t < 0.21) return 1.0;
    if (t >= 0.21 && t < 0.24) return 1.0 - (t - 0.21) / 0.03;
    if (t >= 0.44 && t < 0.47) return (t - 0.44) / 0.03;
    if (t >= 0.47 && t < 0.53) return 1.0;
    if (t >= 0.53 && t < 0.56) return 1.0 - (t - 0.53) / 0.03;
    if (t >= 0.62 && t < 0.65) return (t - 0.62) / 0.03;
    if (t >= 0.65 && t < 0.69) return 1.0;
    if (t >= 0.69 && t < 0.72) return 1.0 - (t - 0.69) / 0.03;
    return 0.0;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulseCtrl, _rotateCtrl]),
                      builder: (context, child) => CustomPaint(
                        painter: _BackgroundPainter(
                          pulse: _pulseCtrl.value,
                          rotation: _rotateCtrl.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final canvas = Size(constraints.maxWidth, constraints.maxHeight);
                      return AnimatedBuilder(
                        animation: _mainCtrl,
                        builder: (context, child) {
                          final t = _mainCtrl.value;
                          final items = _items;

                          final centres = List.generate(items.length, (i) {
                            final norm = _interpPos(i, t);
                            return Offset(
                              canvas.width * norm.dx,
                              canvas.height * norm.dy,
                            );
                          });

                          final connectors = _activeConnectors(t);
                          final connAlpha = _connectorOpacity(t);

                          return Stack(
                            children: [
                              if (connectors.isNotEmpty && connAlpha > 0)
                                RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _ConnectorPainter(
                                      opacity: connAlpha,
                                      centres: centres,
                                      itemCount: items.length,
                                      pairs: connectors,
                                    ),
                                    size: canvas,
                                  ),
                                ),
                              ...List.generate(items.length, (i) {
                                final centre = centres[i];
                                final scale = _cardScale(i, t);
                                final opacity = _cardOpacity(i, t);
                                return Positioned(
                                  left: centre.dx - _cardW / 2,
                                  top: centre.dy - _cardH / 2,
                                  child: Opacity(
                                    opacity: opacity.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: PlanItemCard(item: items[i]),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _isComplete ? 'Your cleaning plan is ready ✨' : 'Generating Your Plan',
              key: ValueKey(_isComplete),
              style: AppTypography.heading1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _phraseVisible && !_isComplete ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              _phrases[_phraseIdx],
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryPurple,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return AnimatedOpacity(
      opacity: _isComplete ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 700),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: GestureDetector(
          onTap: () {
            if (!_isComplete) return;
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    WeeklyPlanScreen(session: widget.session),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: const LinearGradient(
                colors: [AppColors.secondaryPurple, AppColors.accentIndigo],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.40),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Specular top highlight line
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.60),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'View Cleaning Plan',
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Background Painter ────────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  final double pulse;
  final double rotation;

  _BackgroundPainter({required this.pulse, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Dot grid
    final dotPaint = Paint()
      ..color = AppColors.accentIndigo.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    // Radial pulses
    for (var p = 0; p < 2; p++) {
      final phase = (pulse + p * 0.5) % 1.0;
      final radius = phase * size.longestSide * 0.65;
      final opacity = (1.0 - phase) * 0.08;
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = AppColors.secondaryPurple.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Rotating analysis ring
    final ringR = size.shortestSide * 0.38;
    canvas.drawCircle(
      Offset(cx, cy), ringR,
      Paint()
        ..color = AppColors.accentIndigo.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Dashes
    final dashPaint = Paint()
      ..color = AppColors.secondaryPurple.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = rotation * 2 * math.pi + i * (2 * math.pi / 8);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: ringR),
        angle, 0.12, false, dashPaint,
      );
    }

    // Glowing nodes
    final nodePaint = Paint()
      ..color = AppColors.secondaryPurple
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 4; i++) {
      final angle = rotation * 2 * math.pi + i * math.pi / 2;
      canvas.drawCircle(
        Offset(cx + ringR * math.cos(angle), cy + ringR * math.sin(angle)),
        2.5, nodePaint,
      );
    }

    // Light sweep
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: ringR * 1.5),
      rotation * 2 * math.pi, 0.4, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.025)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringR * 1.5,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.pulse != pulse || old.rotation != rotation;
}

// ─── Connector Lines Painter ──────────────────────────────────────────────────

class _ConnectorPainter extends CustomPainter {
  final double opacity;
  final List<Offset> centres;
  final int itemCount;
  final List<(int, int)> pairs;

  _ConnectorPainter({
    required this.opacity,
    required this.centres,
    required this.itemCount,
    required this.pairs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || centres.isEmpty) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.secondaryPurple.withValues(alpha: opacity * 0.50);

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.secondaryPurple.withValues(alpha: opacity * 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final (a, b) in pairs) {
      if (a >= itemCount || b >= itemCount) continue;
      canvas.drawLine(centres[a], centres[b], linePaint);
      canvas.drawCircle(centres[a], 3.0, nodePaint);
      canvas.drawCircle(centres[b], 3.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.opacity != opacity || old.centres != centres || old.pairs != pairs;
}
