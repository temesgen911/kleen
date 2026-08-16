import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/captured_image.dart';
import '../../models/scanner_session.dart';
import '../../services/camera_service.dart';
import '../../services/image_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'widgets/camera_controls.dart';
import 'widgets/scan_status_card.dart';
import 'widgets/scanner_frame.dart';
import 'widgets/scanner_header.dart';
import 'widgets/step_progress.dart';

class ScannerScreen extends StatefulWidget {
  final ScannerSession? session;

  const ScannerScreen({super.key, this.session});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final CameraService _cameraService;
  late final ScannerSession _session;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? ScannerSession();
    _cameraService = CameraService()..addListener(_onCameraStateChanged);
    WidgetsBinding.instance.addObserver(this);
    _cameraService.initialize();
  }

  void _onCameraStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.removeListener(_onCameraStateChanged);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cameraService.handleAppLifecycleState(state);
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;
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

    setState(() => _isProcessing = true);

    try {
      String sourcePath;

      if (_cameraService.isReady) {
        final xfile = await _cameraService.takePicture();
        if (xfile == null) {
          setState(() => _isProcessing = false);
          return;
        }
        sourcePath = xfile.path;
      } else {
        // Fallback for Simulator without hardware camera: generate a persistent test file
        final roomDir = await ImageStorageService.instance.getRoomDirectory(
          sessionId: _session.sessionId,
          roomId: currentRoom.id,
        );
        final simFile = File(
          '${roomDir.path}/sim_test_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await simFile.writeAsBytes(const [
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
          0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB,
          0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07,
          0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B,
          0x0B, 0x0C, 0x19, 0x12, 0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E,
          0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C,
          0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34,
          0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34,
          0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01,
          0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00, 0x01, 0x05,
          0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
          0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00,
          0x3F, 0x00, 0x7F, 0x00, 0xFF, 0xD9
        ]);
        sourcePath = simFile.path;
      }

      final capturedImage =
          await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: sourcePath,
        sessionId: _session.sessionId,
        roomId: currentRoom.id,
        roomName: currentRoom.name,
        orderIndex: currentRoom.photoCount,
        sourceType: ImageSourceType.camera,
      );

      setState(() {
        currentRoom.addCapturedImage(capturedImage);
      });
    } catch (e) {
      debugPrint('[ScannerScreen] Error during capture: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    final currentRoom = _session.currentRoom;
    if (currentRoom.photoCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondaryPurple,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Maximum 3 photos reached for ${currentRoom.name}.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    try {
      final XFile? picked =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _isProcessing = true);

      final capturedImage =
          await ImageStorageService.instance.persistAndNormalizeImage(
        sourceFilePath: picked.path,
        sessionId: _session.sessionId,
        roomId: currentRoom.id,
        roomName: currentRoom.name,
        orderIndex: currentRoom.photoCount,
        sourceType: ImageSourceType.gallery,
      );

      setState(() {
        currentRoom.addCapturedImage(capturedImage);
      });
    } catch (e) {
      debugPrint('[ScannerScreen] Error picking from gallery: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showTipsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.primaryTeal, size: 22),
                const SizedBox(width: 10),
                Text('Room Scanning Tips', style: AppTypography.heading2),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipRow(
              icon: Icons.wb_sunny_outlined,
              title: 'Good lighting',
              desc:
                  'Turn on room lights or open blinds for high object recognition accuracy.',
            ),
            const SizedBox(height: 12),
            _buildTipRow(
              icon: Icons.crop_rotate,
              title: 'Opposite angles',
              desc:
                  'Take 2–3 photos from opposite room corners to capture all surfaces.',
            ),
            const SizedBox(height: 12),
            _buildTipRow(
              icon: Icons.layers_outlined,
              title: 'Cover all surfaces',
              desc:
                  'Include tables, rugs, counters, shelves, and major electronics.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
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

                // Scanner Frame with Live Camera / Fallback
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: ScannerFrame(
                        cameraController: _cameraService.controller,
                        cameraStatus: _cameraService.status,
                        errorMessage: _cameraService.errorMessage,
                        onRetryPermission: () => _cameraService.initialize(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Controls and Status
                CameraControls(
                  onCapture: _capturePhoto,
                  onGalleryTap: _pickFromGallery,
                  onTipsTap: _showTipsDialog,
                  isCaptureDisabled: currentPhotos >= 3 || _isProcessing,
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
