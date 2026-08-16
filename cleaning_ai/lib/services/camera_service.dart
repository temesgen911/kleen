import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Represents current camera initialization or error state.
enum CameraStatus {
  uninitialized,
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
  error;

  bool get isReady => this == CameraStatus.ready;
  bool get hasError =>
      this == CameraStatus.permissionDenied ||
      this == CameraStatus.permissionPermanentlyDenied ||
      this == CameraStatus.unavailable ||
      this == CameraStatus.error;
}

/// Service encapsulating device camera lifecycle, rear-camera resolution tuning, and capture execution.
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  CameraStatus _status = CameraStatus.uninitialized;
  String? _errorMessage;

  CameraController? get controller => _controller;
  CameraStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == CameraStatus.ready && _controller != null && _controller!.value.isInitialized;

  /// Initializes the device's rear camera with a balanced 1080p (high) resolution preset for vision analysis.
  Future<CameraStatus> initialize() async {
    _status = CameraStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _status = CameraStatus.unavailable;
        _errorMessage = 'No camera hardware found on this device.';
        notifyListeners();
        return _status;
      }

      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // ResolutionPreset.high gives 1920x1080 (1080p), providing rich detail for furniture & surfaces
      // while avoiding gigabyte-sized files and inference memory bottlenecks.
      final newController = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await newController.initialize();

      // Ensure exposure mode is continuous for optimal indoor room lighting
      try {
        await newController.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      _controller = newController;
      _status = CameraStatus.ready;
      notifyListeners();
      return _status;
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
        _status = CameraStatus.permissionDenied;
        _errorMessage = 'Camera access was denied. Please grant camera permission to scan rooms.';
      } else if (e.code == 'CameraAccessRestricted') {
        _status = CameraStatus.permissionPermanentlyDenied;
        _errorMessage = 'Camera access is restricted. Please enable camera in device settings.';
      } else {
        _status = CameraStatus.error;
        _errorMessage = 'Camera error: ${e.description ?? e.code}';
      }
      debugPrint('[CameraService] CameraException: $e');
      notifyListeners();
      return _status;
    } catch (e) {
      _status = CameraStatus.error;
      _errorMessage = 'Unexpected camera error: $e';
      debugPrint('[CameraService] Initialization error: $e');
      notifyListeners();
      return _status;
    }
  }

  /// Captures a photo using the active camera controller.
  Future<XFile?> takePicture() async {
    if (!isReady || _controller == null) {
      debugPrint('[CameraService] Cannot capture photo: camera is not ready.');
      return null;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      return photo;
    } catch (e) {
      debugPrint('[CameraService] Failed to take picture: $e');
      return null;
    }
  }

  /// Handles AppLifecycleState transitions to release camera resources in background and re-acquire on resume.
  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    final CameraController? current = _controller;
    if (current == null || !current.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      await _controller?.dispose();
      _controller = null;
      _status = CameraStatus.uninitialized;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      await initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
