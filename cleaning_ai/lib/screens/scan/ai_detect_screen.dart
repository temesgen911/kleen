import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/scanner_session.dart';
import 'widgets/scanner_header.dart';
import 'widgets/step_progress.dart';
import 'widgets/ai_detect_frame.dart';
import 'widgets/processing_card.dart';
import 'review_confirm_screen.dart';

class AIDetectScreen extends StatefulWidget {
  final String imagePath;
  final List<XFile> capturedPhotos;
  final ScannerSession? session;

  const AIDetectScreen({
    super.key,
    this.imagePath = '',
    this.capturedPhotos = const [],
    this.session,
  });

  @override
  State<AIDetectScreen> createState() => _AIDetectScreenState();
}

class _AIDetectScreenState extends State<AIDetectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late final ScannerSession _session;
  bool _analysisComplete = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? ScannerSession();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _analysisComplete = true);
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _proceedToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewConfirmScreen(session: _session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstPhoto = widget.imagePath.isNotEmpty
        ? widget.imagePath
        : (_session.allCapturedPhotos.isNotEmpty
            ? _session.allCapturedPhotos.first.path
            : '');

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // Background Glows
          Container(color: AppColors.backgroundStart),
          Positioned(
            top: -100,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentIndigo.withValues(alpha: 0.15),
                    AppColors.accentIndigo.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryPurple.withValues(alpha: 0.15),
                    AppColors.secondaryPurple.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const ScannerHeader(),
                const StepProgress(currentStep: 2),

                // Instructions Text
                Text(
                  'AI is detecting objects across rooms ✨',
                  style: AppTypography.heading2.copyWith(fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  'Identifying surfaces, furniture, and cleaning priorities.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // AI Detect Frame
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: AIDetectFrame(
                        imagePath: firstPhoto,
                        session: _session,
                        progressAnimation: _progressController,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Show Processing card during analysis, Review button when done
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _analysisComplete
                      ? _buildProceedButton()
                      : ProcessingCard(
                          progressAnimation: _progressController),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: _proceedToReview,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
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
                blurRadius: 16,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Review Multi-Room Detections',
                      style: AppTypography.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
