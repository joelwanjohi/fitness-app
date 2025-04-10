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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAMKiHh8GfdvS5y7f1kxaJ5VaLc6a3f2W4',
    appId: '1:24350514815:web:f81dc40510c32f5bd3294a',
    messagingSenderId: '24350514815',
    projectId: 'gadgetmtaa',
    authDomain: 'gadgetmtaa.firebaseapp.com',
    databaseURL: 'https://gadgetmtaa-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'gadgetmtaa.firebasestorage.app',
    measurementId: 'G-QXM398MFJ0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlSRmRSjSfJYdSB_eoZ7ME0U3RHg0wMvo',
    appId: '1:24350514815:android:240901ffcb98489ed3294a',
    messagingSenderId: '24350514815',
    projectId: 'gadgetmtaa',
    databaseURL: 'https://gadgetmtaa-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'gadgetmtaa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDDT0Llsc266aafYY4WKKj_otczBsRbB8',
    appId: '1:24350514815:ios:21bc89c3a9c6d099d3294a',
    messagingSenderId: '24350514815',
    projectId: 'gadgetmtaa',
    databaseURL: 'https://gadgetmtaa-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'gadgetmtaa.firebasestorage.app',
    iosBundleId: 'com.example.livelongFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBDDT0Llsc266aafYY4WKKj_otczBsRbB8',
    appId: '1:24350514815:ios:21bc89c3a9c6d099d3294a',
    messagingSenderId: '24350514815',
    projectId: 'gadgetmtaa',
    databaseURL: 'https://gadgetmtaa-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'gadgetmtaa.firebasestorage.app',
    iosBundleId: 'com.example.livelongFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBJiOUAspze7BDWijmugae8db3bfFWBZyc',
    appId: '1:24350514815:web:bcfd328e522c2e99d3294a',
    messagingSenderId: '24350514815',
    projectId: 'gadgetmtaa',
    authDomain: 'gadgetmtaa.firebaseapp.com',
    databaseURL: 'https://gadgetmtaa-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'gadgetmtaa.firebasestorage.app',
    measurementId: 'G-QMHR8YYL3K',
  );
}
