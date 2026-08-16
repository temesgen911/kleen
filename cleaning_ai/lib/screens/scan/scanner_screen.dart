import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/scanner_session.dart';
import 'widgets/scanner_header.dart';
import 'widgets/step_progress.dart';
import 'widgets/scanner_frame.dart';
import 'widgets/camera_controls.dart';
import 'widgets/scan_status_card.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final ScannerSession _session = ScannerSession();
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _capturePhoto() async {
    final currentRoom = _session.currentRoom;
    if (currentRoom.photoCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondaryPurple,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Maximum 3 photos reached for ${currentRoom.name}. Tap Next Room or Add Room!',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Fallback for iOS Simulator where no camera is available
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint("Camera not initialized. Simulating capture for testing...");
      setState(() {
        currentRoom.photos.add(XFile('')); // Dummy file for simulator testing
      });
      return;
    }

    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      debugPrint("Photo captured for ${currentRoom.name}: ${photo.path}");

      setState(() {
        currentRoom.photos.add(photo);
      });
    } catch (e) {
      debugPrint("Failed to capture photo: $e");
      setState(() {
        currentRoom.photos.add(XFile(''));
      });
    }
  }

  void _onNextRoom() {
    if (_session.currentRoomIndex < _session.rooms.length - 1) {
      setState(() {
        _session.currentRoomIndex++;
      });
    }
  }

  void _showAddRoomDialog() {
    final presetRooms = [
      ('Bathroom', Icons.bathtub),
      ('Dining Room', Icons.restaurant_menu),
      ('Home Office', Icons.computer),
      ('Hallway', Icons.door_front_door),
      ('Balcony', Icons.balcony),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Another Room', style: AppTypography.heading2),
            const SizedBox(height: 6),
            Text(
              'Select a room to scan next',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: presetRooms.map((preset) {
                final exists =
                    _session.rooms.any((r) => r.name == preset.$1);
                return ActionChip(
                  avatar: Icon(preset.$2,
                      size: 16,
                      color: exists
                          ? AppColors.textMuted
                          : AppColors.secondaryPurple),
                  label: Text(preset.$1),
                  backgroundColor: exists
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.secondaryPurple.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: exists
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.secondaryPurple.withValues(alpha: 0.4),
                  ),
                  labelStyle: TextStyle(
                    color: exists
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: exists
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          setState(() {
                            _session.addRoom(preset.$1, preset.$2);
                            _session.currentRoomIndex =
                                _session.rooms.length - 1;
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = _session.currentRoom;
    final currentPhotos = currentRoom.photoCount;

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
                const StepProgress(currentStep: 1),

                // Room Selector Pill Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ...List.generate(_session.rooms.length, (idx) {
                        final room = _session.rooms[idx];
                        final isSelected = _session.currentRoomIndex == idx;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _session.currentRoomIndex = idx;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondaryPurple
                                        .withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondaryPurple
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.secondaryPurple
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(room.icon,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    room.name,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.secondaryPurple
                                          : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${room.photoCount}/3',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      // Add Room Button
                      GestureDetector(
                        onTap: _showAddRoomDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Add Room',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Instructions Text
                Text(
                  'Scanning ${currentRoom.name}',
                  style: AppTypography.heading2.copyWith(fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'Capture 2–3 photos from different angles',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Scanner Frame
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: ScannerFrame(
                        cameraController: _isCameraInitialized
                            ? _cameraController
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Controls and Status
                CameraControls(
                  onCapture: _capturePhoto,
                  captureProgress: (currentPhotos / 3.0).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 8),
                ScanStatusCard(
                  session: _session,
                  onNextRoom: _onNextRoom,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
