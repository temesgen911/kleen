import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cleaning_streak.dart';
import 'local_db_service.dart';

/// Storage service for persisting cleaning streaks across app launches.
class StreakStorage {
  static const String _keyStreak = 'cleaning_streak_data_v1';

  /// Saves the current streak to local storage.
  static Future<void> saveStreak(CleaningStreak streak) async {
    try {
      await LocalDbService.instance.saveStreak(streak);
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(streak.toJson());
      await prefs.setString(_keyStreak, jsonString);
    } catch (e) {
      // Fallback silently
    }
  }

  /// Loads the saved streak from local storage, or returns initial if not found.
  static Future<CleaningStreak> loadStreak() async {
    try {
      final streak = await LocalDbService.instance.loadStreak();
      if (streak.currentStreak > 0 || streak.totalCompletedDays > 0) {
        return streak;
      }
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyStreak);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        return CleaningStreak.fromJson(decoded);
      }
    } catch (e) {
      // Fallback on decode error
    }
    return CleaningStreak.initial();
  }

  /// Clears stored streak data (for debugging/testing).
  static Future<void> clearStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyStreak);
    } catch (_) {}
  }
}
