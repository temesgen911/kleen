import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';

/// Service for synchronizing authenticated Firebase users with the FastAPI/PostgreSQL backend.
class BackendUserService {
  final http.Client _httpClient;
  final String _baseUrl;

  BackendUserService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    // iOS Simulator and macOS desktop default
    return 'http://127.0.0.1:8000';
  }

  /// Syncs or fetches the current user from the FastAPI backend using the Firebase ID token.
  Future<AuthUser?> fetchOrSyncUserProfile({
    required String firebaseIdToken,
    required String firebaseUid,
    String? email,
    String? displayName,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/me');

    try {
      developer.log('Syncing user profile with backend: $uri', name: 'BackendUserService');
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $firebaseIdToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final user = AuthUser.fromJson(data);
        developer.log('Backend user sync successful: ${user.id}', name: 'BackendUserService');
        return user;
      } else {
        developer.log(
          'Backend returned status ${response.statusCode}: ${response.body}',
          name: 'BackendUserService',
        );
      }
    } catch (e) {
      developer.log('Backend sync offline/fallback: $e', name: 'BackendUserService');
    }

    // Fallback: Construct local AuthUser if backend is temporarily unreachable
    return AuthUser(
      id: firebaseUid,
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      timezone: 'UTC',
      createdAt: DateTime.now(),
    );
  }
}
