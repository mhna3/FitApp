import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  String? get _currentUserEmail => _auth.currentUser?.email;

  Future<void> addExerciseItem(Map<String, dynamic> exerciseData) async {
    if (_currentUserEmail == null) throw Exception('User not logged in');

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final exerciseItem = {
        'userEmail': _currentUserEmail,
        'date': dateString,
        'timestamp': FieldValue.serverTimestamp(),
        'exerciseName': exerciseData['name'] ?? '',
        'duration': exerciseData['duration_min'] ?? 0,
        'calories': exerciseData['nf_calories'] ?? 0,
        'met': exerciseData['met'] ?? 0,
        'photoUrl': exerciseData['photo']?['thumb'] ?? null,
        'userInput': exerciseData['user_input'] ?? '',
      };

      await _firestore.collection('user_exercise_intake').add(exerciseItem);
    } catch (e) {
      throw Exception('Failed to add exercise item: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTodaysExerciseItems() async {
    if (_currentUserEmail == null) return [];

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final querySnapshot = await _firestore
          .collection('user_exercise_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .where('date', isEqualTo: dateString)
          .get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      items.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;

        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;

        return timestampB.compareTo(timestampA);
      });

      return items;
    } catch (e) {
      print('Error fetching today\'s exercise items: $e');
      return [];
    }
  }

  Future<Map<String, double>> getTodaysExerciseStats() async {
    final exerciseItems = await getTodaysExerciseItems();

    double totalCalories = 0;
    double totalDuration = 0;
    int totalExercises = exerciseItems.length;

    for (final item in exerciseItems) {
      totalCalories += (item['calories'] ?? 0).toDouble();
      totalDuration += (item['duration'] ?? 0).toDouble();
    }

    return {
      'calories': totalCalories,
      'duration': totalDuration,
      'exercises': totalExercises.toDouble(),
    };
  }

  Future<void> deleteExerciseItem(String itemId) async {
    try {
      await _firestore.collection('user_exercise_intake').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete exercise item: $e');
    }
  }

  Future<void> cleanupOldItems() async {
    if (_currentUserEmail == null) return;

    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    final weekAgoString = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

    try {
      final querySnapshot = await _firestore
          .collection('user_exercise_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .where('date', isLessThan: weekAgoString)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${querySnapshot.docs.length} old exercise items');
      }
    } catch (e) {
      print('Error cleaning up old exercise items: $e');
    }
  }

  Future<Map<String, double>> getUserExerciseGoals() async {
    try {
      return await _userService.getUserExerciseGoals();
    } catch (e) {
      print('Error getting user exercise goals, using defaults: $e');
      return {
        'caloriesBurned': 500,
        'duration': 60,
        'exercises': 3,
      };
    }
  }

  Future<Map<String, double>> calculateExerciseProgress(Map<String, double> stats) async {
    final goals = await getUserExerciseGoals();

    return {
      'caloriesBurned': (stats['calories'] ?? 0) / goals['caloriesBurned']!,
      'duration': (stats['duration'] ?? 0) / goals['duration']!,
      'exercises': (stats['exercises'] ?? 0) / goals['exercises']!,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentExercises() async {
    final items = await getTodaysExerciseItems();
    return items.take(3).toList(); // Return top 3 recent exercises
  }

  Future<Map<String, String>> getGoalDisplayText() async {
    final goals = await getUserExerciseGoals();

    return {
      'caloriesBurned': '${goals['caloriesBurned']!.toInt()} cal',
      'duration': '${goals['duration']!.toInt()} min',
      'exercises': '${goals['exercises']!.toInt()}',  // FIXED: Remove 'exercises' suffix
    };
  }

  Future<Map<String, bool>> checkGoalsReached() async {
    final stats = await getTodaysExerciseStats();
    final progress = await calculateExerciseProgress(stats);

    return {
      'caloriesBurned': progress['caloriesBurned']! >= 1.0,
      'duration': progress['duration']! >= 1.0,
      'exercises': progress['exercises']! >= 1.0,
    };
  }

  Future<Map<String, dynamic>> getExerciseReport(DateTime startDate, DateTime endDate) async {
    if (_currentUserEmail == null) return {};

    try {
      final dates = <String>[];
      for (var date = startDate; date.isBefore(endDate.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
        dates.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
      }

      final querySnapshot = await _firestore
          .collection('user_exercise_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .where('date', whereIn: dates)
          .get();

      final dateWiseData = <String, Map<String, double>>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String;

        if (dateWiseData[date] == null) {
          dateWiseData[date] = {
            'calories': 0,
            'duration': 0,
            'exercises': 0,
          };
        }

        dateWiseData[date]!['calories'] = (dateWiseData[date]!['calories']! + (data['calories'] ?? 0));
        dateWiseData[date]!['duration'] = (dateWiseData[date]!['duration']! + (data['duration'] ?? 0));
        dateWiseData[date]!['exercises'] = (dateWiseData[date]!['exercises']! + 1);
      }

      return {
        'dateWiseData': dateWiseData,
        'totalDays': dates.length,
        'activeDays': dateWiseData.length,
      };
    } catch (e) {
      print('Error getting exercise report: $e');
      return {};
    }
  }

  Future<int> getWorkoutStreak() async {
    if (_currentUserEmail == null) return 0;

    try {
      int streak = 0;
      final today = DateTime.now();

      for (int i = 0; i < 365; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dateString = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        final querySnapshot = await _firestore
            .collection('user_exercise_intake')
            .where('userEmail', isEqualTo: _currentUserEmail)
            .where('date', isEqualTo: dateString)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error getting workout streak: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteExercises({int limit = 5}) async {
    if (_currentUserEmail == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('user_exercise_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .get();

      final exerciseCount = <String, Map<String, dynamic>>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final exerciseName = data['exerciseName'] as String? ?? 'Unknown';

        if (exerciseCount[exerciseName] == null) {
          exerciseCount[exerciseName] = {
            'name': exerciseName,
            'count': 0,
            'totalCalories': 0.0,
            'totalDuration': 0.0,
          };
        }

        exerciseCount[exerciseName]!['count'] = exerciseCount[exerciseName]!['count'] + 1;
        exerciseCount[exerciseName]!['totalCalories'] = exerciseCount[exerciseName]!['totalCalories'] + (data['calories'] ?? 0);
        exerciseCount[exerciseName]!['totalDuration'] = exerciseCount[exerciseName]!['totalDuration'] + (data['duration'] ?? 0);
      }

      final sortedExercises = exerciseCount.values.toList();
      sortedExercises.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return sortedExercises.take(limit).toList();
    } catch (e) {
      print('Error getting favorite exercises: $e');
      return [];
    }
  }
}