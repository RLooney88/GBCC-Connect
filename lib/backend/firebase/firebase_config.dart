import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyD86S_CyvkU62VisnsNFgow7NptZ2v_nSs",
            authDomain: "gbcc-connect.firebaseapp.com",
            projectId: "gbcc-connect",
            storageBucket: "gbcc-connect.firebasestorage.app",
            messagingSenderId: "114383086199",
            appId: "1:114383086199:web:edacb93dcee67216be5c72"));
  } else {
    await Firebase.initializeApp();
  }
}
