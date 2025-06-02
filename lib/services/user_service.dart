// lib/services/user_service.dart - Updated with Calories Out Goal

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's UID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get current user's email
  String? get _currentUserEmail => _auth.currentUser?.email;

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_currentUserId == null) return null;

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        // Convert any Timestamp fields to DateTime strings for display
        return _sanitizeProfileData(data);
      } else {
        // Create default profile if doesn't exist
        return _getDefaultProfileData();
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Create default profile data (without FieldValue for UI display)
  Map<String, dynamic> _getDefaultProfileData() {
    return {
      'email': _currentUserEmail ?? '',
      'age': '',
      'height': '',
      'weight': '',
      'dailyCalorieGoal': '2000',
      'dailyCaloriesBurnedGoal': '300',  // NEW: Default calories burned goal
      'targetWeight': '',
      'workoutDaysPerWeek': '3',
      'dailyStepGoal': '10000',
    };
  }

  // Sanitize profile data for UI display (convert Timestamps, etc.)
  Map<String, dynamic> _sanitizeProfileData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Remove or convert any problematic fields
    sanitized.remove('createdAt');
    sanitized.remove('updatedAt');

    // Ensure all values are strings or numbers that can be converted to strings
    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toString();
      } else if (value == null) {
        sanitized[key] = '';
      }
    });

    return sanitized;
  }

  // Save user profile (this is the main method called from UI)
  Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUserId == null) return false;

    try {
      // Clean the profile data and add timestamps
      final cleanData = Map<String, dynamic>.from(profileData);

      // Add Firestore-specific fields
      cleanData['updatedAt'] = FieldValue.serverTimestamp();

      // Check if this is the first time saving (add createdAt)
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

  // Update user profile (alternative method)
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUserId == null) return false;

    try {
      // Add timestamp for last update
      profileData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .update(profileData);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      // If update fails (document doesn't exist), try to create it
      return await saveUserProfile(profileData);
    }
  }

  // Get user's fitness goals (used by food/exercise services)
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

    // Parse goals from profile with fallbacks
    double calorieGoal = double.tryParse(profile['dailyCalorieGoal']?.toString() ?? '2000') ?? 2000;

    // Calculate macros based on standard ratios
    double proteinGoal = (calorieGoal * 0.30) / 4; // 30% calories from protein, 4 cal/g
    double carbGoal = (calorieGoal * 0.40) / 4;    // 40% calories from carbs, 4 cal/g
    double fatGoal = (calorieGoal * 0.30) / 9;     // 30% calories from fat, 9 cal/g

    return {
      'calories': calorieGoal,
      'protein': proteinGoal,
      'carbs': carbGoal,
      'fat': fatGoal,
    };
  }

  // Get user's exercise goals (UPDATED to use actual user settings)
  Future<Map<String, double>> getUserExerciseGoals() async {
    final profile = await getUserProfile();

    if (profile == null) {
      return {
        'caloriesBurned': 300,
        'duration': 60,
        'exercises': 3,
      };
    }

    // Parse goals from user profile
    double caloriesBurnedGoal = double.tryParse(profile['dailyCaloriesBurnedGoal']?.toString() ?? '300') ?? 300;
    double workoutDays = double.tryParse(profile['workoutDaysPerWeek']?.toString() ?? '3') ?? 3;

    // Calculate reasonable exercise goals
    double dailyExerciseGoal = workoutDays > 0 ? workoutDays : 3; // At least 3 exercises if they work out
    double durationGoal = (workoutDays * 60) / 7; // Total weekly minutes divided by 7 days

    return {
      'caloriesBurned': caloriesBurnedGoal,  // Use actual user goal
      'duration': durationGoal.clamp(30, 120), // Between 30-120 minutes per day
      'exercises': dailyExerciseGoal,        // Use workout days as exercise count goal
    };
  }

  // Update display name
  Future<bool> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      return true;
    } catch (e) {
      print('Error updating display name: $e');
      return false;
    }
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    final profile = await getUserProfile();
    if (profile == null) return false;

    // Check if essential fields are filled
    return profile['age']?.toString().isNotEmpty == true &&
        profile['height']?.toString().isNotEmpty == true &&
        profile['weight']?.toString().isNotEmpty == true;
  }

  // Get user's BMI if height and weight are available
  Future<double?> calculateBMI() async {
    final profile = await getUserProfile();
    if (profile == null) return null;

    final weightStr = profile['weight']?.toString() ?? '';
    final heightStr = profile['height']?.toString() ?? '';

    // Try to parse weight (assume kg)
    final weight = double.tryParse(weightStr.replaceAll(RegExp(r'[^0-9.]'), ''));

    // Try to parse height (assume cm)
    final height = double.tryParse(heightStr.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (weight != null && height != null && height > 0) {
      // BMI = weight(kg) / (height(m))^2
      final heightInMeters = height / 100;
      return weight / (heightInMeters * heightInMeters);
    }

    return null;
  }

  // Delete user profile (for account deletion)
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

  // Stream user profile for real-time updates
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

  // Get formatted goal display for UI
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