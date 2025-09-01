import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_user == null) return null;
      
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      return doc.data();
    } catch (e) {
      _error = 'Error getting user data: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? gender,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user == null) throw Exception('No user logged in');

      // Update display name in Firebase Auth if provided
      if (displayName != null && displayName.trim().isNotEmpty) {
        await _user!.updateDisplayName(displayName);
      }

      // Update user data in Firestore
      final updates = <String, dynamic>{};
      if (displayName != null && displayName.trim().isNotEmpty) {
        updates['displayName'] = displayName;
      }
      if (gender != null && gender.trim().isNotEmpty) {
        updates['gender'] = gender;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update(updates);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadUserFromPreferences();
  }

  Future<void> _loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    final userPassword = prefs.getString('userPassword');
    
    if (userEmail != null && userPassword != null) {
      await signIn(userEmail, userPassword, true);
    }
  }

  Future<void> signUp(String email, String password, String displayName, String gender) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);

      // Save user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseAuthErrorMessage(e);
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password, [bool rememberMe = false]) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setString('userPassword', password);
      }

      _user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseAuthErrorMessage(e);
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userEmail');
      await prefs.remove('userPassword');
      
      await _auth.signOut();
      _user = null;
    } catch (e) {
      _error = 'Error signing out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'The password provided is too weak';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'user-disabled':
        return 'This user account has been disabled';
      default:
        return 'An error occurred during authentication';
    }
  }
}
