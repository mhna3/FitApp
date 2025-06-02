// lib/services/daily_reset_service.dart - Updated with exercise support

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_service.dart';
import 'exercise_service.dart';

class DailyResetService {
  static const String _lastResetKey = 'last_reset_date';
  final FoodService _foodService = FoodService();
  final ExerciseService _exerciseService = ExerciseService();
  Timer? _dailyTimer;

  // Initialize the daily reset service
  Future<void> initialize() async {
    await _checkForDailyReset();
    _scheduleDailyReset();
  }

  // Check if we need to perform a daily reset
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

  // Perform the actual daily reset operations
  Future<void> _performDailyReset() async {
    try {
      // Clean up old food items (older than 7 days)
      await _foodService.cleanupOldItems();

      // Clean up old exercise items (older than 7 days)
      await _exerciseService.cleanupOldItems();

      // You can add more reset operations here:
      // - Reset daily step counter
      // - Reset daily water intake
      // - Reset sleep tracking
      // - Send daily summary notifications
      // - Calculate weekly/monthly statistics

      print('Daily reset operations completed (food + exercise cleanup)');
    } catch (e) {
      print('Error performing daily reset: $e');
    }
  }

  // Schedule the next daily reset at midnight
  void _scheduleDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _dailyTimer?.cancel();
    _dailyTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      _scheduleDailyReset(); // Schedule the next reset
    });

    print('Next daily reset scheduled for: $tomorrow');
  }

  // Get today's date as a string
  String _getTodayString() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  // Manual reset for testing purposes
  Future<void> performManualReset() async {
    await _performDailyReset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetKey, _getTodayString());
  }

  // Check if today's data should be cleared (for testing)
  Future<bool> shouldResetToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetString = prefs.getString(_lastResetKey);
    final today = _getTodayString();
    return lastResetString != today;
  }

  // Get summary stats for the week (useful for notifications)
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

  // Dispose of timers when not needed
  void dispose() {
    _dailyTimer?.cancel();
  }
}