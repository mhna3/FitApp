// lib/services/food_service.dart - Updated with Fixed Goal Handling

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Get current user's email
  String? get _currentUserEmail => _auth.currentUser?.email;

  // Add food item to user's daily intake
  Future<void> addFoodItem(Map<String, dynamic> foodData) async {
    if (_currentUserEmail == null) throw Exception('User not logged in');

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      // Create the food item document
      final foodItem = {
        'userEmail': _currentUserEmail,
        'date': dateString,
        'timestamp': FieldValue.serverTimestamp(),
        'foodName': foodData['food_name'] ?? '',
        'servingQty': foodData['serving_qty'] ?? 0,
        'servingUnit': foodData['serving_unit'] ?? '',
        'calories': foodData['nf_calories'] ?? 0,
        'protein': foodData['nf_protein'] ?? 0,
        'carbs': foodData['nf_total_carbohydrate'] ?? 0,
        'fat': foodData['nf_total_fat'] ?? 0,
        'fiber': foodData['nf_dietary_fiber'] ?? 0,
        'sugar': foodData['nf_sugars'] ?? 0,
        'sodium': foodData['nf_sodium'] ?? 0,
        'photoUrl': foodData['photo']?['thumb'] ?? null,
      };

      await _firestore.collection('user_food_intake').add(foodItem);
    } catch (e) {
      throw Exception('Failed to add food item: $e');
    }
  }

  // Get today's food items for current user
  Future<List<Map<String, dynamic>>> getTodaysFoodItems() async {
    if (_currentUserEmail == null) return [];

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      // Query without orderBy to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection('user_food_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .where('date', isEqualTo: dateString)
          .get();

      // Convert to list and sort in memory by timestamp (most recent first)
      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by timestamp (newest first)
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
      print('Error fetching today\'s food items: $e');
      return [];
    }
  }

  // Calculate today's total nutrients
  Future<Map<String, double>> getTodaysNutrients() async {
    final foodItems = await getTodaysFoodItems();

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;

    for (final item in foodItems) {
      totalCalories += (item['calories'] ?? 0).toDouble();
      totalProtein += (item['protein'] ?? 0).toDouble();
      totalCarbs += (item['carbs'] ?? 0).toDouble();
      totalFat += (item['fat'] ?? 0).toDouble();
      totalFiber += (item['fiber'] ?? 0).toDouble();
      totalSugar += (item['sugar'] ?? 0).toDouble();
      totalSodium += (item['sodium'] ?? 0).toDouble();
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
      'sugar': totalSugar,
      'sodium': totalSodium,
    };
  }

  // Delete a food item
  Future<void> deleteFoodItem(String itemId) async {
    try {
      await _firestore.collection('user_food_intake').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete food item: $e');
    }
  }

  // Clean up old food items (older than 7 days to save storage)
  Future<void> cleanupOldItems() async {
    if (_currentUserEmail == null) return;

    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    final weekAgoString = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

    try {
      // Simple query without orderBy to avoid index issues
      final querySnapshot = await _firestore
          .collection('user_food_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .where('date', isLessThan: weekAgoString)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${querySnapshot.docs.length} old food items');
      }
    } catch (e) {
      print('Error cleaning up old items: $e');
    }
  }

  // Get user's food goals from their profile (Updated to use UserService)
  Future<Map<String, double>> getUserGoals() async {
    try {
      return await _userService.getUserFitnessGoals();
    } catch (e) {
      print('Error getting user goals, using defaults: $e');
      // Fallback to default goals if user service fails
      return {
        'calories': 2000,
        'protein': 150,  // grams
        'carbs': 250,    // grams
        'fat': 65,       // grams
      };
    }
  }

  // Calculate goal progress percentages (Updated to use actual user goals)
  Future<Map<String, double>> calculateGoalProgress(Map<String, double> nutrients) async {
    final goals = await getUserGoals();

    return {
      'calories': (nutrients['calories'] ?? 0) / goals['calories']!,
      'protein': (nutrients['protein'] ?? 0) / goals['protein']!,
      'carbs': (nutrients['carbs'] ?? 0) / goals['carbs']!,
      'fat': (nutrients['fat'] ?? 0) / goals['fat']!,
    };
  }

  // Get formatted goal display text
  Future<Map<String, String>> getGoalDisplayText() async {
    final goals = await getUserGoals();

    return {
      'calories': '${goals['calories']!.toInt()} cal',
      'protein': '${goals['protein']!.toInt()}g',
      'carbs': '${goals['carbs']!.toInt()}g',
      'fat': '${goals['fat']!.toInt()}g',
    };
  }

  // Check if user has reached their daily goals
  Future<Map<String, bool>> checkGoalsReached() async {
    final nutrients = await getTodaysNutrients();
    final progress = await calculateGoalProgress(nutrients);

    return {
      'calories': progress['calories']! >= 1.0,
      'protein': progress['protein']! >= 1.0,
      'carbs': progress['carbs']! >= 1.0,
      'fat': progress['fat']! >= 1.0,
    };
  }

  // Get nutrition summary for weekly/monthly reports
  Future<Map<String, dynamic>> getNutritionSummary(DateTime startDate, DateTime endDate) async {
    if (_currentUserEmail == null) return {};

    try {
      final dates = <String>[];
      for (var date = startDate; date.isBefore(endDate.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
        dates.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
      }

      final querySnapshot = await _firestore
          .collection('user_food_intake')
          .where('userEmail', isEqualTo: _currentUserEmail)
          .where('date', whereIn: dates)
          .get();

      // Aggregate data by date
      final dateWiseData = <String, Map<String, double>>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String;

        if (dateWiseData[date] == null) {
          dateWiseData[date] = {
            'calories': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
          };
        }

        dateWiseData[date]!['calories'] = (dateWiseData[date]!['calories']! + (data['calories'] ?? 0));
        dateWiseData[date]!['protein'] = (dateWiseData[date]!['protein']! + (data['protein'] ?? 0));
        dateWiseData[date]!['carbs'] = (dateWiseData[date]!['carbs']! + (data['carbs'] ?? 0));
        dateWiseData[date]!['fat'] = (dateWiseData[date]!['fat']! + (data['fat'] ?? 0));
      }

      return {
        'dateWiseData': dateWiseData,
        'totalDays': dates.length,
        'activeDays': dateWiseData.length,
      };
    } catch (e) {
      print('Error getting nutrition summary: $e');
      return {};
    }
  }
}