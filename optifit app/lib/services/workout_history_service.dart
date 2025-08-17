import '../models/workout_models.dart';
import 'data_service.dart';

class WorkoutHistoryService {
  static final WorkoutHistoryService _instance = WorkoutHistoryService._internal();
  factory WorkoutHistoryService() => _instance;
  WorkoutHistoryService._internal();

  List<WorkoutSession> _workoutHistory = [];
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _workoutHistory = await DataService().getWorkoutHistory();
      _initialized = true;
    }
  }

  // Save a completed workout session
  Future<void> saveWorkout(WorkoutSession session) async {
    await init();
    _workoutHistory.add(session);
    await DataService().saveWorkoutHistory(_workoutHistory);
    print('Workout saved: ${session.plan.name} - ${session.duration.inMinutes} minutes');
  }

  // Get all saved workout sessions
  List<WorkoutSession> getWorkoutHistory() {
    return List.from(_workoutHistory);
  }

  // Get recent workouts (last 10)
  List<WorkoutSession> getRecentWorkouts() {
    final sorted = List<WorkoutSession>.from(_workoutHistory)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(10).toList();
  }

  // Get workout statistics
  Map<String, dynamic> getWorkoutStats() {
    if (_workoutHistory.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalMinutes': 0,
        'totalSets': 0,
        'averageCompletionRate': 0.0,
      };
    }

    final totalWorkouts = _workoutHistory.length;
    final totalMinutes = _workoutHistory.fold(0, (sum, session) => sum + session.duration.inMinutes);
    final totalSets = _workoutHistory.fold(0, (sum, session) => sum + session.completedSets);
    final totalPossibleSets = _workoutHistory.fold(0, (sum, session) => sum + session.totalSets);
    final averageCompletionRate = totalPossibleSets > 0 ? (totalSets / totalPossibleSets * 100) : 0.0;

    return {
      'totalWorkouts': totalWorkouts,
      'totalMinutes': totalMinutes,
      'totalSets': totalSets,
      'averageCompletionRate': averageCompletionRate.round(),
    };
  }

  // Clear all workout history (for testing)
  Future<void> clearHistory() async {
    _workoutHistory.clear();
    await DataService().saveWorkoutHistory(_workoutHistory);
  }

  // Add a public setter for the in-memory workout history
  void setWorkoutHistory(List<WorkoutSession> sessions) {
    _workoutHistory = List.from(sessions);
  }
} 