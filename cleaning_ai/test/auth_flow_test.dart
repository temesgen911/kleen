import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cleaning_ai/models/auth_user.dart';
import 'package:cleaning_ai/services/auth_service.dart';
import 'package:cleaning_ai/services/backend_user_service.dart';
import 'package:cleaning_ai/services/auth_state_notifier.dart';
import 'package:cleaning_ai/screens/auth/login_screen.dart';
import 'package:cleaning_ai/screens/auth/signup_screen.dart';
import 'package:cleaning_ai/screens/auth/auth_gate.dart';
import 'package:cleaning_ai/screens/profile/profile_screen.dart';
import 'package:cleaning_ai/screens/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthUser Model Tests', () {
    test('Serializes and deserializes correctly from camelCase JSON', () {
      final jsonMap = {
        'id': 'b13cf14a-f5bb-4aa7-bda8-54b9aa1bb4f6',
        'firebaseUid': 'fb_uid_test_123',
        'email': 'user@example.com',
        'displayName': 'Emma Watson',
        'timezone': 'UTC',
        'createdAt': '2026-08-17T12:00:00.000Z',
        'updatedAt': '2026-08-17T12:05:00.000Z',
      };

      final user = AuthUser.fromJson(jsonMap);
      expect(user.id, 'b13cf14a-f5bb-4aa7-bda8-54b9aa1bb4f6');
      expect(user.firebaseUid, 'fb_uid_test_123');
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'Emma Watson');
      expect(user.effectiveDisplayName, 'Emma Watson');

      final serialized = user.toJson();
      expect(serialized['firebaseUid'], 'fb_uid_test_123');
      expect(serialized['email'], 'user@example.com');
    });

    test('effectiveDisplayName falls back gracefully to email prefix', () {
      final user = AuthUser(
        id: '1',
        firebaseUid: 'uid1',
        email: 'alex.smith@test.com',
        displayName: null,
        createdAt: DateTime.now(),
      );
      expect(user.effectiveDisplayName, 'alex.smith');
    });
  });

  group('BackendUserService Tests', () {
    test('fetchOrSyncUserProfile parses 200 OK from backend successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/me');
        expect(request.headers['Authorization'], 'Bearer test_id_token_123');

        return http.Response(
          json.encode({
            'id': 'backend-user-uuid',
            'firebaseUid': 'fb-uid-123',
            'email': 'tester@example.com',
            'displayName': 'Test User',
            'timezone': 'UTC',
            'createdAt': '2026-08-17T12:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final backendService = BackendUserService(
        httpClient: mockClient,
        baseUrl: 'http://localhost:8000',
      );

      final profile = await backendService.fetchOrSyncUserProfile(
        firebaseIdToken: 'test_id_token_123',
        firebaseUid: 'fb-uid-123',
        email: 'tester@example.com',
        displayName: 'Test User',
      );

      expect(profile, isNotNull);
      expect(profile!.id, 'backend-user-uuid');
      expect(profile.displayName, 'Test User');
    });

    test('fetchOrSyncUserProfile falls back safely when backend returns 500 or error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final backendService = BackendUserService(
        httpClient: mockClient,
        baseUrl: 'http://localhost:8000',
      );

      final profile = await backendService.fetchOrSyncUserProfile(
        firebaseIdToken: 'err_token',
        firebaseUid: 'fb-fallback-uid',
        email: 'fallback@example.com',
        displayName: 'Fallback Name',
      );

      expect(profile, isNotNull);
      expect(profile!.firebaseUid, 'fb-fallback-uid');
      expect(profile.email, 'fallback@example.com');
    });
  });

  group('AuthStateNotifier & AuthService Integration Tests', () {
    test('Sign Up creates account, authenticates, and signs out', () async {
      final authService = AuthService();
      final backendService = BackendUserService(
        httpClient: MockClient((req) async => http.Response(
          json.encode({
            'id': 'uuid-new-user',
            'firebaseUid': 'user_new_test_com',
            'email': 'new@test.com',
            'displayName': 'New Cleaner',
            'timezone': 'UTC',
            'createdAt': '2026-08-17T12:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        )),
      );

      final notifier = AuthStateNotifier(
        authService: authService,
        backendUserService: backendService,
      );

      expect(notifier.isAuthenticated, isFalse);

      final success = await notifier.signUp(
        name: 'New Cleaner',
        email: 'new@test.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.currentUser?.email, 'new@test.com');

      await notifier.signOut();
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.currentUser, isNull);

      notifier.dispose();
    });

    test('Sign In authenticates existing user and updates state', () async {
      final authService = AuthService();
      final notifier = AuthStateNotifier(authService: authService);

      final success = await notifier.signIn(
        email: 'emma.cleaning@example.com',
        password: 'securepassword',
      );

      expect(success, isTrue);
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.currentUser?.email, 'emma.cleaning@example.com');

      notifier.dispose();
    });
  });

  group('Auth UI Widget Tests', () {
    testWidgets('LoginScreen validates inputs and triggers sign in', (tester) async {
      final authNotifier = AuthStateNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authNotifier: authNotifier),
        ),
      );

      expect(find.text('Welcome to Kleen'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Attempt to submit empty form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'emma@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'secret123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(authNotifier.isAuthenticated, isTrue);

      authNotifier.dispose();
    });

    testWidgets('SignUpScreen validates password match and strength', (tester) async {
      final authNotifier = AuthStateNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: SignUpScreen(authNotifier: authNotifier),
        ),
      );

      expect(find.text('Create Account'), findsWidgets);

      // Fill in mismatching passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Emma Watson');
      await tester.enterText(find.byType(TextFormField).at(1), 'emma@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'mypassword123');
      await tester.enterText(find.byType(TextFormField).at(3), 'wrongpassword');
      await tester.pump();

      // Strength indicator should show Strong
      expect(find.text('Strong'), findsOneWidget);

      // Attempt to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);

      // Fix confirm password
      await tester.enterText(find.byType(TextFormField).at(3), 'mypassword123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(authNotifier.isAuthenticated, isTrue);

      authNotifier.dispose();
    });

    testWidgets('AuthGate switches dynamically between LoginScreen and HomeScreen', (tester) async {
      final authNotifier = AuthStateNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(authNotifier: authNotifier),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      // Sign in
      await authNotifier.signIn(
        email: 'test@example.com',
        password: 'password123',
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Sign out
      await authNotifier.signOut();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      authNotifier.dispose();
    });

    testWidgets('ProfileScreen renders user details and sign out dialog', (tester) async {
      final authNotifier = AuthStateNotifier();
      await authNotifier.signIn(
        email: 'alex@example.com',
        password: 'password123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(authNotifier: authNotifier),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Open Sign Out dialog
      await tester.tap(find.text('Sign Out'));
      await tester.pump();

      expect(find.text('Are you sure you want to sign out of Cleaning AI?'), findsOneWidget);

      // Confirm sign out
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(authNotifier.isAuthenticated, isFalse);

      authNotifier.dispose();
    });
  });
}
