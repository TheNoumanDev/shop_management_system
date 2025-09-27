import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    if (kIsWeb) {
      // For web, Firebase is initialized via the JavaScript SDK in index.html
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC21ed2-F0UlloIxZqAsu9hITc4b2kY4Zw",
          authDomain: "mashaallahmobileshop-6ef8a.firebaseapp.com",
          projectId: "mashaallahmobileshop-6ef8a",
          storageBucket: "mashaallahmobileshop-6ef8a.firebasestorage.app",
          messagingSenderId: "247259397180",
          appId: "1:247259397180:web:50c4d0708ec42a52131739",
          measurementId: "G-15LNFSC6PW",
        ),
      );
    } else {
      // For mobile platforms, use the generated firebase_options.dart
      await Firebase.initializeApp();
    }
  }

  // Auth Stream
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Current User
  User? get currentUser => auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign Out
  Future<void> signOut() async {
    await auth.signOut();
  }
}