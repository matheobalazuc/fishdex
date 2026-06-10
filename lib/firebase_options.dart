import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDjG73ZeAFX5fpLa-FSSUvjlWiFec7RvSw',
    appId:             '1:997414023621:web:b41a4e859c83ce7b221bac',
    messagingSenderId: '997414023621',
    projectId:         'fishdex-1052f',
    authDomain:        'fishdex-1052f.firebaseapp.com',
    storageBucket:     'fishdex-1052f.firebasestorage.app',
  );
}
