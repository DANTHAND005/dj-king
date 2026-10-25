import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Public app identifiers from Firebase; database rules protect game data.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('DJ King supports Android, iOS, and web.'),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDYT6Njxx-AIah3XAkwsGWCpT_eB414aGQ',
    appId: '1:154972261064:web:3aa0c126b4dc831157f3fd',
    messagingSenderId: '154972261064',
    projectId: 'dj-king-c5353',
    authDomain: 'dj-king-c5353.firebaseapp.com',
    databaseURL: 'https://dj-king-c5353-default-rtdb.firebaseio.com',
    storageBucket: 'dj-king-c5353.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDDPqSdX7HCtDUBz0qE76EVrrYRZmb6jL4',
    appId: '1:154972261064:android:63642c976f8d649357f3fd',
    messagingSenderId: '154972261064',
    projectId: 'dj-king-c5353',
    databaseURL: 'https://dj-king-c5353-default-rtdb.firebaseio.com',
    storageBucket: 'dj-king-c5353.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyClZ5kFKSpbqx_lcoMK61Y5OSPp4tXg_fs',
    appId: '1:154972261064:ios:4d2122dc992de64757f3fd',
    messagingSenderId: '154972261064',
    projectId: 'dj-king-c5353',
    databaseURL: 'https://dj-king-c5353-default-rtdb.firebaseio.com',
    storageBucket: 'dj-king-c5353.firebasestorage.app',
    iosBundleId: 'com.example.djKing',
  );
}
