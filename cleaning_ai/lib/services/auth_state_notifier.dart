import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';
import 'backend_user_service.dart';

/// State notifier managing authentication state, current user profile, and backend synchronization.
class AuthStateNotifier extends ChangeNotifier {
  final AuthService _authService;
  final BackendUserService _backendUserService;

  StreamSubscription<fb.User?>? _authSubscription;

  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStateNotifier({
    AuthService? authService,
    BackendUserService? backendUserService,
  })  : _authService = authService ?? AuthService(),
        _backendUserService = backendUserService ?? BackendUserService() {
    _init();
  }

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((fbUser) async {
      if (fbUser != null) {
        await _syncWithBackend(fbUser);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _syncWithBackend(fb.User fbUser) async {
    try {
      debugPrint('[KleenAI Auth] Syncing authenticated user with backend: ${fbUser.email} (${fbUser.uid})');
      final token = await _authService.getIdToken() ?? 'mock_token_${fbUser.uid}';
      final syncedProfile = await _backendUserService.fetchOrSyncUserProfile(
        firebaseIdToken: token,
        firebaseUid: fbUser.uid,
        email: fbUser.email,
        displayName: fbUser.displayName,
      );

      _currentUser = syncedProfile ??
          AuthUser(
            id: fbUser.uid,
            firebaseUid: fbUser.uid,
            email: fbUser.email,
            displayName: fbUser.displayName,
            timezone: 'UTC',
            createdAt: DateTime.now(),
          );
      debugPrint('[KleenAI Auth] ✅ User state updated: ${_currentUser?.email}');
    } catch (e) {
      debugPrint('[KleenAI Auth] ⚠️ Error syncing user profile with backend: $e');
      _currentUser = AuthUser(
        id: fbUser.uid,
        firebaseUid: fbUser.uid,
        email: fbUser.email,
        displayName: fbUser.displayName,
        timezone: 'UTC',
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('[KleenAI Auth] Attempting Google Sign-In...');
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        debugPrint('[KleenAI Auth] Google Sign-In cancelled by user.');
        _setLoading(false);
        return false;
      }
      if (credential.user != null) {
        debugPrint('[KleenAI Auth] Google Sign-In succeeded, syncing backend for ${credential.user!.email}');
        await _syncWithBackend(credential.user!);
      }
      _setLoading(false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[KleenAI Auth] ❌ Firebase Auth Exception during Google sign-in: ${e.code} - ${e.message}');
      _setError(_mapFirebaseAuthError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[KleenAI Auth] ❌ Generic Error during Google sign-in: $e');
      final err = e.toString();
      if (err.contains('operation-not-allowed') || err.contains('disabled')) {
        _setError('Google Sign-In is disabled in Firebase Console. Enable it in Authentication > Sign-in method.');
      } else if (err.contains('network') || err.contains('SocketException')) {
        _setError('Network connection error. Please check your internet connection.');
      } else {
        _setError('Sign in error: ${err.replaceAll("Exception: ", "")}');
      }
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with email and password.
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _syncWithBackend(credential.user!);
      }
      _setLoading(false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to sign in. Please check your credentials and try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Create a new account with email, password, and name.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _syncWithBackend(credential.user!);
      }
      _setLoading(false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to create account. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset link.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send password reset email.');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthStateNotifier');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  String _mapFirebaseAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Google Sign-In is disabled in Firebase Console. Please enable Google in Firebase Console > Authentication > Sign-in providers.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
