// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Email/Password Signup (existing method with workaround)
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _updateUserProfile(userCredential.user!, fullName.trim(), email.trim());
      return userCredential.user;

    } catch (e) {
      if (kDebugMode) print("Signup error: $e");

      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        try {
          await Future.delayed(Duration(milliseconds: 500));
          await _auth.currentUser?.reload();
          User? currentUser = _auth.currentUser;

          if (currentUser != null && currentUser.email == email.trim()) {
            await _updateUserProfile(currentUser, fullName.trim(), email.trim());
            return currentUser;
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  // Email/Password Login (existing method with workaround)
// Email/Password Login (existing method with workaround)
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user profile to ensure Firestore document exists
      if (userCredential.user != null) {
        await _updateUserProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? email.split('@')[0],
          email.trim(),
        );
      }

      return userCredential.user;

    } catch (e) {
      if (kDebugMode) print("Login error: $e");

      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        try {
          await Future.delayed(Duration(milliseconds: 500));
          await _auth.currentUser?.reload();
          User? currentUser = _auth.currentUser;

          if (currentUser != null && currentUser.email == email.trim()) {
            await _updateUserProfile(
              currentUser,
              currentUser.displayName ?? email.split('@')[0],
              email.trim(),
            );
            return currentUser;
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for signing in
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Update user profile in Firestore
      if (userCredential.user != null) {
        await _updateUserProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'Google User',
          userCredential.user!.email ?? '',
          isGoogleSignIn: true,
        );
      }

      return userCredential.user;

    } catch (e) {
      if (kDebugMode) print("Google sign-in error: $e");

      // Handle PigeonUserDetails error for Google sign-in too
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        try {
          await Future.delayed(Duration(milliseconds: 500));
          await _auth.currentUser?.reload();
          User? currentUser = _auth.currentUser;

          if (currentUser != null) {
            await _updateUserProfile(
              currentUser,
              currentUser.displayName ?? 'Google User',
              currentUser.email ?? '',
              isGoogleSignIn: true,
            );
            return currentUser;
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  // Helper method to update user profile
  Future<void> _updateUserProfile(
      User user,
      String fullName,
      String email, {
        bool isGoogleSignIn = false,
      }) async {
    try {
      // Update display name if not set
      if (user.displayName == null || user.displayName!.isEmpty) {
        await user.updateDisplayName(fullName);
      }

      // Check if user document already exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // User exists - only update basic info, preserve isAdmin status
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': fullName,
          'email': email,
          'signInMethod': isGoogleSignIn ? 'google' : 'email',
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      } else {
        // New user - set all fields including isAdmin: false
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'signInMethod': isGoogleSignIn ? 'google' : 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'uid': user.uid,
          'isAdmin': false, // Only set for new users
        });
      }

    } catch (e) {
      if (kDebugMode) print("Profile update error: $e");
    }
  }

  Future<void> setAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
      });
    } catch (e) {
      if (kDebugMode) print("Error setting admin status: $e");
      rethrow;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['isAdmin'] == true;
    } catch (e) {
      if (kDebugMode) print("Error checking admin status: $e");
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      if (kDebugMode) print("Sign out error: $e");
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      if (kDebugMode) print("Password reset error: $e");
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user has specific sign-in method
  Future<List<String>> getSignInMethods(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      if (kDebugMode) print("Error fetching sign-in methods: $e");
      return [];
    }
  }
}