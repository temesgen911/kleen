import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// ─── Room Data ───────────────────────────────────────────────────────────────

class RoomData {
  final String id;
  final String name;
  final IconData icon;
  final List<XFile> photos;

  RoomData({
    String? id,
    required this.name,
    this.icon = Icons.chair,
    List<XFile>? photos,
  })  : id = id ??
            'room_${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}',
        photos = photos ?? [];

  int get photoCount => photos.length;
  bool get hasSufficientPhotos => photos.length >= 2;
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

// ─── Review Item ─────────────────────────────────────────────────────────────

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
  List<RoomData> rooms;
  int currentRoomIndex;
  List<ReviewItem> reviewItems;
  bool isConfirmed;

  ScannerSession({
    List<RoomData>? rooms,
    this.currentRoomIndex = 0,
    List<ReviewItem>? reviewItems,
    this.isConfirmed = false,
  })  : rooms = rooms ??
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

  int get totalCapturedPhotos => allCapturedPhotos.length;

  int get confirmedCount => reviewItems.where((i) => i.isConfirmed).length;
  int get totalCount => reviewItems.length;

  List<ReviewItem> itemsForCategory(ItemCategory category) =>
      reviewItems.where((i) => i.category == category).toList();

  List<ReviewItem> itemsForRoom(String roomName) =>
      reviewItems.where((i) => i.roomName == roomName).toList();

  Set<String> get availableRoomNames =>
      reviewItems.map((i) => i.roomName).toSet();

  void addItem(ReviewItem item) => reviewItems.add(item);

  void toggleConfirmed(String id) {
    final idx = reviewItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      reviewItems[idx].isConfirmed = !reviewItems[idx].isConfirmed;
    }
  }

  void addRoom(String name, [IconData icon = Icons.door_sliding]) {
    rooms.add(RoomData(name: name, icon: icon));
  }

  // ─── Mock Data ─────────────────────────────────────────────────────────────
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
