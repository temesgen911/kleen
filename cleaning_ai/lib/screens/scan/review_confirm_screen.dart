import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/scanner_session.dart';
import 'widgets/review_step_progress.dart';
import 'widgets/ai_scan_complete_card.dart';
import 'widgets/detected_items_card.dart';
import 'widgets/confirm_cta_button.dart';
import 'scanner_screen.dart';
import 'plan_generation_screen.dart';

class ReviewConfirmScreen extends StatefulWidget {
  final ScannerSession session;

  const ReviewConfirmScreen({super.key, required this.session});

  @override
  State<ReviewConfirmScreen> createState() => _ReviewConfirmScreenState();
}

class _ReviewConfirmScreenState extends State<ReviewConfirmScreen> {

  // ── Retake: confirm before discarding session ─────────────────────────────
  void _onRetake() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Retake scan?',
            style: AppTypography.heading3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Retaking will replace this room scan and discard current detections. Continue?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              await widget.session.resetSession();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  (route) => route.isFirst,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retake'),
          ),
        ],
      ),
    );
  }

  // ── Confirm room ──────────────────────────────────────────────────────────
  void _onConfirm() {
    setState(() => widget.session.isConfirmed = true);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlanGenerationScreen(
          session: widget.session,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // ── Background ambient glows ────────────────────────────────────
          Positioned(
            top: -120,
            left: -160,
            child: _ambientGlow(500, AppColors.accentIndigo, 0.12),
          ),
          Positioned(
            bottom: -60,
            right: -100,
            child: _ambientGlow(400, AppColors.accentOrange, 0.08),
          ),
          Positioned(
            top: 250,
            right: -120,
            child: _ambientGlow(300, AppColors.secondaryPurple, 0.10),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Back button
                      _HeaderIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),

                      // Title
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Review & Confirm',
                              style: AppTypography.heading2.copyWith(
                                color: AppColors.textPrimary, fontSize: 18),
                            ),
                            Text(
                              'Step 3 of 3',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Retake button
                      GestureDetector(
                        onTap: _onRetake,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  size: 14,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Retake',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Step progress ──────────────────────────────────────────
                const ReviewStepProgress(),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // AI Scan Complete card
                        AiScanCompleteCard(
                          itemCount: widget.session.totalCount,
                          roomName: widget.session.currentRoom.name,
                          roomCount: widget.session.availableRoomNames.length,
                        ),
                        const SizedBox(height: 14),

                        // Detected Items card
                        DetectedItemsCard(
                          session: widget.session,
                          onSessionChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 24),

                        // CTA
                        ConfirmCtaButton(onConfirm: _onConfirm),
                        const SizedBox(height: 14),

                        // Bottom reassurance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 12,
                                color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              'You can edit or add more items anytime',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientGlow(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0.0),
        ]),
      ),
    );
  }
}

// ─── Small header icon button ─────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
      ),
    );
  }
}
