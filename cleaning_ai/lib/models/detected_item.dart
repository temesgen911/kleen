import 'scanner_session.dart' show ItemCategory;

/// Represents raw physical object detection output produced by a Vision Analysis model.
class DetectedItem {
  final String id;
  final String name;
  final ItemCategory category;
  final String roomName;
  final double confidence;
  final String? sourceImageId;
  final String? material;
  final String? cleanableSurface;
  final List<double>? normalizedBoundingBox; // [left, top, width, height]
  final Map<String, dynamic> aiMetadata;

  DetectedItem({
    String? id,
    required this.name,
    required this.category,
    this.roomName = 'Living Room',
    this.confidence = 0.95,
    this.sourceImageId,
    this.material,
    this.cleanableSurface,
    this.normalizedBoundingBox,
    this.aiMetadata = const {},
  }) : id = id ??
            'det_${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}';

  DetectedItem copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    String? roomName,
    double? confidence,
    String? sourceImageId,
    String? material,
    String? cleanableSurface,
    List<double>? normalizedBoundingBox,
    Map<String, dynamic>? aiMetadata,
  }) {
    return DetectedItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      roomName: roomName ?? this.roomName,
      confidence: confidence ?? this.confidence,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      material: material ?? this.material,
      cleanableSurface: cleanableSurface ?? this.cleanableSurface,
      normalizedBoundingBox:
          normalizedBoundingBox ?? this.normalizedBoundingBox,
      aiMetadata: aiMetadata ?? this.aiMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'roomName': roomName,
      'confidence': confidence,
      'sourceImageId': sourceImageId,
      'material': material,
      'cleanableSurface': cleanableSurface,
      'normalizedBoundingBox': normalizedBoundingBox,
      'aiMetadata': aiMetadata,
    };
  }

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ItemCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ItemCategory.other,
      ),
      roomName: json['roomName'] as String? ?? 'Living Room',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
      sourceImageId: json['sourceImageId'] as String?,
      material: json['material'] as String?,
      cleanableSurface: json['cleanableSurface'] as String?,
      normalizedBoundingBox: (json['normalizedBoundingBox'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      aiMetadata: (json['aiMetadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
