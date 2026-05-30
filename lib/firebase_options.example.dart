// Sao chép file này thành `firebase_options.dart` rồi điền giá trị từ Firebase Console
// hoặc chạy: flutterfire configure
//
// KHÔNG commit file `firebase_options.dart` lên GitHub public.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'YOUR_FIREBASE_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
      storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    );
  }
}
