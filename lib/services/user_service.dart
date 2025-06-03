import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  String? get _currentUserEmail => _auth.currentUser?.email;

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_currentUserId == null) return null;

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return _sanitizeProfileData(data);
      } else {
        return _getDefaultProfileData();
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Map<String, dynamic> _getDefaultProfileData() {
    return {
      'email': _currentUserEmail ?? '',
      'age': '',
      'height': '',
      'weight': '',
      'dailyCalorieGoal': '2000',
      'dailyCaloriesBurnedGoal': '500',
      'targetWeight': '',
      'workoutDaysPerWeek': '3',
      'dailyStepGoal': '10000',
    };
  }

  Map<String, dynamic> _sanitizeProfileData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    sanitized.remove('createdAt');
    sanitized.remove('updatedAt');

    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toString();
      } else if (value == null) {
        sanitized[key] = '';
      }
    });

    return sanitized;
  }

  Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUserId == null) return false;

    try {
      final cleanData = Map<String, dynamic>.from(profileData);

      cleanData['updatedAt'] = FieldValue.serverTimestamp();

      final docSnapshot = await _firestore.collection('users').doc(_currentUserId).get();
      if (!docSnapshot.exists) {
        cleanData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .set(cleanData, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUserId == null) return false;

    try {
      profileData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .update(profileData);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return await saveUserProfile(profileData);
    }
  }

  Future<Map<String, double>> getUserFitnessGoals() async {
    final profile = await getUserProfile();

    if (profile == null) {
      return {
        'calories': 2000,
        'protein': 150,
        'carbs': 250,
        'fat': 65,
      };
    }

    double calorieGoal = double.tryParse(profile['dailyCalorieGoal']?.toString() ?? '2000') ?? 2000;

    double proteinGoal = (calorieGoal * 0.30) / 4;
    double carbGoal = (calorieGoal * 0.40) / 4;
    double fatGoal = (calorieGoal * 0.30) / 9;

    return {
      'calories': calorieGoal,
      'protein': proteinGoal,
      'carbs': carbGoal,
      'fat': fatGoal,
    };
  }

  Future<Map<String, double>> getUserExerciseGoals() async {
    final profile = await getUserProfile();

    if (profile == null) {
      return {
        'caloriesBurned': 300,
        'duration': 60,
        'exercises': 3,
      };
    }

    double caloriesBurnedGoal = double.tryParse(profile['dailyCaloriesBurnedGoal']?.toString() ?? '300') ?? 300;
    double workoutDays = double.tryParse(profile['workoutDaysPerWeek']?.toString() ?? '3') ?? 3;

    double dailyExerciseGoal = workoutDays > 0 ? workoutDays : 3;
    double durationGoal = (workoutDays * 60) / 7;

    return {
      'caloriesBurned': caloriesBurnedGoal,
      'duration': durationGoal.clamp(30, 120),
      'exercises': dailyExerciseGoal,
    };
  }

  Future<bool> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      return true;
    } catch (e) {
      print('Error updating display name: $e');
      return false;
    }
  }

  Future<bool> isProfileComplete() async {
    final profile = await getUserProfile();
    if (profile == null) return false;

    return profile['age']?.toString().isNotEmpty == true &&
        profile['height']?.toString().isNotEmpty == true &&
        profile['weight']?.toString().isNotEmpty == true;
  }

  Future<double?> calculateBMI() async {
    final profile = await getUserProfile();
    if (profile == null) return null;

    final weightStr = profile['weight']?.toString() ?? '';
    final heightStr = profile['height']?.toString() ?? '';

    final weight = double.tryParse(weightStr.replaceAll(RegExp(r'[^0-9.]'), ''));

    final height = double.tryParse(heightStr.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (weight != null && height != null && height > 0) {
      final heightInMeters = height / 100;
      return weight / (heightInMeters * heightInMeters);
    }

    return null;
  }

  Future<bool> deleteUserProfile() async {
    if (_currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (_currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return _sanitizeProfileData(doc.data()!);
      }
      return null;
    });
  }

  Future<Map<String, String>> getFormattedGoals() async {
    final fitnessGoals = await getUserFitnessGoals();
    final exerciseGoals = await getUserExerciseGoals();

    return {
      'dailyCalories': '${fitnessGoals['calories']!.toInt()} cal',
      'dailyCaloriesBurned': '${exerciseGoals['caloriesBurned']!.toInt()} cal',
      'protein': '${fitnessGoals['protein']!.toInt()}g',
      'carbs': '${fitnessGoals['carbs']!.toInt()}g',
      'fat': '${fitnessGoals['fat']!.toInt()}g',
      'exercises': '${exerciseGoals['exercises']!.toInt()}',
      'duration': '${exerciseGoals['duration']!.toInt()} min',
    };
  }
}