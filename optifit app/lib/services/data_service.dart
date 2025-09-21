import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_models.dart';

class DataService {
  static const String _workoutHistoryKey = 'workout_history';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _scheduledWorkoutsKey = 'scheduled_workouts';
  static const String _aiChatHistoryKey = 'ai_chat_history';
  static const String _userProfileKey = 'user_profile';

  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  SharedPreferences? _prefs;
  List<WorkoutSession>? _workoutHistoryCache;

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Workout History
  Future<List<WorkoutSession>> getWorkoutHistory({bool forceReload = false}) async {
    if (_workoutHistoryCache != null && !forceReload) {
      return _workoutHistoryCache!;
    }
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_workoutHistoryKey);
    if (jsonString == null) {
      _workoutHistoryCache = [];
      return [];
    }
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      _workoutHistoryCache = jsonList.map((json) => WorkoutSession.fromJson(json)).toList();
      return _workoutHistoryCache!;
    } catch (e) {
      debugPrint('Error loading workout history: $e');
      _workoutHistoryCache = [];
      return [];
    }
  }

  Future<void> saveWorkoutHistory(List<WorkoutSession> sessions) async {
    final prefs = await _getPrefs();
    final jsonList = sessions.map((session) => session.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_workoutHistoryKey, jsonString);
    _workoutHistoryCache = List.from(sessions);
  }

  Future<void> addWorkoutSession(WorkoutSession session) async {
    final history = await getWorkoutHistory();
    history.add(session);
    await saveWorkoutHistory(history);
  }

  void clearWorkoutHistoryCache() {
    _workoutHistoryCache = null;
  }

  // User Preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_userPreferencesKey);
    if (jsonString == null) {
      // Return default preferences
      return {
        'theme': 'light',
        'notifications': true,
        'workoutReminders': true,
        'reminderTime': '18:00',
        'units': 'metric', // metric or imperial
        'autoStartWorkout': false,
        'soundEnabled': true,
        'vibrationEnabled': true,
      };
    }
    
    try {
      return Map<String, dynamic>.from(json.decode(jsonString));
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      return {};
    }
  }

  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    final prefs = await _getPrefs();
    final jsonString = json.encode(preferences);
    await prefs.setString(_userPreferencesKey, jsonString);
  }

  Future<void> updateUserPreference(String key, dynamic value) async {
    final preferences = await getUserPreferences();
    preferences[key] = value;
    await saveUserPreferences(preferences);
  }

  // Scheduled Workouts
  Future<Map<String, List<Map<String, dynamic>>>> getScheduledWorkouts() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_scheduledWorkoutsKey);
    if (jsonString == null) return {};
    
    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(
        key,
        (value as List).map((item) {
          final map = Map<String, dynamic>.from(item);
          if (map.containsKey('color') && map['color'] is int) {
            map['color'] = Color(map['color']);
          }
          return map;
        }).toList(),
      ));
    } catch (e) {
      debugPrint('Error loading scheduled workouts: $e');
      return {};
    }
  }

  Future<void> saveScheduledWorkouts(Map<String, List<Map<String, dynamic>>> workouts) async {
    final prefs = await _getPrefs();
    final toSave = workouts.map((key, value) => MapEntry(
      key,
      value.map((item) {
        final map = Map<String, dynamic>.from(item);
        if (map['color'] is Color) {
          map['color'] = (map['color'] as Color).value;
        }
        return map;
      }).toList(),
    ));
    final jsonString = json.encode(toSave);
    await prefs.setString(_scheduledWorkoutsKey, jsonString);
  }

  // AI Chat History
  Future<List<Map<String, dynamic>>> getAIChatHistory() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_aiChatHistoryKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error loading AI chat history: $e');
      return [];
    }
  }

  Future<void> saveAIChatHistory(List<Map<String, dynamic>> messages) async {
    final prefs = await _getPrefs();
    final jsonString = json.encode(messages);
    await prefs.setString(_aiChatHistoryKey, jsonString);
  }

  Future<void> addAIChatMessage(Map<String, dynamic> message) async {
    final history = await getAIChatHistory();
    history.add(message);
    // Keep only last 100 messages to prevent storage bloat
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }
    await saveAIChatHistory(history);
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_userProfileKey);
    if (jsonString == null) {
      return {
        'name': 'Fitness Enthusiast',
        'age': 25,
        'weight': 70.0,
        'height': 170.0,
        'fitnessLevel': 'beginner',
        'goals': ['strength', 'muscle'],
        'experience': 0,
        'joinDate': DateTime.now().toIso8601String(),
      };
    }
    
    try {
      return Map<String, dynamic>.from(json.decode(jsonString));
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return {};
    }
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await _getPrefs();
    final jsonString = json.encode(profile);
    await prefs.setString(_userProfileKey, jsonString);
  }

  // Statistics
  Future<Map<String, dynamic>> getWorkoutStats() async {
    final history = await getWorkoutHistory();
    if (history.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalDuration': 0,
        'totalCalories': 0,
        'streakDays': 0,
        'favoriteWorkout': null,
        'averageFormScore': 0.0,
      };
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentWorkouts = history.where((session) => 
      session.startTime.isAfter(thirtyDaysAgo)
    ).toList();

    int streakDays = 0;
    DateTime currentDate = now;
    
    while (true) {
      final dayWorkouts = history.where((session) =>
        session.startTime.year == currentDate.year &&
        session.startTime.month == currentDate.month &&
        session.startTime.day == currentDate.day
      ).toList();
      
      if (dayWorkouts.isEmpty) break;
      streakDays++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return {
      'totalWorkouts': history.length,
      'totalDuration': history.fold(0, (sum, session) => sum + session.duration.inMinutes),
      'totalCalories': history.fold(0, (sum, session) => sum + (session.caloriesBurned ?? 0)),
      'streakDays': streakDays,
      'recentWorkouts': recentWorkouts.length,
      'averageFormScore': history.fold(0.0, (sum, session) => sum + (session.averageFormScore ?? 0)) / history.length,
    };
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_workoutHistoryKey);
    await prefs.remove(_userPreferencesKey);
    await prefs.remove(_scheduledWorkoutsKey);
    await prefs.remove(_aiChatHistoryKey);
    await prefs.remove(_userProfileKey);
    clearWorkoutHistoryCache();
  }

  // Export data (for backup)
  Future<String> exportData() async {
    final data = {
      'workoutHistory': await getWorkoutHistory(),
      'userPreferences': await getUserPreferences(),
      'scheduledWorkouts': await getScheduledWorkouts(),
      'aiChatHistory': await getAIChatHistory(),
      'userProfile': await getUserProfile(),
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    return json.encode(data);
  }

  // Import data (for restore)
  Future<bool> importData(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      if (data.containsKey('workoutHistory')) {
        final history = (data['workoutHistory'] as List)
            .map((item) => WorkoutSession.fromJson(item))
            .toList();
        await saveWorkoutHistory(history);
      }
      
      if (data.containsKey('userPreferences')) {
        await saveUserPreferences(Map<String, dynamic>.from(data['userPreferences']));
      }
      
      if (data.containsKey('scheduledWorkouts')) {
        await saveScheduledWorkouts(Map<String, List<Map<String, dynamic>>>.from(data['scheduledWorkouts']));
      }
      
      if (data.containsKey('aiChatHistory')) {
        await saveAIChatHistory((data['aiChatHistory'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList());
      }
      
      if (data.containsKey('userProfile')) {
        await saveUserProfile(Map<String, dynamic>.from(data['userProfile']));
      }
      
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  /// Forces a fresh reload of workout history with optional error handling
  Future<List<WorkoutSession>> refreshWorkoutHistory() async {
    try {
      // Clear the cache to ensure fresh data
      clearWorkoutHistoryCache();

      // Force reload from storage
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_workoutHistoryKey);

      if (jsonString == null) {
        _workoutHistoryCache = [];
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      _workoutHistoryCache = jsonList.map((json) => WorkoutSession.fromJson(json)).toList();

      return _workoutHistoryCache!;
    } catch (e) {
      debugPrint('Error refreshing workout history: $e');
      // Return cached data if available, empty list otherwise
      return _workoutHistoryCache ?? [];
    }
  }

  /// Refreshes user stats and returns updated statistics
  Future<Map<String, dynamic>> refreshWorkoutStats() async {
    try {
      final history = await refreshWorkoutHistory();
      return await getWorkoutStats();
    } catch (e) {
      debugPrint('Error refreshing workout stats: $e');
      // Return basic stats if refresh fails
      return {
        'totalWorkouts': 0,
        'totalDuration': 0,
        'totalCalories': 0,
        'streakDays': 0,
        'favoriteWorkout': null,
        'averageFormScore': 0.0,
      };
    }
  }

  /// Validates data integrity during refresh operations
  Future<bool> validateDataIntegrity() async {
    try {
      final history = await getWorkoutHistory();
      final preferences = await getUserPreferences();
      final profile = await getUserProfile();

      // Basic validation checks
      bool isValid = true;

      // Check if workout history is properly formatted
      for (final session in history) {
        if (session.plan.name.isEmpty || session.startTime == null) {
          isValid = false;
          break;
        }
      }

      // Check if essential preferences exist
      if (!preferences.containsKey('theme') || !preferences.containsKey('notifications')) {
        isValid = false;
      }

      // Check if profile has essential fields
      if (!profile.containsKey('name') || !profile.containsKey('joinDate')) {
        isValid = false;
      }

      return isValid;
    } catch (e) {
      debugPrint('Error validating data integrity: $e');
      return false;
    }
  }

  /// Performs a comprehensive refresh of all app data
  Future<Map<String, dynamic>> performComprehensiveRefresh() async {
    final Map<String, dynamic> refreshResults = {
      'success': false,
      'workoutHistoryUpdated': false,
      'preferencesUpdated': false,
      'profileUpdated': false,
      'errors': <String>[],
      'timestamp': DateTime.now(),
    };

    try {
      // Refresh workout history
      try {
        await refreshWorkoutHistory();
        refreshResults['workoutHistoryUpdated'] = true;
      } catch (e) {
        refreshResults['errors'].add('Failed to refresh workout history: $e');
      }

      // Validate data integrity
      final isDataValid = await validateDataIntegrity();
      if (!isDataValid) {
        refreshResults['errors'].add('Data integrity validation failed');
      }

      // If no critical errors, mark as successful
      refreshResults['success'] = refreshResults['errors'].isEmpty;

      return refreshResults;
    } catch (e) {
      refreshResults['errors'].add('Comprehensive refresh failed: $e');
      return refreshResults;
    }
  }

  /// Gets the last refresh timestamp for UI feedback
  Future<DateTime?> getLastRefreshTimestamp() async {
    final prefs = await _getPrefs();
    final timestampString = prefs.getString('last_refresh_timestamp');
    if (timestampString != null) {
      return DateTime.tryParse(timestampString);
    }
    return null;
  }

  /// Updates the last refresh timestamp
  Future<void> updateLastRefreshTimestamp() async {
    final prefs = await _getPrefs();
    await prefs.setString('last_refresh_timestamp', DateTime.now().toIso8601String());
  }
} 