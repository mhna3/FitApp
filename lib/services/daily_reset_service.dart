import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_service.dart';
import 'exercise_service.dart';

class DailyResetService {
  static const String _lastResetKey = 'last_reset_date';
  final FoodService _foodService = FoodService();
  final ExerciseService _exerciseService = ExerciseService();
  Timer? _dailyTimer;

  Future<void> initialize() async {
    await _checkForDailyReset();
    _scheduleDailyReset();
  }

  Future<void> _checkForDailyReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetString = prefs.getString(_lastResetKey);
      final today = _getTodayString();

      if (lastResetString == null || lastResetString != today) {
        await _performDailyReset();
        await prefs.setString(_lastResetKey, today);
        print('Daily reset completed for: $today');
      }
    } catch (e) {
      print('Error checking for daily reset: $e');
    }
  }

  Future<void> _performDailyReset() async {
    try {
      await _foodService.cleanupOldItems();

      await _exerciseService.cleanupOldItems();

      print('Daily reset operations completed (food + exercise cleanup)');
    } catch (e) {
      print('Error performing daily reset: $e');
    }
  }

  void _scheduleDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _dailyTimer?.cancel();
    _dailyTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      _scheduleDailyReset();
    });

    print('Next daily reset scheduled for: $tomorrow');
  }

  String _getTodayString() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  Future<void> performManualReset() async {
    await _performDailyReset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetKey, _getTodayString());
  }

  Future<bool> shouldResetToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetString = prefs.getString(_lastResetKey);
    final today = _getTodayString();
    return lastResetString != today;
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final foodStats = await _foodService.getTodaysNutrients();
      final exerciseStats = await _exerciseService.getTodaysExerciseStats();

      return {
        'food': foodStats,
        'exercise': exerciseStats,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print('Error getting weekly summary: $e');
      return {};
    }
  }

  void dispose() {
    _dailyTimer?.cancel();
  }
}