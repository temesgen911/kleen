import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'captured_image.dart';
import 'confirmed_item.dart';
import 'cleaning_requirement.dart';
import '../services/image_storage_service.dart';

// ─── Room Data ───────────────────────────────────────────────────────────────

class RoomData {
  final String id;
  final String name;
  final IconData icon;
  final List<CapturedImage> images;

  RoomData({
    String? id,
    required this.name,
    this.icon = Icons.chair,
    List<CapturedImage>? images,
    List<XFile>? photos,
  })  : id = id ??
            'room_${name.toLowerCase().replaceAll(' ', '_')}',
        images = images ??
            (photos?.map((f) => CapturedImage.fromXFile(f, roomName: name)).toList() ??
                []);

  List<XFile> get photos => images.map((img) => img.toXFile()).toList();

  int get photoCount => images.length;
  bool get hasSufficientPhotos => images.length >= 2;

  void addPhoto(XFile file) {
    images.add(CapturedImage.fromXFile(
      file,
      roomName: name,
      orderIndex: images.length,
    ));
  }

  void addCapturedImage(CapturedImage image) {
    images.add(image);
  }

  Future<bool> removeImage(CapturedImage image) async {
    final removed = images.remove(image);
    if (removed) {
      await ImageStorageService.instance.deleteImage(image);
    }
    return removed;
  }

  Future<CapturedImage?> removeImageById(String imageId) async {
    final index = images.indexWhere((img) => img.id == imageId);
    if (index != -1) {
      final img = images.removeAt(index);
      await ImageStorageService.instance.deleteImage(img);
      return img;
    }
    return null;
  }

  Future<void> clearPhotos() async {
    for (final img in List<CapturedImage>.from(images)) {
      await ImageStorageService.instance.deleteImage(img);
    }
    images.clear();
  }
}

// ─── Item Category ────────────────────────────────────────────────────────────

enum ItemCategory {
  surfaces,
  furniture,
  electronics,
  other;

  String get displayName {
    switch (this) {
      case ItemCategory.surfaces:
        return 'Surfaces';
      case ItemCategory.furniture:
        return 'Furniture';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.other:
        return 'Other';
    }
  }
}

// ─── Review Item (Backwards-compatible UI bridge & ConfirmedItem view) ─────────

class ReviewItem {
  final String id;
  final String name;
  final String roomName;
  final ItemCategory category;
  final String cleaningAction;
  final String frequency;
  bool isConfirmed;
  bool isManuallyAdded;

  ReviewItem({
    String? id,
    required this.name,
    this.roomName = 'Living Room',
    required this.category,
    required this.cleaningAction,
    required this.frequency,
    this.isConfirmed = true,
    this.isManuallyAdded = false,
  }) : id = id ??
            '${name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

  factory ReviewItem.fromConfirmedItem(
    ConfirmedItem confirmed, {
    String cleaningAction = 'Wipe',
    String frequency = 'Every 7 days',
  }) {
    return ReviewItem(
      id: confirmed.id,
      name: confirmed.name,
      roomName: confirmed.roomName,
      category: confirmed.category,
      cleaningAction: cleaningAction,
      frequency: frequency,
      isConfirmed: confirmed.isConfirmed,
      isManuallyAdded: confirmed.provenance == ItemProvenance.userAdded,
    );
  }

  ConfirmedItem toConfirmedItem() {
    return ConfirmedItem(
      id: id,
      name: name,
      roomName: roomName,
      category: category,
      provenance: isManuallyAdded
          ? ItemProvenance.userAdded
          : ItemProvenance.aiDetected,
      isConfirmed: isConfirmed,
    );
  }

  CleaningRequirement toCleaningRequirement() {
    int days = 7;
    if (frequency.contains('2')) days = 2;
    if (frequency.contains('4')) days = 4;
    if (frequency.contains('14')) days = 14;

    int mins = 2;
    if (cleaningAction.contains('Vacuum / Mop')) {
      mins = 6;
    } else if (cleaningAction.contains('Vacuum')) {
      mins = 4;
    } else if (cleaningAction.contains('Wipe')) {
      mins = 3;
    }

    return CleaningRequirement(
      itemId: id,
      action: cleaningAction,
      frequencyDays: days,
      estimatedMinutes: mins,
    );
  }

  ReviewItem copyWith({
    String? name,
    String? roomName,
    ItemCategory? category,
    String? cleaningAction,
    String? frequency,
    bool? isConfirmed,
    bool? isManuallyAdded,
  }) {
    return ReviewItem(
      id: id,
      name: name ?? this.name,
      roomName: roomName ?? this.roomName,
      category: category ?? this.category,
      cleaningAction: cleaningAction ?? this.cleaningAction,
      frequency: frequency ?? this.frequency,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isManuallyAdded: isManuallyAdded ?? this.isManuallyAdded,
    );
  }
}

// ─── Scanner Session ─────────────────────────────────────────────────────────

class ScannerSession {
  final String sessionId;
  List<RoomData> rooms;
  int currentRoomIndex;
  List<ReviewItem> reviewItems;
  bool isConfirmed;

