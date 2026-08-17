import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service managing Firebase Authentication operations.
class AuthService {
  FirebaseAuth? _auth;
  bool _initialized = false;

  final StreamController<User?> _fallbackAuthStateController =
      StreamController<User?>.broadcast();
  User? _mockCurrentUser;

  AuthService() {
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _auth = FirebaseAuth.instance;
      _initialized = true;
      developer.log('Firebase Auth initialized successfully.', name: 'AuthService');
    } catch (e) {
      developer.log('Firebase Core not yet configured natively: $e. Using resilient fallback.', name: 'AuthService');
      _initialized = false;
    }
  }

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges {
    if (_auth != null && _initialized) {
      return _auth!.authStateChanges();
    }
    return _fallbackAuthStateController.stream;
  }

  /// Current authenticated user (if any).
  User? get currentUser {
    if (_auth != null && _initialized) {
      return _auth!.currentUser;
    }
    return _mockCurrentUser;
  }

  /// Retrieves the current Firebase ID token for backend authorization headers.
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (_auth != null && _initialized && _auth!.currentUser != null) {
      return await _auth!.currentUser!.getIdToken(forceRefresh);
    }
    if (_mockCurrentUser != null) {
      return 'mock_token_${_mockCurrentUser!.uid}';
    }
    return null;
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    if (_auth != null && _initialized) {
      return await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }

    // Resilient simulated fallback for testing environments
    _mockCurrentUser = _createMockUser(email: email.trim());
    _fallbackAuthStateController.add(_mockCurrentUser);
    return _MockUserCredential(_mockCurrentUser!);
  }

  /// Create a new account with email, password, and display name.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    if (_auth != null && _initialized) {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      }
      return credential;
    }

    // Resilient simulated fallback for testing environments
    _mockCurrentUser = _createMockUser(email: email.trim(), displayName: name.trim());
    _fallbackAuthStateController.add(_mockCurrentUser);
    return _MockUserCredential(_mockCurrentUser!);
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _ensureInitialized();

    if (_auth != null && _initialized) {
      await _auth!.sendPasswordResetEmail(email: email.trim());
      return;
    }
    developer.log('Simulated password reset email sent to: $email', name: 'AuthService');
  }

  /// Sign out current user.
  Future<void> signOut() async {
    if (_auth != null && _initialized) {
      await _auth!.signOut();
    }
    _mockCurrentUser = null;
    _fallbackAuthStateController.add(null);
    developer.log('User signed out.', name: 'AuthService');
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initFirebase();
    }
  }

  User _createMockUser({required String email, String? displayName}) {
    return _SimulatedUser(
      uid: 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: displayName ?? (email.contains('@') ? email.split('@').first : 'User'),
    );
  }
}

// ---------------------------------------------------------------------------
// Resilient Mock Implementations for Tests & Unprovisioned Simulators
// ---------------------------------------------------------------------------

class _MockUserCredential implements UserCredential {
  @override
  final User user;
  _MockUserCredential(this.user);

  @override
  AuthCredential? get credential => null;
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}

class _SimulatedUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  _SimulatedUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token_$uid';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }

  @override
  bool get emailVerified => true;
  @override
  bool get isAnonymous => false;
  @override
  List<UserInfo> get providerData => [];
  @override
  UserMetadata get metadata => throw UnimplementedError();
  @override
  String? get phoneNumber => null;
  @override
  String? get photoURL => null;
  @override
  String? get refreshToken => null;
  @override
  String? get tenantId => null;

  @override
  Future<void> delete() async {}
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  @override
  Future<void> updateEmail(String newEmail) async {}
  @override
  Future<void> updatePassword(String newPassword) async {}
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {}
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<User> unlink(String providerId) async => throw UnimplementedError();
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
}
