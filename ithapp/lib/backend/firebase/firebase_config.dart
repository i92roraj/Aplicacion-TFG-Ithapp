import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCutQ9ACO6La8ifZ2DBFaQ17DQEMiJag88",
            authDomain: "ithapp-d147e.firebaseapp.com",
            projectId: "ithapp-d147e",
            storageBucket: "ithapp-d147e.firebasestorage.app",
            messagingSenderId: "672954509821",
            appId: "1:672954509821:web:31c07470495628f7fe1194"));
  } else {
    await Firebase.initializeApp();
  }
}
