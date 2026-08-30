import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/scanner_session.dart';
import '../models/task_frequency.dart';

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
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Parses voice transcript into structured cleaning items using Gemini AI or structured NLP parser.
  Future<List<ReviewItem>> parseSpeechToTasks(String transcript, {String? apiKey}) async {
    if (transcript.trim().isEmpty) return [];

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
        final prompt = '''
You are KleenAI, an expert cleaning assistant. Parse the following voice description into a JSON array of cleaning tasks.
Return ONLY raw JSON with this exact structure for each task:
[
  {
    "name": "Coffee Table",
    "roomName": "Living Room",
    "category": "surfaces",
    "cleaningAction": "Wipe",
    "frequency": "Weekly"
  }
]

Categories must be one of: "surfaces", "furniture", "electronics", "other".
Voice description: "$transcript"
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final List parsedList = jsonDecode(cleanJson);

          return parsedList.map((item) {
            return ReviewItem(
              id: 'voice_${DateTime.now().microsecondsSinceEpoch}',
              name: item['name'] as String? ?? 'Clean Area',
              roomName: item['roomName'] as String? ?? 'Living Room',
              category: _parseCategory(item['category'] as String?),
              cleaningAction: item['cleaningAction'] as String? ?? 'Wipe',
              frequency: item['frequency'] as String? ?? 'Weekly',
              isConfirmed: true,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('[VoiceTaskService] Gemini API parsing notice: $e. Using local smart NLP parser.');
      }
    }

    // Fallback Smart Local NLP parser
    return _smartLocalParse(transcript);
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

  List<ReviewItem> _smartLocalParse(String transcript) {
    final List<ReviewItem> items = [];
    final lower = transcript.toLowerCase();

    // Split speech by conjunctions / sentences
    final phrases = lower.split(RegExp(r'(\b(and|also|then|after that|plus)\b|[.,;\n])'));

    for (var phrase in phrases) {
      final text = phrase.trim();
      if (text.length < 3) continue;

      String room = 'Living Room';
      if (text.contains('bathroom')) room = 'Bathroom';
      if (text.contains('kitchen')) room = 'Kitchen';
      if (text.contains('bedroom')) room = 'Bedroom';
      if (text.contains('dining')) room = 'Dining Room';
      if (text.contains('hallway')) room = 'Hallway';

      String action = 'Wipe';
      if (text.contains('vacuum') || text.contains('hoover')) action = 'Vacuum';
      if (text.contains('mop')) action = 'Mop';
      if (text.contains('dust')) action = 'Dust';
      if (text.contains('scrub') || text.contains('deep clean')) action = 'Scrub';
      if (text.contains('wash')) action = 'Wash';

      String freq = 'Weekly';
      if (text.contains('daily') || text.contains('every day')) freq = 'Daily';
      if (text.contains('every 2 days') || text.contains('twice a week')) freq = '2x / Week';
      if (text.contains('biweekly') || text.contains('every 2 weeks')) freq = 'Bi-Weekly';
      if (text.contains('monthly') || text.contains('every month')) freq = 'Monthly';

      // Extract subject item
      String itemName = text
          .replaceAll(RegExp(r'\b(clean|vacuum|mop|dust|wipe|scrub|wash|every|daily|weekly|monthly|the|a|an|in|the|my|our)\b'), '')
          .replaceAll(RegExp(r'\b(bathroom|kitchen|bedroom|living room|dining room)\b'), '')
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
          roomName: 'Living Room',
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
    if (n.contains('floor') || n.contains('counter') || n.contains('window') || n.contains('mirror') || n.contains('sink')) return ItemCategory.surfaces;
    return ItemCategory.other;
  }
}
