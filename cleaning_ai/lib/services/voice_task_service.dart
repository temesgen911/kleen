import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/scanner_session.dart';

class RoomVoiceBubble {
  final String id;
  String roomTitle;
  String transcript;
  final DateTime recordedAt;

  RoomVoiceBubble({
    String? id,
    required this.roomTitle,
    required this.transcript,
    DateTime? recordedAt,
  })  : id = id ?? 'voice_bubble_${DateTime.now().microsecondsSinceEpoch}',
        recordedAt = recordedAt ?? DateTime.now();

  RoomVoiceBubble copyWith({
    String? roomTitle,
    String? transcript,
  }) {
    return RoomVoiceBubble(
      id: id,
      roomTitle: roomTitle ?? this.roomTitle,
      transcript: transcript ?? this.transcript,
      recordedAt: recordedAt,
    );
  }
}

class VoiceTaskService {
  static final VoiceTaskService instance = VoiceTaskService._internal();
  factory VoiceTaskService() => instance;
  VoiceTaskService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;

  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;
    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) => debugPrint('[VoiceTaskService] Speech error: $error'),
        onStatus: (status) => debugPrint('[VoiceTaskService] Speech status: $status'),
      );
    } catch (e) {
      debugPrint('[VoiceTaskService] Speech init exception: $e');
      _speechInitialized = false;
    }
    return _speechInitialized;
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function(bool isListening) onListeningStateChanged,
  }) async {
    final available = await initializeSpeech();
    if (!available) {
      onListeningStateChanged(false);
      return;
    }

    onListeningStateChanged(true);
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Parses multiple room voice transcripts into structured cleaning items using Gemini AI or Smart Local NLP.
  Future<List<ReviewItem>> parseMultiRoomTranscripts(
    List<RoomVoiceBubble> roomBubbles, {
    String? apiKey,
  }) async {
    final validBubbles = roomBubbles.where((b) => b.transcript.trim().isNotEmpty).toList();
    if (validBubbles.isEmpty) return [];

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

        final StringBuffer inputBuffer = StringBuffer();
        for (int i = 0; i < validBubbles.length; i++) {
          inputBuffer.writeln('Room ${i + 1} (${validBubbles[i].roomTitle}): "${validBubbles[i].transcript}"');
        }

        final prompt = '''
You are KleenAI, an expert cleaning assistant. Parse the following voice descriptions spoken across multiple rooms into a JSON array of cleaning tasks.
For each item mentioned (e.g. king bed, glass window, TV, rug, coffee table, counter, sink):
1. Extract or infer the room name (e.g. Master Bedroom, Living Room, Kitchen, Bathroom).
2. Assign an appropriate cleaning action (e.g., Wipe, Vacuum, Dust, Mop, Clean, Wash).
3. Assign a realistic frequency (one of: "Daily", "2x / Week", "Weekly", "Bi-Weekly", "Monthly").
4. Assign an estimated duration in minutes (integer between 2 and 45).
5. Assign category (one of: "surfaces", "furniture", "electronics", "other").

Return ONLY raw JSON with this exact array structure:
[
  {
    "name": "King Bed",
    "roomName": "Bedroom",
    "category": "furniture",
    "cleaningAction": "Make Bed & Tidy",
    "frequency": "Weekly",
    "estimatedMinutes": 10
  }
]

Voice descriptions:
${inputBuffer.toString()}
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final List parsedList = jsonDecode(cleanJson);

          return parsedList.map((item) {
            return ReviewItem(
              id: 'voice_${DateTime.now().microsecondsSinceEpoch}_${item['name']}',
              name: item['name'] as String? ?? 'Clean Area',
              roomName: item['roomName'] as String? ?? 'Room',
              category: _parseCategory(item['category'] as String?),
              cleaningAction: item['cleaningAction'] as String? ?? 'Wipe',
              frequency: item['frequency'] as String? ?? 'Weekly',
              isConfirmed: true,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('[VoiceTaskService] Gemini API multi-room parsing notice: $e. Using local smart NLP parser.');
      }
    }

    // Fallback Smart Local NLP parser for multi-room voice bubbles
    final List<ReviewItem> allItems = [];
    for (final bubble in validBubbles) {
      final items = _smartLocalParse(bubble.transcript, defaultRoom: bubble.roomTitle);
      allItems.addAll(items);
    }
    return allItems;
  }

  /// Single transcript parser bridge
  Future<List<ReviewItem>> parseSpeechToTasks(String transcript, {String? apiKey}) async {
    return parseMultiRoomTranscripts(
      [RoomVoiceBubble(roomTitle: 'Room 1', transcript: transcript)],
      apiKey: apiKey,
    );
  }

  ItemCategory _parseCategory(String? catStr) {
    if (catStr == null) return ItemCategory.surfaces;
    switch (catStr.toLowerCase()) {
      case 'surfaces':
        return ItemCategory.surfaces;
      case 'furniture':
        return ItemCategory.furniture;
      case 'electronics':
        return ItemCategory.electronics;
      default:
        return ItemCategory.other;
    }
  }

  List<ReviewItem> _smartLocalParse(String transcript, {String defaultRoom = 'Living Room'}) {
    final List<ReviewItem> items = [];
    final lower = transcript.toLowerCase();

    // Split speech by conjunctions / sentences
    final phrases = lower.split(RegExp(r'(\b(and|also|then|after that|plus|with a|and a|there is a|there are)\b|[.,;\n])'));

    for (var phrase in phrases) {
      final text = phrase.trim();
      if (text.length < 3) continue;

      String room = defaultRoom;
      if (text.contains('bathroom')) room = 'Bathroom';
      if (text.contains('kitchen')) room = 'Kitchen';
      if (text.contains('bedroom')) room = 'Bedroom';
      if (text.contains('dining')) room = 'Dining Room';
      if (text.contains('living')) room = 'Living Room';
      if (text.contains('hallway')) room = 'Hallway';

      String action = 'Wipe';
      if (text.contains('vacuum') || text.contains('hoover') || text.contains('rug') || text.contains('carpet')) action = 'Vacuum';
      if (text.contains('mop') || text.contains('floor')) action = 'Mop';
      if (text.contains('dust') || text.contains('tv') || text.contains('window')) action = 'Dust & Wipe';
      if (text.contains('bed')) action = 'Make Bed & Tidy';
      if (text.contains('scrub') || text.contains('deep clean')) action = 'Scrub';

      String freq = 'Weekly';
      if (text.contains('daily') || text.contains('every day')) freq = 'Daily';
      if (text.contains('every 2 days') || text.contains('twice a week')) freq = '2x / Week';
      if (text.contains('biweekly') || text.contains('every 2 weeks')) freq = 'Bi-Weekly';
      if (text.contains('monthly') || text.contains('every month')) freq = 'Monthly';

      // Extract subject item
      String itemName = text
          .replaceAll(RegExp(r'\b(clean|vacuum|mop|dust|wipe|scrub|wash|every|daily|weekly|monthly|the|a|an|in|my|our|there|is|are|has|have|see|i|saw|here|also)\b'), '')
          .replaceAll(RegExp(r'\b(bathroom|kitchen|bedroom|living room|dining room|hallway|room)\b'), '')
          .trim();

      if (itemName.isEmpty) {
        itemName = '$action $room';
      } else {
        itemName = itemName[0].toUpperCase() + itemName.substring(1);
      }

      items.add(
        ReviewItem(
          id: 'voice_${DateTime.now().microsecondsSinceEpoch}_${items.length}',
          name: itemName,
          roomName: room,
          category: _guessCategory(itemName),
          cleaningAction: action,
          frequency: freq,
          isConfirmed: true,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        ReviewItem(
          id: 'voice_${DateTime.now().microsecondsSinceEpoch}',
          name: 'General Room Cleaning',
          roomName: defaultRoom,
          category: ItemCategory.surfaces,
          cleaningAction: 'Tidy & Wipe',
          frequency: 'Weekly',
          isConfirmed: true,
        ),
      );
    }

    return items;
  }

  ItemCategory _guessCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('tv') || n.contains('screen') || n.contains('computer') || n.contains('lamp')) return ItemCategory.electronics;
    if (n.contains('sofa') || n.contains('couch') || n.contains('chair') || n.contains('bed') || n.contains('table')) return ItemCategory.furniture;
    if (n.contains('floor') || n.contains('counter') || n.contains('window') || n.contains('mirror') || n.contains('sink') || n.contains('rug')) return ItemCategory.surfaces;
    return ItemCategory.other;
  }
}
