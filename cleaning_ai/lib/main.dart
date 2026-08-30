import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Initialize background services
    await NotificationService.instance.initialize();
    SyncService.instance.initialize();
  } catch (_) {
    // App will use resilient fallback if offline or in test binding
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const KleenAIApp());
}

class KleenAIApp extends StatelessWidget {
  const KleenAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kleenai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        // Gracefully absorb Firebase Auth deep-link redirect callback URLs
        if (settings.name != null && (settings.name!.contains('/link') || settings.name!.contains('auth/callback'))) {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
            transitionDuration: Duration.zero,
          );
        }
        return null;
      },
    );
  }
}
