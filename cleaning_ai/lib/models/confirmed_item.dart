import 'detected_item.dart';
import 'scanner_session.dart' show ItemCategory;

/// Tracks provenance of how an item was entered into the cleaning registry.
enum ItemProvenance {
  aiDetected,
  userAdded,
  userModified;

  String get displayName {
    switch (this) {
      case ItemProvenance.aiDetected:
        return 'AI Detected';
      case ItemProvenance.userAdded:
        return 'Manually Added';
      case ItemProvenance.userModified:
        return 'User Modified';
    }
  }
}

/// Represents a physical cleanable item confirmed by the user in a specific room.
class ConfirmedItem {
  final String id;
  final String name;
  final String roomName;
  final ItemCategory category;
  final ItemProvenance provenance;
  final double confidence;
  final bool isConfirmed;
  final String? sourceImageId;
  final String? detectedItemId;
  final String? material;
  final String? notes;

  ConfirmedItem({
    String? id,
    required this.name,
    this.roomName = 'Living Room',
    required this.category,
    this.provenance = ItemProvenance.aiDetected,
    this.confidence = 0.95,
    this.isConfirmed = true,
    this.sourceImageId,
    this.detectedItemId,
    this.material,
    this.notes,
  }) : id = id ??
            'item_${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}';

  factory ConfirmedItem.fromDetectedItem(
    DetectedItem detected, {
    bool isConfirmed = true,
  }) {
    return ConfirmedItem(
      id: 'conf_${detected.id}',
      name: detected.name,
      roomName: detected.roomName,
      category: detected.category,
      provenance: ItemProvenance.aiDetected,
      confidence: detected.confidence,
      isConfirmed: isConfirmed,
      sourceImageId: detected.sourceImageId,
      detectedItemId: detected.id,
      material: detected.material,
    );
  }

  factory ConfirmedItem.userCreated({
    required String name,
    required String roomName,
    required ItemCategory category,
  }) {
    return ConfirmedItem(
      name: name,
      roomName: roomName,
      category: category,
      provenance: ItemProvenance.userAdded,
      confidence: 1.0,
      isConfirmed: true,
    );
  }

  ConfirmedItem copyWith({
    String? id,
    String? name,
    String? roomName,
    ItemCategory? category,
    ItemProvenance? provenance,
    double? confidence,
    bool? isConfirmed,
    String? sourceImageId,
    String? detectedItemId,
    String? material,
    String? notes,
  }) {
    return ConfirmedItem(
      id: id ?? this.id,
      name: name ?? this.name,
      roomName: roomName ?? this.roomName,
      category: category ?? this.category,
      provenance: provenance ?? this.provenance,
      confidence: confidence ?? this.confidence,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      detectedItemId: detectedItemId ?? this.detectedItemId,
      material: material ?? this.material,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roomName': roomName,
      'category': category.name,
      'provenance': provenance.name,
      'confidence': confidence,
      'isConfirmed': isConfirmed,
      'sourceImageId': sourceImageId,
      'detectedItemId': detectedItemId,
      'material': material,
      'notes': notes,
    };
  }

  factory ConfirmedItem.fromJson(Map<String, dynamic> json) {
    return ConfirmedItem(
      id: json['id'] as String,
      name: json['name'] as String,
      roomName: json['roomName'] as String? ?? 'Living Room',
      category: ItemCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ItemCategory.other,
      ),
      provenance: ItemProvenance.values.firstWhere(
        (p) => p.name == json['provenance'],
        orElse: () => ItemProvenance.aiDetected,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isConfirmed: json['isConfirmed'] as bool? ?? true,
      sourceImageId: json['sourceImageId'] as String?,
      detectedItemId: json['detectedItemId'] as String?,
      material: json['material'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
