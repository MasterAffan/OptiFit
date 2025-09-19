# Enhanced Data Service Extensions for Pull-to-Refresh Support

```dart
// Add these methods to the existing DataService class in data_service.dart

// Enhanced refresh functionality for better pull-to-refresh support
class DataService {
  // ... existing code ...

  // Add refresh-specific methods to force fresh data loading
  
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
  
  // ... rest of existing DataService code ...
}
```

## Additional Helper Class for Progress Charts Refresh

```dart
// Create a new file: lib/utils/progress_refresh_helper.dart

import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/workout_models.dart';

class ProgressRefreshHelper {
  static Future<Map<String, dynamic>> refreshProgressData({
    required int selectedPeriod,
    required List<String> periods,
  }) async {
    try {
      // Get fresh workout history
      final history = await DataService().refreshWorkoutHistory();
      
      // Calculate fresh stats
      final stats = _calculateStatsForPeriod(history, selectedPeriod);
      
      // Get chart data
      final chartData = _getChartDataForPeriod(history, selectedPeriod);
      
      return {
        'success': true,
        'history': history,
        'stats': stats,
        'chartData': chartData,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now(),
      };
    }
  }
  
  static Map<String, dynamic> _calculateStatsForPeriod(
    List<WorkoutSession> history, 
    int selectedPeriod
  ) {
    final now = DateTime.now();
    DateTime start;
    
    if (selectedPeriod == 0) {
      // This week (Monday to now)
      start = now.subtract(Duration(days: now.weekday - 1));
    } else if (selectedPeriod == 1) {
      // This month
      start = DateTime(now.year, now.month, 1);
    } else if (selectedPeriod == 2) {
      // Last 3 months
      start = DateTime(now.year, now.month - 2, 1);
    } else {
      // This year
      start = DateTime(now.year, 1, 1);
    }
    
    final filtered = history.where((s) => s.startTime.isAfter(start)).toList();
    int workouts = filtered.length;
    int calories = filtered.fold(0, (sum, s) => sum + (s.caloriesBurned ?? 0));
    int minutes = filtered.fold(0, (sum, s) => sum + s.duration.inMinutes);
    
    // Calculate streak
    int streak = 0;
    DateTime current = now;
    while (true) {
      final dayWorkouts = filtered
          .where((s) =>
              s.startTime.year == current.year &&
              s.startTime.month == current.month &&
              s.startTime.day == current.day)
          .toList();
      if (dayWorkouts.isEmpty) break;
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    
    return {
      'workouts': workouts,
      'calories': calories,
      'minutes': minutes,
      'streak': streak,
    };
  }
  
  static Map<String, dynamic> _getChartDataForPeriod(
    List<WorkoutSession> history, 
    int selectedPeriod
  ) {
    // Get workout frequency data for charts
    final now = DateTime.now();
    List<int> weekCounts = [];
    
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final count = history
          .where((s) =>
              s.startTime.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              s.startTime.isBefore(weekEnd.add(const Duration(days: 1))))
          .length;
      weekCounts.add(count);
    }
    
    return {
      'weekCounts': weekCounts,
      'maxWorkouts': weekCounts.isEmpty ? 1 : weekCounts.reduce((a, b) => a > b ? a : b),
      'labels': ['W1', 'W2', 'W3', 'W4'],
    };
  }
}
```

## Refresh Status Widget

```dart
// Create a new file: lib/widgets/refresh_status_widget.dart

import 'package:flutter/material.dart';
import '../theme/theme.dart';

class RefreshStatusWidget extends StatelessWidget {
  final bool isRefreshing;
  final String? error;
  final VoidCallback? onDismissError;
  final DateTime? lastRefresh;

  const RefreshStatusWidget({
    super.key,
    required this.isRefreshing,
    this.error,
    this.onDismissError,
    this.lastRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refresh Failed',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    error!,
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onDismissError != null)
              IconButton(
                onPressed: onDismissError,
                icon: Icon(Icons.close, color: AppTheme.error, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      );
    }

    if (isRefreshing) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Refreshing data...',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (lastRefresh != null) {
      final timeDiff = DateTime.now().difference(lastRefresh!).inMinutes;
      String timeText;
      if (timeDiff < 1) {
        timeText = 'Just now';
      } else if (timeDiff < 60) {
        timeText = '${timeDiff}m ago';
      } else {
        final hours = timeDiff ~/ 60;
        timeText = '${hours}h ago';
      }

      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 16),
            const SizedBox(width: 6),
            Text(
              'Updated $timeText',
              style: TextStyle(
                color: AppTheme.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
```

## Usage Instructions

1. **Replace** the existing `progress_screen.dart` with the updated version [5]
2. **Replace** the existing `workouts_screen.dart` with the updated version [6] 
3. **Add** the enhanced DataService methods to your existing `data_service.dart`
4. **Create** the helper files `progress_refresh_helper.dart` and `refresh_status_widget.dart`

## Key Features Implemented:

### ✅ RefreshIndicator Widget
- Added to both Progress and Workouts screens
- Custom styling with app theme colors
- Proper physics for smooth pull-to-refresh experience

### ✅ Refresh Logic for Workout History
- Comprehensive data refresh functionality  
- Cache clearing to ensure fresh data
- Proper error handling and recovery

### ✅ Refresh for Progress Charts
- Chart data is refreshed alongside workout history
- Period-specific data recalculation
- Updated AI insights after refresh

### ✅ Loading Indicators During Refresh
- Header progress indicators
- Status banners with refresh state
- Smooth loading transitions

### ✅ Graceful Error Handling
- Dismissible error banners
- User-friendly error messages
- Fallback to cached data when possible
- Success/failure feedback via SnackBars

The implementation provides a robust pull-to-refresh experience that enhances user engagement and ensures data freshness across both workout history and progress tracking screens.