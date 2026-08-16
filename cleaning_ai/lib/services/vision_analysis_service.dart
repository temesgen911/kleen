import '../models/detected_item.dart';
import '../models/scanner_session.dart' show ItemCategory, RoomData;

/// Contract for visual detection and scene analysis of captured room imagery.
abstract class VisionAnalysisService {
  Future<List<DetectedItem>> analyzeRoomScan(RoomData room);
  Future<List<DetectedItem>> analyzeMultiRoomScan(List<RoomData> rooms);
}

/// Mock implementation providing curated, multi-room vision detections.
class MockVisionAnalysisService implements VisionAnalysisService {
  const MockVisionAnalysisService();

  @override
  Future<List<DetectedItem>> analyzeRoomScan(RoomData room) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final roomName = room.name;
    return _mockDetections.where((d) => d.roomName == roomName).toList();
  }

  @override
  Future<List<DetectedItem>> analyzeMultiRoomScan(List<RoomData> rooms) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final roomNames = rooms.map((r) => r.name).toSet();
    final results = _mockDetections
        .where((d) => roomNames.contains(d.roomName))
        .toList();
    return results.isNotEmpty ? results : _mockDetections;
  }

  static final List<DetectedItem> _mockDetections = [
    DetectedItem(
      id: 'det_hardwood_floor',
      name: 'Hardwood Floor',
      roomName: 'Living Room',
      category: ItemCategory.surfaces,
      confidence: 0.98,
      material: 'Oak Wood',
      cleanableSurface: 'Floor',
      normalizedBoundingBox: [0.05, 0.60, 0.90, 0.35],
    ),
    DetectedItem(
      id: 'det_coffee_table',
      name: 'Coffee Table',
      roomName: 'Living Room',
      category: ItemCategory.furniture,
      confidence: 0.95,
      material: 'Walnut / Glass',
      cleanableSurface: 'Tabletop',
      normalizedBoundingBox: [0.25, 0.45, 0.40, 0.25],
    ),
    DetectedItem(
      id: 'det_tv_stand',
      name: 'TV Stand',
      roomName: 'Living Room',
      category: ItemCategory.furniture,
      confidence: 0.92,
      material: 'Wood',
      cleanableSurface: 'Shelves & Top',
      normalizedBoundingBox: [0.30, 0.25, 0.40, 0.30],
    ),
    DetectedItem(
      id: 'det_sofa',
      name: 'Sofa',
      roomName: 'Living Room',
      category: ItemCategory.furniture,
      confidence: 0.96,
      material: 'Fabric / Linen',
      cleanableSurface: 'Upholstery',
      normalizedBoundingBox: [0.10, 0.35, 0.50, 0.40],
    ),
    DetectedItem(
      id: 'det_television',
      name: 'Television',
      roomName: 'Living Room',
      category: ItemCategory.electronics,
      confidence: 0.99,
      material: 'OLED Glass Screen',
      cleanableSurface: 'Display & Bezel',
      normalizedBoundingBox: [0.35, 0.15, 0.30, 0.25],
    ),
    DetectedItem(
      id: 'det_area_rug',
      name: 'Area Rug',
      roomName: 'Bedroom',
      category: ItemCategory.surfaces,
      confidence: 0.94,
      material: 'Wool Blend',
      cleanableSurface: 'Textile Surface',
      normalizedBoundingBox: [0.20, 0.55, 0.60, 0.35],
    ),
    DetectedItem(
      id: 'det_windowsill',
      name: 'Windowsill',
      roomName: 'Bedroom',
      category: ItemCategory.surfaces,
      confidence: 0.91,
      material: 'Painted Wood',
      cleanableSurface: 'Ledge',
      normalizedBoundingBox: [0.70, 0.20, 0.25, 0.40],
    ),
    DetectedItem(
      id: 'det_countertop',
      name: 'Countertop',
      roomName: 'Kitchen',
      category: ItemCategory.surfaces,
      confidence: 0.97,
      material: 'Quartz / Stone',
      cleanableSurface: 'Counter Surface',
      normalizedBoundingBox: [0.05, 0.40, 0.85, 0.30],
    ),
    DetectedItem(
      id: 'det_house_plant',
      name: 'House Plant',
      roomName: 'Living Room',
      category: ItemCategory.other,
      confidence: 0.89,
      material: 'Foliage / Ceramic Pot',
      cleanableSurface: 'Leaves & Base',
      normalizedBoundingBox: [0.80, 0.30, 0.15, 0.45],
    ),
  ];
}
