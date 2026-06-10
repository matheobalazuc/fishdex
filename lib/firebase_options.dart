import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ─────────────────────────────────────────────────────────────────
// INSTRUCTIONS :
//  1. Va sur https://console.firebase.google.com/project/fishdex-1052f
//  2. Paramètres du projet (⚙) → Général → "Tes applications"
//  3. Clique "+ Ajouter une application" → Web (si pas encore fait)
//  4. Copie les valeurs apiKey et appId dans les champs ci-dessous
//  5. Pour iOS : télécharge GoogleService-Info.plist et récupère
//     API_KEY et GOOGLE_APP_ID
// ─────────────────────────────────────────────────────────────────
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  // ── WEB ──────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDjG73ZeAFX5fpLa-FSSUvjlWiFec7RvSw',
    appId:             '1:997414023621:web:b41a4e859c83ce7b221bac',
    messagingSenderId: '997414023621',
    projectId:         'fishdex-1052f',
    authDomain:        'fishdex-1052f.firebaseapp.com',
    storageBucket:     'fishdex-1052f.firebasestorage.app',
  );

}
