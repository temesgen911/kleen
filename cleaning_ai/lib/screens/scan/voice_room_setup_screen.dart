import 'package:flutter/material.dart';
import '../../models/scanner_session.dart';
import '../../services/voice_task_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'review_confirm_screen.dart';

class VoiceRoomSetupScreen extends StatefulWidget {
  const VoiceRoomSetupScreen({super.key});

  @override
  State<VoiceRoomSetupScreen> createState() => _VoiceRoomSetupScreenState();
}

class _VoiceRoomSetupScreenState extends State<VoiceRoomSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isProcessing = false;
  String _currentLiveTranscript = '';
  final List<RoomVoiceBubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
      _currentLiveTranscript = '';
    });
    _pulseController.repeat(reverse: true);

    await VoiceTaskService.instance.startListening(
      onResult: (text) {
        setState(() {
          _currentLiveTranscript = text;
        });
      },
      onListeningStateChanged: (listening) {
        if (!mounted) return;
        if (!listening && _isListening) {
          _finishRoomRecording();
        }
      },
    );
  }

  Future<void> _stopRecordingManual() async {
    await VoiceTaskService.instance.stopListening();
    _finishRoomRecording();
  }

  void _finishRoomRecording() {
    _pulseController.stop();
    _pulseController.value = 1.0;

    final text = _currentLiveTranscript.trim();
    if (text.isNotEmpty) {
      final roomIndex = _bubbles.length + 1;
      String inferredRoomTitle = 'Room $roomIndex';
      final lower = text.toLowerCase();
      if (lower.contains('bedroom')) inferredRoomTitle = 'Bedroom';
      if (lower.contains('living')) inferredRoomTitle = 'Living Room';
      if (lower.contains('kitchen')) inferredRoomTitle = 'Kitchen';
      if (lower.contains('bathroom')) inferredRoomTitle = 'Bathroom';
      if (lower.contains('dining')) inferredRoomTitle = 'Dining Room';

      setState(() {
        _bubbles.add(
          RoomVoiceBubble(
            roomTitle: inferredRoomTitle,
            transcript: text,
          ),
        );
        _currentLiveTranscript = '';
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = false;
        _currentLiveTranscript = '';
      });
    }
  }

  void _deleteBubble(int index) {
    setState(() {
      _bubbles.removeAt(index);
    });
  }

  void _editBubbleTranscript(int index) {
    final bubble = _bubbles[index];
    final controller = TextEditingController(text: bubble.transcript);
    final roomController = TextEditingController(text: bubble.roomTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2234),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Room Recording', style: AppTypography.heading3.copyWith(fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Room Name',
                labelStyle: const TextStyle(color: AppColors.primaryTeal),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryTeal)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Transcript Text',
                labelStyle: const TextStyle(color: AppColors.primaryTeal),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryTeal)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _bubbles[index] = bubble.copyWith(
                  roomTitle: roomController.text.trim().isEmpty ? 'Room ${index + 1}' : roomController.text.trim(),
                  transcript: controller.text.trim(),
                );
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.backgroundStart,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAllAndGeneratePlan() async {
    if (_bubbles.isEmpty && _currentLiveTranscript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.categoryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Please speak at least one room description before continuing.'),
        ),
      );
      return;
    }

    // If currently listening, capture live text first
    if (_isListening && _currentLiveTranscript.isNotEmpty) {
      _finishRoomRecording();
    }

    setState(() {
      _isProcessing = true;
    });

    final parsedItems = await VoiceTaskService.instance.parseMultiRoomTranscripts(_bubbles);

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
        title: Text('Voice Room Setup', style: AppTypography.heading2.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_bubbles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.categoryOrange),
              tooltip: 'Clear All Rooms',
              onPressed: () {
                setState(() {
                  _bubbles.clear();
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subtitle & Status Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
              child: Column(
                children: [
                  Text(
                    'Walk Room to Room & Speak',
                    style: AppTypography.heading1.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hold/Tap mic for each room. Speak items you see (e.g. king bed, glass window, TV, rug). Let go when done, then tap Continue!',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Room Pill Counter Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.meeting_room,
                          size: 16,
                          color: _bubbles.isNotEmpty ? AppColors.primaryTeal : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _bubbles.isEmpty
                              ? 'No rooms recorded yet'
                              : '${_bubbles.length} ${_bubbles.length == 1 ? 'Room' : 'Rooms'} Recorded',
                          style: AppTypography.label.copyWith(
                            color: _bubbles.isNotEmpty ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Giant Central Microphone Button
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_isListening) {
                    _stopRecordingManual();
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
                        width: 130,
                        height: 130,
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
                                  .withValues(alpha: 0.45),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 54,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isListening ? 'STOP' : 'TAP MIC',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Live Transcript Box (While Recording)
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondaryPurple, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: AppColors.secondaryPurple, strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentLiveTranscript.isEmpty ? 'Listening... Speak room items now!' : _currentLiveTranscript,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontStyle: _currentLiveTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Recorded Room Voice Bubbles List (ChatGPT Voice Typing Box Style)
            Expanded(
              child: _bubbles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.record_voice_over_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text(
                              'Tap the giant mic above to record your first room!',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _bubbles.length,
                      itemBuilder: (context, index) {
                        final bubble = _bubbles[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primaryTeal.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Room Title & Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.meeting_room_rounded, size: 16, color: AppColors.primaryTeal),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        bubble.roomTitle,
                                        style: AppTypography.heading3.copyWith(fontSize: 15, color: AppColors.primaryTeal),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                                        onPressed: () => _editBubbleTranscript(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        onPressed: () => _deleteBubble(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // ChatGPT-style Transcript Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.graphic_eq, size: 18, color: AppColors.secondaryPurple),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        bubble.transcript,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: Colors.white,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom CTA "Continue & Process Rooms"
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_bubbles.isEmpty && _currentLiveTranscript.isEmpty) || _isProcessing
                      ? null
                      : _submitAllAndGeneratePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: AppColors.backgroundStart,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    elevation: 6,
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: AppColors.backgroundStart, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text('AI Generating Tasks & Schedules...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(
                          _bubbles.isEmpty
                              ? 'Continue'
                              : 'Continue & Process ${_bubbles.length} ${_bubbles.length == 1 ? 'Room' : 'Rooms'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
