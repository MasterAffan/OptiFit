import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_models.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static const String _scheduledWorkoutsKey = 'scheduledWorkouts_v2';
  static const String _notificationSettingsKey = 'notificationSettings';

  final NotificationService _notificationService = NotificationService();

  Future<Map<String, List<ScheduledWorkout>>> getScheduledWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_scheduledWorkoutsKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        final Map<String, List<ScheduledWorkout>> result = {};

        decoded.forEach((dateKey, workoutsList) {
          result[dateKey] = (workoutsList as List)
              .map((workoutJson) => ScheduledWorkout.fromJson(workoutJson))
              .toList();
        });

        return result;
      } catch (e) {
        // If decoding fails, return empty map
        return {};
      }
    }

    return {};
  }

  Future<void> saveScheduledWorkouts(Map<String, List<ScheduledWorkout>> workouts) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> toSave = {};
    workouts.forEach((dateKey, workoutsList) {
      toSave[dateKey] = workoutsList.map((workout) => workout.toJson()).toList();
    });

    final jsonString = json.encode(toSave);
    await prefs.setString(_scheduledWorkoutsKey, jsonString);
  }

  Future<void> scheduleWorkout({
    required String workoutName,
    required String time,
    required DateTime date,
    required Color color,
    bool notificationsEnabled = true,
  }) async {
    final dateKey = _getDateKey(date);
    final scheduledWorkout = ScheduledWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workout: workoutName,
      time: time,
      scheduledDate: date,
      color: color,
      notificationsEnabled: notificationsEnabled,
      createdAt: DateTime.now(),
    );

    final currentWorkouts = await getScheduledWorkouts();

    if (currentWorkouts.containsKey(dateKey)) {
      currentWorkouts[dateKey]!.add(scheduledWorkout);
    } else {
      currentWorkouts[dateKey] = [scheduledWorkout];
    }

    await saveScheduledWorkouts(currentWorkouts);

    // Schedule notifications if enabled
    if (notificationsEnabled) {
      final workoutIndex = currentWorkouts[dateKey]!.length - 1;
      await _notificationService.scheduleWorkoutNotifications(
        workoutName: workoutName,
        scheduledTime: scheduledWorkout.fullScheduledDateTime,
        dateKey: dateKey,
        workoutIndex: workoutIndex,
      );
    }
  }

  Future<void> deleteScheduledWorkout(String dateKey, int workoutIndex) async {
    // Cancel notifications first
    await _notificationService.cancelWorkoutNotifications(dateKey, workoutIndex);

    final currentWorkouts = await getScheduledWorkouts();

    if (currentWorkouts.containsKey(dateKey) &&
        workoutIndex < currentWorkouts[dateKey]!.length) {
      currentWorkouts[dateKey]!.removeAt(workoutIndex);

      if (currentWorkouts[dateKey]!.isEmpty) {
        currentWorkouts.remove(dateKey);
      }

      await saveScheduledWorkouts(currentWorkouts);
    }
  }

  Future<void> updateWorkoutNotifications(String dateKey, int workoutIndex, bool enabled) async {
    final currentWorkouts = await getScheduledWorkouts();

    if (currentWorkouts.containsKey(dateKey) &&
        workoutIndex < currentWorkouts[dateKey]!.length) {
      final workout = currentWorkouts[dateKey]![workoutIndex];
      final updatedWorkout = workout.copyWith(notificationsEnabled: enabled);

      currentWorkouts[dateKey]![workoutIndex] = updatedWorkout;
      await saveScheduledWorkouts(currentWorkouts);

      if (enabled) {
        // Schedule notifications
        await _notificationService.scheduleWorkoutNotifications(
          workoutName: workout.workout,
          scheduledTime: workout.fullScheduledDateTime,
          dateKey: dateKey,
          workoutIndex: workoutIndex,
        );
      } else {
        // Cancel notifications
        await _notificationService.cancelWorkoutNotifications(dateKey, workoutIndex);
      }
    }
  }

  Future<List<ScheduledWorkout>> getTodaysWorkouts() async {
    final today = DateTime.now();
    final dateKey = _getDateKey(today);
    final allWorkouts = await getScheduledWorkouts();
    return allWorkouts[dateKey] ?? [];
  }

  Future<List<ScheduledWorkout>> getUpcomingWorkouts({int days = 7}) async {
    final allWorkouts = await getScheduledWorkouts();
    final upcomingWorkouts = <ScheduledWorkout>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      final dateKey = _getDateKey(date);

      if (allWorkouts.containsKey(dateKey)) {
        final dayWorkouts = allWorkouts[dateKey]!
            .where((workout) => workout.isUpcoming)
            .toList();
        upcomingWorkouts.addAll(dayWorkouts);
      }
    }

    // Sort by scheduled time
    upcomingWorkouts.sort((a, b) =>
        a.fullScheduledDateTime.compareTo(b.fullScheduledDateTime));

    return upcomingWorkouts;
  }

  Future<NotificationSettings> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notificationSettingsKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return NotificationSettings.fromJson(json);
      } catch (e) {
        return NotificationSettings();
      }
    }

    return NotificationSettings();
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(settings.toJson());
    await prefs.setString(_notificationSettingsKey, jsonString);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Migration method to convert old format to new format
  Future<void> migrateOldScheduleFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final oldData = prefs.getString('scheduledWorkouts');

    if (oldData != null && !prefs.containsKey(_scheduledWorkoutsKey)) {
      try {
        final Map<String, dynamic> oldWorkouts = json.decode(oldData);
        final Map<String, List<ScheduledWorkout>> newWorkouts = {};

        oldWorkouts.forEach((dateKey, workoutsList) {
          final List<ScheduledWorkout> convertedWorkouts = [];

          for (var workout in workoutsList) {
            final scheduledWorkout = ScheduledWorkout(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              workout: workout['workout'],
              time: workout['time'],
              scheduledDate: DateTime.parse(dateKey),
              color: Color(workout['color']),
              notificationsEnabled: true,
              createdAt: DateTime.now(),
            );
            convertedWorkouts.add(scheduledWorkout);
          }

          newWorkouts[dateKey] = convertedWorkouts;
        });

        await saveScheduledWorkouts(newWorkouts);

        // Remove old data
        await prefs.remove('scheduledWorkouts');
      } catch (e) {
        // Migration failed, continue with empty schedule
      }
    }
  }
}
