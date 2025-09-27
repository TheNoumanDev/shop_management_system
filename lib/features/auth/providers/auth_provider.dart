import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() {
    // Listen to auth state changes
    _firebaseService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Register with email and password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final credential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        try {
          // Update display name
          await credential.user!.updateDisplayName(fullName);
          
          // Create user document in Firestore
          await _firebaseService.firestore
              .collection(AppConstants.usersCollection)
              .doc(credential.user!.uid)
              .set({
            'uid': credential.user!.uid,
            'email': email,
            'fullName': fullName,
            'role': AppConstants.adminRole, // Default to admin role
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
          
          // Reload user to get updated display name
          await credential.user!.reload();
          _user = _firebaseService.auth.currentUser;
          
          return true;
        } catch (firestoreError) {
          // If Firestore fails but user is created, still consider it success
          // The user can be completed later
          debugPrint('Firestore error: $firestoreError');
          _user = credential.user;
          return true;
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _user = null;
    } catch (e) {
      _setError('Error signing out. Please try again.');
    }
  }
  
  // Get user role from Firestore
  Future<String?> getUserRole() async {
    if (_user == null) return null;
    
    try {
      final doc = await _firebaseService.firestore
          .collection(AppConstants.usersCollection)
          .doc(_user!.uid)
          .get();
      
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Convert Firebase Auth error codes to user-friendly messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}