import 'package:camera/camera.dart';

/// Represents a photo captured during a room scanning session with full metadata.
class CapturedImage {
  final String id;
  final String filePath;
  final DateTime capturedAt;
  final String roomName;
  final int orderIndex;
  final double? width;
  final double? height;
  final String? thumbnailPath;
  final String? cloudReference;

  CapturedImage({
    String? id,
    required this.filePath,
    DateTime? capturedAt,
    this.roomName = 'Living Room',
    this.orderIndex = 0,
    this.width,
    this.height,
    this.thumbnailPath,
    this.cloudReference,
  })  : id = id ?? 'img_${DateTime.now().millisecondsSinceEpoch}_$orderIndex',
        capturedAt = capturedAt ?? DateTime.now();

  factory CapturedImage.fromXFile(
    XFile file, {
    String roomName = 'Living Room',
    int orderIndex = 0,
  }) {
    return CapturedImage(
      id: 'img_${DateTime.now().microsecondsSinceEpoch}_$orderIndex',
      filePath: file.path,
      roomName: roomName,
      orderIndex: orderIndex,
      capturedAt: DateTime.now(),
    );
  }

  XFile toXFile() => XFile(filePath);

  CapturedImage copyWith({
    String? id,
    String? filePath,
    DateTime? capturedAt,
    String? roomName,
    int? orderIndex,
    double? width,
    double? height,
    String? thumbnailPath,
    String? cloudReference,
  }) {
    return CapturedImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      capturedAt: capturedAt ?? this.capturedAt,
      roomName: roomName ?? this.roomName,
      orderIndex: orderIndex ?? this.orderIndex,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      cloudReference: cloudReference ?? this.cloudReference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'capturedAt': capturedAt.toIso8601String(),
      'roomName': roomName,
      'orderIndex': orderIndex,
      'width': width,
      'height': height,
      'thumbnailPath': thumbnailPath,
      'cloudReference': cloudReference,
    };
  }

  factory CapturedImage.fromJson(Map<String, dynamic> json) {
    return CapturedImage(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      roomName: json['roomName'] as String? ?? 'Living Room',
      orderIndex: json['orderIndex'] as int? ?? 0,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      thumbnailPath: json['thumbnailPath'] as String?,
      cloudReference: json['cloudReference'] as String?,
    );
  }
}
