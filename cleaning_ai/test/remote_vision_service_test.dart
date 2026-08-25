import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cleaning_ai/models/captured_image.dart';
import 'package:cleaning_ai/models/scanner_session.dart';
import 'package:cleaning_ai/services/remote_vision_analysis_service.dart';
import 'package:cleaning_ai/services/vision_analysis_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteVisionAnalysisService Tests', () {
    test('parses real backend response DTO into DetectedItem objects', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/v1/vision/detect'));
        return http.Response(
          json.encode({
            'status': 'success',
            'roomId': 'room_123',
            'roomName': 'Living Room',
            'model': 'IDEA-Research/grounding-dino-tiny',
            'threshold': 0.35,
            'totalDetections': 2,
            'detections': [
              {
                'id': 'det_sofa_1',
                'name': 'Sofa',
                'label': 'sofa',
                'category': 'furniture',
                'roomName': 'Living Room',
                'confidence': 0.92,
                'sourceImageId': 'img_001',
                'normalizedBoundingBox': [0.10, 0.20, 0.50, 0.40],
                'aiMetadata': {'model': 'IDEA-Research/grounding-dino-tiny'}
              },
              {
                'id': 'det_tv_2',
                'name': 'Television',
                'label': 'television',
                'category': 'electronics',
                'roomName': 'Living Room',
                'confidence': 0.98,
                'sourceImageId': 'img_001',
                'normalizedBoundingBox': [0.35, 0.15, 0.30, 0.25],
                'aiMetadata': {'model': 'IDEA-Research/grounding-dino-tiny'}
              }
            ]
          }),
          200,
        );
      });

      final service = RemoteVisionAnalysisService(
        httpClient: mockClient,
        baseUrl: 'http://localhost:8000',
      );

      final room = RoomData(
        id: 'room_123',
        name: 'Living Room',
        images: [
          CapturedImage(id: 'img_001', filePath: 'test_assets/dummy.jpg', roomName: 'Living Room')
        ],
      );

      final detections = await service.analyzeRoomScan(room);
      expect(detections.length, 2);

      final sofa = detections.firstWhere((d) => d.name == 'Sofa');
      expect(sofa.category, ItemCategory.furniture);
      expect(sofa.confidence, 0.92);
      expect(sofa.sourceImageId, 'img_001');
      expect(sofa.normalizedBoundingBox, [0.10, 0.20, 0.50, 0.40]);

      final tv = detections.firstWhere((d) => d.name == 'Television');
      expect(tv.category, ItemCategory.electronics);
      expect(tv.confidence, 0.98);
    });

    test('falls back gracefully to MockVisionAnalysisService when HTTP error occurs', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = RemoteVisionAnalysisService(
        httpClient: mockClient,
        baseUrl: 'http://localhost:8000',
      );

      final room = RoomData(
        id: 'room_123',
        name: 'Living Room',
        images: [
          CapturedImage(id: 'img_001', filePath: 'test_assets/dummy.jpg', roomName: 'Living Room')
        ],
      );

      final detections = await service.analyzeRoomScan(room);
      expect(detections, isNotEmpty); // Gracefully returned mock items
    });
  });
}
