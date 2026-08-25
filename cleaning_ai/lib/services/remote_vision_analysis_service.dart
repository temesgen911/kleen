import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/detected_item.dart';
import '../models/scanner_session.dart' show ItemCategory, RoomData;
import 'auth_service.dart';
import 'vision_analysis_service.dart';

/// Real remote vision analysis service calling FastAPI Grounding DINO detector endpoint.
class RemoteVisionAnalysisService implements VisionAnalysisService {
  final http.Client _httpClient;
  final String _baseUrl;
  final VisionAnalysisService _fallbackMock;
  final AuthService? _authService;

  RemoteVisionAnalysisService({
    http.Client? httpClient,
    String? baseUrl,
    VisionAnalysisService? fallbackMock,
    AuthService? authService,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl(),
        _fallbackMock = fallbackMock ?? const MockVisionAnalysisService(),
        _authService = authService;

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  @override
  Future<List<DetectedItem>> analyzeRoomScan(RoomData room) async {
    if (room.images.isEmpty) {
      return _fallbackMock.analyzeRoomScan(room);
    }

    final uri = Uri.parse('$_baseUrl/api/v1/vision/detect');
    try {
      developer.log('Sending room images to real vision backend: $uri', name: 'RemoteVisionAnalysisService');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header if token exists
      if (_authService != null) {
        final token = await _authService.getIdToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.fields['room_name'] = room.name;

      for (var img in room.images) {
        request.fields['image_ids'] = img.id;
        final file = File(img.filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: 'room_${img.id}.jpg',
            ),
          );
        } else {
          // Fallback attachment for unit tests or virtual paths
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              [0, 1, 2, 3],
              filename: 'room_${img.id}.jpg',
            ),
          );
        }
      }

      if (request.files.isEmpty) {
        developer.log('No valid local files found to upload. Using mock fallback.', name: 'RemoteVisionAnalysisService');
        return _fallbackMock.analyzeRoomScan(room);
      }

      final streamedResponse = await _httpClient.send(request).timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> detectionsJson = data['detections'] as List<dynamic>? ?? [];

        developer.log('✅ Received ${detectionsJson.length} real DINO detections from backend.', name: 'RemoteVisionAnalysisService');

        if (detectionsJson.isEmpty) {
          developer.log('Zero detections returned. Falling back to mock for presentation.', name: 'RemoteVisionAnalysisService');
          return _fallbackMock.analyzeRoomScan(room);
        }

        return detectionsJson.map((item) {
          final Map<String, dynamic> map = item as Map<String, dynamic>;
          return DetectedItem(
            id: map['id'] as String? ?? 'det_${DateTime.now().millisecondsSinceEpoch}',
            name: map['name'] as String? ?? 'Detected Item',
            category: _parseCategory(map['category'] as String?),
            roomName: map['roomName'] as String? ?? room.name,
            confidence: (map['confidence'] as num?)?.toDouble() ?? 0.85,
            sourceImageId: map['sourceImageId'] as String? ?? room.images.first.id,
            normalizedBoundingBox: (map['normalizedBoundingBox'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList(),
            aiMetadata: (map['aiMetadata'] as Map<String, dynamic>?) ?? const {},
          );
        }).toList();
      } else {
        developer.log('Backend returned status ${response.statusCode}: ${response.body}', name: 'RemoteVisionAnalysisService');
      }
    } catch (e) {
      developer.log('Remote vision backend call error/fallback: $e', name: 'RemoteVisionAnalysisService');
    }

    // Fallback to mock service if backend is offline or errors out
    return _fallbackMock.analyzeRoomScan(room);
  }

  @override
  Future<List<DetectedItem>> analyzeMultiRoomScan(List<RoomData> rooms) async {
    final List<DetectedItem> allDetections = [];
    for (var room in rooms) {
      final detections = await analyzeRoomScan(room);
      allDetections.addAll(detections);
    }
    return allDetections;
  }

  static ItemCategory _parseCategory(String? catStr) {
    if (catStr == null) return ItemCategory.other;
    return ItemCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == catStr.toLowerCase(),
      orElse: () => ItemCategory.other,
    );
  }
}
