import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_models.dart';

class CustomWorkoutService {
  // Singleton pattern
  static final CustomWorkoutService _instance =
      CustomWorkoutService._internal();
  factory CustomWorkoutService() {
    return _instance;
  }
  CustomWorkoutService._internal();

  static const String _storageKey = 'customWorkouts';

  Future<List<WorkoutPlan>> getCustomWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => WorkoutPlan.fromJson(json)).toList();
      } catch (e) {
        // If decoding fails, return an empty list
        if (kDebugMode) {
          print('Error decoding custom workouts: $e');
        }
        return [];
      }
    }
    return [];
  }

  Future<void> _saveToDisk(List<WorkoutPlan> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = workouts.map((workout) => workout.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  Future<void> saveCustomWorkout(WorkoutPlan workout) async {
    final workouts = await getCustomWorkouts();
    // Remove existing workout with the same name to avoid duplicates
    workouts.removeWhere((w) => w.name == workout.name);
    workouts.add(workout);
    await _saveToDisk(workouts);
  }

  Future<void> deleteCustomWorkout(String workoutName) async {
    final workouts = await getCustomWorkouts();
    workouts.removeWhere((workout) => workout.name == workoutName);
    await _saveToDisk(workouts);
  }
}
