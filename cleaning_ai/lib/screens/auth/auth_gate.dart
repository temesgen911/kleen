import 'package:flutter/material.dart';
import '../../services/auth_state_notifier.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Top-level authentication gateway that dynamically switches between
/// LoginScreen and HomeScreen based on the current user session state.
class AuthGate extends StatefulWidget {
  final AuthStateNotifier? authNotifier;

  const AuthGate({
    super.key,
    this.authNotifier,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthStateNotifier _authNotifier;
  bool _ownsNotifier = false;

  @override
  void initState() {
    super.initState();
    if (widget.authNotifier != null) {
      _authNotifier = widget.authNotifier!;
    } else {
      _authNotifier = AuthStateNotifier();
      _ownsNotifier = true;
    }
  }

  @override
  void dispose() {
    if (_ownsNotifier) {
      _authNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authNotifier,
      builder: (context, _) {
        if (_authNotifier.isAuthenticated) {
          return HomeScreen(authNotifier: _authNotifier);
        }
        return LoginScreen(authNotifier: _authNotifier);
      },
    );
  }
}
