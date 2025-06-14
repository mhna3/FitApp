// File generated by FlutterFire CLI.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyD4VA4VAMF6bb-9Hfx69UasWUfJD46ZP9k',
    appId: '1:197211060793:web:3e3c778eeee373779febe8',
    messagingSenderId: '197211060793',
    projectId: 'fitapp-55595',
    authDomain: 'fitapp-55595.firebaseapp.com',
    databaseURL: 'https://fitapp-55595-default-rtdb.firebaseio.com',
    storageBucket: 'fitapp-55595.firebasestorage.app',
    measurementId: 'G-32GR725K36',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9S-ObEVkxPEhiXpIhJuSPJ_N5ZG8Ja5Y',
    appId: '1:197211060793:android:2e259e030f4337bf9febe8',
    messagingSenderId: '197211060793',
    projectId: 'fitapp-55595',
    databaseURL: 'https://fitapp-55595-default-rtdb.firebaseio.com',
    storageBucket: 'fitapp-55595.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrVxp5bcY-UEuiz-7dXuCA1LNHBJ6NKs4',
    appId: '1:197211060793:ios:5a9896b95ab5185b9febe8',
    messagingSenderId: '197211060793',
    projectId: 'fitapp-55595',
    databaseURL: 'https://fitapp-55595-default-rtdb.firebaseio.com',
    storageBucket: 'fitapp-55595.firebasestorage.app',
    androidClientId: '197211060793-mli438ajv139k65130ftj73r46rvdbip.apps.googleusercontent.com',
    iosClientId: '197211060793-1c1h9osllrmp60hq9kqqn1c4jcih985q.apps.googleusercontent.com',
    iosBundleId: 'com.example.fitApp',
  );
}