  ScannerSession({
    String? sessionId,
    List<RoomData>? rooms,
    this.currentRoomIndex = 0,
    List<ReviewItem>? reviewItems,
    this.isConfirmed = false,
  })  : sessionId = sessionId ??
            'scan_${DateTime.now().millisecondsSinceEpoch}',
        rooms = rooms ??
            [
              RoomData(
                  id: 'living_room', name: 'Living Room', icon: Icons.chair),
              RoomData(id: 'bedroom', name: 'Bedroom', icon: Icons.bed),
              RoomData(
                  id: 'kitchen', name: 'Kitchen', icon: Icons.restaurant),
            ],
        reviewItems = reviewItems ?? List.from(mockReviewItems);

  RoomData get currentRoom =>
      rooms.isNotEmpty && currentRoomIndex < rooms.length
          ? rooms[currentRoomIndex]
          : (rooms.isNotEmpty
              ? rooms.first
              : RoomData(name: 'Living Room'));

  List<XFile> get allCapturedPhotos =>
      rooms.expand((r) => r.photos).toList();

  List<CapturedImage> get allCapturedImages =>
      rooms.expand((r) => r.images).toList();

  int get totalCapturedPhotos => allCapturedPhotos.length;

  int get confirmedCount => reviewItems.where((i) => i.isConfirmed).length;
  int get totalCount => reviewItems.length;

  List<ConfirmedItem> get confirmedItems =>
      reviewItems.map((r) => r.toConfirmedItem()).toList();

  List<CleaningRequirement> get cleaningRequirements =>
      reviewItems.where((r) => r.isConfirmed).map((r) => r.toCleaningRequirement()).toList();

  List<ReviewItem> itemsForCategory(ItemCategory category) =>
      reviewItems.where((i) => i.category == category).toList();

  List<ReviewItem> itemsForRoom(String roomName) =>
      reviewItems.where((i) => i.roomName == roomName).toList();

  Set<String> get availableRoomNames =>
      reviewItems.map((i) => i.roomName).toSet();

  void addItem(ReviewItem item) => reviewItems.add(item);

  void addDetectedItems(List<dynamic> items) {
    if (items.isEmpty) return;
    reviewItems.clear();
    for (final item in items) {
      final name = item.name as String;
      final roomName = item.roomName as String;
      final category = item.category as ItemCategory;
      reviewItems.add(
        ReviewItem(
          id: item.id as String,
          name: name,
          roomName: roomName,
          category: category,
          cleaningAction: 'Wipe / Dust',
          frequency: 'Every 7 days',
        ),
      );
    }
  }

  void toggleConfirmed(String id) {
    final idx = reviewItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      reviewItems[idx].isConfirmed = !reviewItems[idx].isConfirmed;
    }
  }

  void addRoom(String name, [IconData icon = Icons.door_sliding]) {
    final id = name.toLowerCase().replaceAll(' ', '_');
    rooms.add(RoomData(id: id, name: name, icon: icon));
  }

  Future<void> resetSession() async {
    for (final room in rooms) {
      await room.clearPhotos();
    }
    await ImageStorageService.instance.deleteSessionImages(sessionId);
    currentRoomIndex = 0;
    reviewItems = List.from(mockReviewItems);
    isConfirmed = false;
  }

  // ─── Default Mock Data ─────────────────────────────────────────────────────
  static final List<ReviewItem> mockReviewItems = [
    ReviewItem(
      name: 'Hardwood Floor',
      roomName: 'Living Room',
      category: ItemCategory.surfaces,
      cleaningAction: 'Vacuum / Mop',
      frequency: 'Every 7 days',
    ),
    ReviewItem(
      name: 'Coffee Table',
      roomName: 'Living Room',
      category: ItemCategory.furniture,
      cleaningAction: 'Wipe',
      frequency: 'Every 2 days',
    ),
    ReviewItem(
      name: 'TV Stand',
      roomName: 'Living Room',
      category: ItemCategory.furniture,
      cleaningAction: 'Dust',
      frequency: 'Every 7 days',
    ),
    ReviewItem(
      name: 'Sofa',
      roomName: 'Living Room',
      category: ItemCategory.furniture,
      cleaningAction: 'Vacuum',
      frequency: 'Every 14 days',
    ),
    ReviewItem(
      name: 'Television',
      roomName: 'Living Room',
      category: ItemCategory.electronics,
      cleaningAction: 'Dust',
      frequency: 'Every 7 days',
    ),
    ReviewItem(
      name: 'Area Rug',
      roomName: 'Bedroom',
      category: ItemCategory.surfaces,
      cleaningAction: 'Vacuum',
      frequency: 'Every 7 days',
    ),
    ReviewItem(
      name: 'Windowsill',
      roomName: 'Bedroom',
      category: ItemCategory.surfaces,
      cleaningAction: 'Wipe',
      frequency: 'Every 14 days',
    ),
    ReviewItem(
      name: 'Countertop',
      roomName: 'Kitchen',
      category: ItemCategory.surfaces,
      cleaningAction: 'Wipe & Disinfect',
      frequency: 'Every 2 days',
    ),
    ReviewItem(
      name: 'House Plant',
      roomName: 'Living Room',
      category: ItemCategory.other,
      cleaningAction: 'Dust Leaves',
      frequency: 'Every 14 days',
    ),
  ];
}
