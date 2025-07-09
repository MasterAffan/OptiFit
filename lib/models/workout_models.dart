import 'package:flutter/material.dart';

// Helper function to get constant IconData instances
IconData _getIconData(int codePoint) {
  // Map common icon code points to their constant Icons instances
  switch (codePoint) {
    case 57997: // fitness_center
      return Icons.fitness_center;
    case 57820: // directions_run
      return Icons.directions_run;
    case 57405: // accessibility_new
      return Icons.accessibility_new;
    case 58735: // self_improvement
      return Icons.self_improvement;
    case 58003: // flash_on
      return Icons.flash_on;
    case 57947: // favorite
      return Icons.favorite;
    case 57582: // bolt
      return Icons.bolt;
    case 58978: // timer
      return Icons.timer;
    case 58655: // repeat
      return Icons.repeat;
    case 58258: // local_fire_department
      return Icons.local_fire_department;
    case 57689: // check_circle
      return Icons.check_circle;
    case 58813: // skip_next
      return Icons.skip_next;
    case 57673: // celebration
      return Icons.celebration;
    case 58971: // thumb_up
      return Icons.thumb_up;
    case 59007: // trending_up
      return Icons.trending_up;
    case 58607: // psychology
      return Icons.psychology;
    case 58710: // schedule
      return Icons.schedule;
    case 58571: // play_arrow
      return Icons.play_arrow;
    case 62442: // stop_outlined
      return Icons.stop_outlined;
    case 57706: // close
      return Icons.close;
    case 58572: // play_circle
      return Icons.play_circle;
    case 61267: // circle_outlined
      return Icons.circle_outlined;
    case 57686: // check
      return Icons.check;
    case 57490: // arrow_back
      return Icons.arrow_back;
    case 58771: // share
      return Icons.share;
    case 58136: // home
      return Icons.home;
    case 57925: // expand_less
      return Icons.expand_less;
    case 57926: // expand_more
      return Icons.expand_more;
    case 57415: // add
      return Icons.add;
    case 58132: // history
      return Icons.history;
    case 57402: // access_time
      return Icons.access_time;
    case 58873: // star
      return Icons.star;
    default:
      // For any other icon, return a default icon
      return Icons.fitness_center;
  }
}

class Exercise {
  final String name;
  final int sets;
  final String reps;
  final String rest;
  final IconData icon;
  final String? instructions;
  final String? targetMuscles;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.icon,
    this.instructions,
    this.targetMuscles,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'rest': rest,
      'icon': icon.codePoint,
      'instructions': instructions,
      'targetMuscles': targetMuscles,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      rest: json['rest'],
      icon: _getIconData(json['icon']),
      instructions: json['instructions'],
      targetMuscles: json['targetMuscles'],
    );
  }
}

class WorkoutSet {
  final int setNumber;
  final String reps;
  final bool isCompleted;
  final bool isSkipped;
  final Duration? restTime;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    this.isCompleted = false,
    this.isSkipped = false,
    this.restTime,
  });

  WorkoutSet copyWith({
    int? setNumber,
    String? reps,
    bool? isCompleted,
    bool? isSkipped,
    Duration? restTime,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      isSkipped: isSkipped ?? this.isSkipped,
      restTime: restTime ?? this.restTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'isCompleted': isCompleted,
      'isSkipped': isSkipped,
      'restTime': restTime?.inSeconds,
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setNumber: json['setNumber'],
      reps: json['reps'],
      isCompleted: json['isCompleted'] ?? false,
      isSkipped: json['isSkipped'] ?? false,
      restTime: json['restTime'] != null
          ? Duration(seconds: json['restTime'])
          : null,
    );
  }
}

class WorkoutExercise {
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final bool isCompleted;

  WorkoutExercise({
    required this.exercise,
    required this.sets,
    this.isCompleted = false,
  });

  WorkoutExercise copyWith({
    Exercise? exercise,
    List<WorkoutSet>? sets,
    bool? isCompleted,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets.map((set) => set.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: (json['sets'] as List)
          .map((set) => WorkoutSet.fromJson(set))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class WorkoutPlan {
  final String name;
  final String duration;
  final int exerciseCount;
  final String difficulty;
  final IconData icon;
  final Color color;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.name,
    required this.duration,
    required this.exerciseCount,
    required this.difficulty,
    required this.icon,
    required this.color,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration': duration,
      'exerciseCount': exerciseCount,
      'difficulty': difficulty,
      'icon': icon.codePoint,
      'color': color.toARGB32(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      name: json['name'],
      duration: json['duration'],
      exerciseCount: json['exerciseCount'],
      difficulty: json['difficulty'],
      icon: _getIconData(json['icon']),
      color: Color(json['color']),
      exercises: (json['exercises'] as List)
          .map((exercise) => Exercise.fromJson(exercise))
          .toList(),
    );
  }
}

class WorkoutSession {
  final WorkoutPlan plan;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final bool isActive;
  final int? caloriesBurned;
  final double? averageFormScore;

  WorkoutSession({
    required this.plan,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.isActive = false,
    this.caloriesBurned,
    this.averageFormScore,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  int get completedExercises {
    return exercises.where((e) => e.isCompleted).length;
  }

  int get totalSets {
    return exercises.fold(0, (sum, e) => sum + e.sets.length);
  }

  int get completedSets {
    return exercises.fold(
      0,
      (sum, e) => sum + e.sets.where((s) => s.isCompleted).length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'isActive': isActive,
      'caloriesBurned': caloriesBurned,
      'averageFormScore': averageFormScore,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      plan: WorkoutPlan.fromJson(json['plan']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      exercises: (json['exercises'] as List)
          .map((exercise) => WorkoutExercise.fromJson(exercise))
          .toList(),
      isActive: json['isActive'] ?? false,
      caloriesBurned: json['caloriesBurned'],
      averageFormScore: json['averageFormScore']?.toDouble(),
    );
  }
}
