import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Temporary Firebase options file so the app stays buildable until
/// `flutterfire configure` regenerates this file for the target project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDb5D83-AVyRi-ZmZ-5qBOjTDhGQjWIABE',
    appId: '1:69792730855:android:1c02620f04382a60971c42',
    messagingSenderId: '69792730855',
    projectId: 'alatol-b8ba3',
    storageBucket: 'alatol-b8ba3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDS7Fi5mMrnZvxuF4fQJUlqxFbba6SSN3k',
    appId: '1:69792730855:ios:b1d7588176519827971c42',
    messagingSenderId: '69792730855',
    projectId: 'alatol-b8ba3',
    storageBucket: 'alatol-b8ba3.firebasestorage.app',
    iosBundleId: 'com.alatol.alatoldelivery',
  );

}