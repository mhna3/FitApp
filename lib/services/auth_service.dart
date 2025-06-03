import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

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

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

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

  Future<void> _updateUserProfile(
      User user,
      String fullName,
      String email, {
        bool isGoogleSignIn = false,
      }) async {
    try {
      if (user.displayName == null || user.displayName!.isEmpty) {
        await user.updateDisplayName(fullName);
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': fullName,
          'email': email,
          'signInMethod': isGoogleSignIn ? 'google' : 'email',
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'signInMethod': isGoogleSignIn ? 'google' : 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'uid': user.uid,
          'isAdmin': false,
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      if (kDebugMode) print("Password reset error: $e");
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<List<String>> getSignInMethods(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      if (kDebugMode) print("Error fetching sign-in methods: $e");
      return [];
    }
  }
}