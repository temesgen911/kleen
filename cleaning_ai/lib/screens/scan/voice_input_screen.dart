import 'package:flutter/material.dart';
import '../../models/scanner_session.dart';
import '../../services/voice_task_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'review_confirm_screen.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isProcessing = false;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto start listening on arrival
    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    VoiceTaskService.instance.stopListening();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);

    await VoiceTaskService.instance.startListening(
      onResult: (text) {
        setState(() {
          _transcript = text;
        });
      },
      onListeningStateChanged: (listening) {
        if (!mounted) return;
        setState(() {
          _isListening = listening;
        });
        if (!listening) {
          _pulseController.stop();
          _pulseController.value = 1.0;
        }
      },
    );
  }

  Future<void> _stopAndParse() async {
    await VoiceTaskService.instance.stopListening();
    _pulseController.stop();
    _pulseController.value = 1.0;

    if (_transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.categoryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('No speech recognized yet. Please tap the mic and speak clearly.'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _isListening = false;
    });

    final parsedItems = await VoiceTaskService.instance.parseSpeechToTasks(_transcript);

    if (!mounted) return;

    final session = ScannerSession();
    session.reviewItems.clear();
    session.reviewItems.addAll(parsedItems);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewConfirmScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Voice Cleaning Setup', style: AppTypography.heading2.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Tell AI Everything To Clean',
                style: AppTypography.heading1.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Speak out loud about rooms, furniture, and how often they need cleaning. AI will structure it into a plan.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Animated Pulsing Mic Button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        VoiceTaskService.instance.stopListening();
                        setState(() => _isListening = false);
                        _pulseController.stop();
                      } else {
                        _startRecording();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isListening ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isListening
                                    ? [AppColors.secondaryPurple, AppColors.categoryOrange]
                                    : [AppColors.primaryTeal, AppColors.secondaryPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? AppColors.secondaryPurple : AppColors.primaryTeal)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Real-time Transcript Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 180),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isListening
                        ? AppColors.primaryTeal.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _transcript.isEmpty
                        ? (_isListening ? 'Listening... Speak now!' : 'Tap mic to start speaking...')
                        : _transcript,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _transcript.isEmpty ? AppColors.textSecondary : Colors.white,
                      fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _stopAndParse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: AppColors.backgroundStart,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 4,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: AppColors.backgroundStart, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Generate Plan from Voice',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
