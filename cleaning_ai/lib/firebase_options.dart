// File generated for kleenai Firebase Options
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcBUoCHZzmZOzPbD7D067IileB9Po6Hjo',
    appId: '1:30408461674:web:5a18e4c049daa2e557a913',
    messagingSenderId: '30408461674',
    projectId: 'kleenai',
    authDomain: 'kleenai.firebaseapp.com',
    storageBucket: 'kleenai.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcBUoCHZzmZOzPbD7D067IileB9Po6Hjo',
    appId: '1:30408461674:android:5a18e4c049daa2e557a913',
    messagingSenderId: '30408461674',
    projectId: 'kleenai',
    storageBucket: 'kleenai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcBUoCHZzmZOzPbD7D067IileB9Po6Hjo',
    appId: '1:30408461674:ios:5a18e4c049daa2e557a913',
    messagingSenderId: '30408461674',
    projectId: 'kleenai',
    storageBucket: 'kleenai.firebasestorage.app',
    iosClientId: '30408461674-behuqgg4crrcecjkfn9669m8b6q1babc.apps.googleusercontent.com',
    iosBundleId: 'com.kleenai.kleenai',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBcBUoCHZzmZOzPbD7D067IileB9Po6Hjo',
    appId: '1:30408461674:ios:5a18e4c049daa2e557a913',
    messagingSenderId: '30408461674',
    projectId: 'kleenai',
    storageBucket: 'kleenai.firebasestorage.app',
    iosClientId: '30408461674-behuqgg4crrcecjkfn9669m8b6q1babc.apps.googleusercontent.com',
    iosBundleId: 'com.kleenai.kleenai',
  );
}
