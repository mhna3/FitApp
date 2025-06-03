import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';

class ClassesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<FitnessClass>> getClasses() {
    return _firestore
        .collection('classes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FitnessClass.fromMap(doc.data()))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime)));
  }

  Stream<List<FitnessClass>> getUpcomingClasses() {
    return _firestore
        .collection('classes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return snapshot.docs
          .map((doc) => FitnessClass.fromMap(doc.data()))
          .where((fitnessClass) => fitnessClass.dateTime.millisecondsSinceEpoch > now)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  Stream<List<FitnessClass>> getClassesByCategory(String category) {
    return _firestore
        .collection('classes')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return snapshot.docs
          .map((doc) => FitnessClass.fromMap(doc.data()))
          .where((fitnessClass) => fitnessClass.dateTime.millisecondsSinceEpoch > now)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  Stream<List<FitnessClass>> getUserRegisteredClasses() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('classes')
        .where('registeredUsers', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FitnessClass.fromMap(doc.data()))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime)));
  }

  Future<String> addClass(FitnessClass fitnessClass) async {
    try {
      final docRef = _firestore.collection('classes').doc();
      final classWithId = fitnessClass.copyWith(id: docRef.id);

      await docRef.set(classWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add class: $e');
    }
  }

  Future<void> updateClass(FitnessClass fitnessClass) async {
    try {
      await _firestore
          .collection('classes')
          .doc(fitnessClass.id)
          .update(fitnessClass.toMap());
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  Future<bool> registerForClass(String classId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }

      final fitnessClass = FitnessClass.fromMap(classDoc.data()!);

      if (fitnessClass.isFull) {
        throw Exception('Class is full');
      }

      if (fitnessClass.registeredUsers.contains(userId)) {
        throw Exception('Already registered for this class');
      }

      if (!fitnessClass.isUpcoming) {
        throw Exception('Cannot register for past classes');
      }

      await _firestore.collection('classes').doc(classId).update({
        'registeredUsers': FieldValue.arrayUnion([userId])
      });

      return true;
    } catch (e) {
      throw Exception('Failed to register for class: $e');
    }
  }

  Future<bool> unregisterFromClass(String classId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }

      final fitnessClass = FitnessClass.fromMap(classDoc.data()!);

      if (!fitnessClass.registeredUsers.contains(userId)) {
        throw Exception('Not registered for this class');
      }

      if (fitnessClass.dateTime.isBefore(DateTime.now().add(Duration(hours: 2)))) {
        throw Exception('Cannot unregister less than 2 hours before class');
      }

      await _firestore.collection('classes').doc(classId).update({
        'registeredUsers': FieldValue.arrayRemove([userId])
      });

      return true;
    } catch (e) {
      throw Exception('Failed to unregister from class: $e');
    }
  }

  Future<bool> isUserAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String)
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      return ['Yoga', 'Cardio', 'Strength', 'Pilates', 'Dance', 'Martial Arts'];
    }
  }

  List<String> getDifficultyLevels() {
    return ['Beginner', 'Intermediate', 'Advanced'];
  }
}