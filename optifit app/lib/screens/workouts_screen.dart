import 'package:flutter/material.dart';
import 'create_workout_screen.dart';
import '../services/custom_workout_service.dart';
import '../theme/theme.dart';
import '../models/workout_models.dart';
import 'workout_execution_screen.dart';
import '../services/workout_history_service.dart';
import 'workout_details_screen.dart';
import 'start_workout_screen.dart';
import '../services/data_service.dart';

class WorkoutsScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const WorkoutsScreen({super.key, this.onGoHome});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final CustomWorkoutService _customWorkoutService = CustomWorkoutService();
  List<WorkoutPlan> _customWorkouts = [];

  final List<String> categories = [
    'All',
    'Strength',
    'Cardio',
    'Yoga',
    'HIIT',
    'Calisthenics',
    'Custom',
  ];
  int selectedCategory = 0;
  bool allWorkoutsExpanded = false;
  List<WorkoutSession> _completedWorkouts = [];
  bool _loadingHistory = true;
  bool _isRefreshing = false;
  String? _refreshError;

  final List<Map<String, dynamic>> workouts = [
    {
      'name': 'Upper Body Strength',
      'duration': '45 min',
      'exercises': 8,
      'difficulty': 'Intermediate',
      'category': 'Strength',
      'icon': Icons.fitness_center,
      'color': AppTheme.primary,
      'calories': '320',
      'rating': 4.8,
    },
    {
      'name': 'Lower Body Power',
      'duration': '50 min',
      'exercises': 6,
      'difficulty': 'Advanced',
      'category': 'Strength',
      'icon': Icons.directions_run,
      'color': AppTheme.success,
      'calories': '380',
      'rating': 4.9,
    },
    {
      'name': 'Full Body HIIT',
      'duration': '30 min',
      'exercises': 10,
      'difficulty': 'Beginner',
      'category': 'HIIT',
      'icon': Icons.flash_on,
      'color': AppTheme.warning,
      'calories': '450',
      'rating': 4.7,
    },
    {
      'name': 'Core & Stability',
      'duration': '25 min',
      'exercises': 7,
      'difficulty': 'Beginner',
      'category': 'Calisthenics',
      'icon': Icons.accessibility_new,
      'color': AppTheme.secondary,
      'calories': '180',
      'rating': 4.6,
    },
    {
      'name': 'Cardio Blast',
      'duration': '40 min',
      'exercises': 5,
      'difficulty': 'Intermediate',
      'category': 'Cardio',
      'icon': Icons.favorite,
      'color': AppTheme.error,
      'calories': '520',
      'rating': 4.8,
    },
    {
      'name': 'Yoga Flow',
      'duration': '35 min',
      'exercises': 12,
      'difficulty': 'Beginner',
      'category': 'Yoga',
      'icon': Icons.self_improvement,
      'color': const Color(0xFF9C27B0),
      'calories': '150',
      'rating': 4.9,
    },
    {
      'name': 'Test',
      'duration': '5 min',
      'exercises': 1,
      'difficulty': 'Beginner',
      'category': 'Strength',
      'icon': Icons.bolt,
      'color': Colors.grey,
      'calories': '10',
      'rating': 5.0,
    },
  ];

  List<Map<String, dynamic>> get filteredWorkouts {
    final customWorkoutsAsMaps = _customWorkouts.map((e) => e.toMap()).toList();

    if (categories[selectedCategory] == 'Custom') {
      return customWorkoutsAsMaps;
    }

    // Use a Set to avoid duplicates if a workout name is the same
    final allWorkoutsMap = {
      for (var w in workouts) w['name']: w,
      for (var w in customWorkoutsAsMaps) w['name']: w,
    };
    final allWorkouts = allWorkoutsMap.values.toList();

    return selectedCategory == 0
        ? allWorkouts
        : allWorkouts
        .where(
          (workout) =>
      workout['category'] == categories[selectedCategory],
    )
        .toList();
  }

  // Get the corresponding WorkoutPlan for a workout card
  WorkoutPlan _getWorkoutPlan(String workoutName) {
    switch (workoutName) {
      case 'Upper Body Strength':
        return WorkoutPlan(
          name: 'Upper Body Strength',
          duration: '45 min',
          exerciseCount: 8,
          difficulty: 'Intermediate',
          icon: Icons.fitness_center,
          color: AppTheme.primary,
          exercises: [
            Exercise(
              name: 'Push-ups',
              sets: 3,
              reps: '10-12',
              rest: '60s',
              icon: Icons.fitness_center,
              instructions:
              'Keep your body in a straight line from head to heels',
              targetMuscles: 'Chest, Triceps, Shoulders',
            ),
            Exercise(
              name: 'Pull-ups',
              sets: 3,
              reps: '8-10',
              rest: '90s',
              icon: Icons.fitness_center,
              instructions:
              'Pull your chin above the bar with controlled movement',
              targetMuscles: 'Back, Biceps',
            ),
            Exercise(
              name: 'Dumbbell Rows',
              sets: 3,
              reps: '12-15',
              rest: '60s',
              icon: Icons.fitness_center,
              instructions:
              'Keep your back straight and pull the weight to your hip',
              targetMuscles: 'Back, Biceps',
            ),
            Exercise(
              name: 'Shoulder Press',
              sets: 3,
              reps: '10-12',
              rest: '75s',
              icon: Icons.fitness_center,
              instructions:
              'Press the weights overhead while keeping your core tight',
              targetMuscles: 'Shoulders, Triceps',
            ),
            Exercise(
              name: 'Bicep Curls',
              sets: 3,
              reps: '12-15',
              rest: '45s',
              icon: Icons.fitness_center,
              instructions:
              'Keep your elbows close to your body throughout the movement',
              targetMuscles: 'Biceps',
            ),
            Exercise(
              name: 'Tricep Dips',
              sets: 3,
              reps: '10-12',
              rest: '60s',
              icon: Icons.fitness_center,
              instructions:
              'Lower your body until your upper arms are parallel to the ground',
              targetMuscles: 'Triceps, Chest',
            ),
            Exercise(
              name: 'Plank',
              sets: 3,
              reps: '30s',
              rest: '45s',
              icon: Icons.accessibility_new,
              instructions:
              'Hold your body in a straight line from head to heels',
              targetMuscles: 'Core, Shoulders',
            ),
            Exercise(
              name: 'Cool Down',
              sets: 1,
              reps: '5 min',
              rest: '0s',
              icon: Icons.self_improvement,
              instructions: 'Gentle stretching and deep breathing',
              targetMuscles: 'Full Body',
            ),
          ],
        );
    // ... (other workout cases remain the same)
      default:
      // Return a default workout for any unmatched names
        return WorkoutPlan(
          name: workoutName,
          duration: '30 min',
          exerciseCount: 5,
          difficulty: 'Beginner',
          icon: Icons.fitness_center,
          color: AppTheme.primary,
          exercises: [
            Exercise(
              name: 'Push-ups',
              sets: 3,
              reps: '10-12',
              rest: '60s',
              icon: Icons.fitness_center,
              instructions:
              'Keep your body in a straight line from head to heels',
              targetMuscles: 'Chest, Triceps, Shoulders',
            ),
            Exercise(
              name: 'Squats',
              sets: 3,
              reps: '12-15',
              rest: '60s',
              icon: Icons.fitness_center,
              instructions: 'Keep your chest up and knees behind your toes',
              targetMuscles: 'Quadriceps, Glutes',
            ),
            Exercise(
              name: 'Plank',
              sets: 3,
              reps: '30s',
              rest: '45s',
              icon: Icons.accessibility_new,
              instructions:
              'Hold your body in a straight line from head to heels',
              targetMuscles: 'Core, Shoulders',
            ),
            Exercise(
              name: 'Cool Down',
              sets: 1,
              reps: '5 min',
              rest: '0s',
              icon: Icons.self_improvement,
              instructions: 'Gentle stretching and deep breathing',
              targetMuscles: 'Full Body',
            ),
          ],
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
    _loadCustomWorkouts();
  }

  Future<void> _loadCustomWorkouts() async {
    final workouts = await _customWorkoutService.getCustomWorkouts();
    setState(() {
      _customWorkouts = workouts;
    });
  }

  Future<void> _loadWorkoutHistory() async {
    final historyService = WorkoutHistoryService();
    await historyService.init();
    setState(() {
      _completedWorkouts = historyService.getWorkoutHistory().reversed.toList();
      _loadingHistory = false;
    });
  }

  // Add comprehensive refresh functionality
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isRefreshing = true;
      _refreshError = null;
      _loadingHistory = true;
    });

    try {
      // Clear data service cache to force fresh data
      DataService().clearWorkoutHistoryCache();

      // Reload both workout history and custom workouts
      await Future.wait([
        _loadWorkoutHistory(),
        _loadCustomWorkouts(),
      ]);

      // Add a small delay to show the loading indicator
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Workout history refreshed successfully'),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _refreshError = 'Failed to refresh workout data: ${e.toString()}';
        _loadingHistory = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(_refreshError!)),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Add this method to be called after a workout is saved
  void _onWorkoutSaved() async {
    setState(() {
      _loadingHistory = true;
    });
    await _loadWorkoutHistory();
  }

  Future<void> _deleteWorkout(WorkoutSession session) async {
    // Remove from UI immediately
    setState(() {
      _completedWorkouts = _completedWorkouts
          .where((s) => s.startTime != session.startTime)
          .toList();
    });
    final historyService = WorkoutHistoryService();
    await historyService.init();
    final updated = historyService
        .getWorkoutHistory()
        .where((s) => s.startTime != session.startTime)
        .toList();
    await DataService().saveWorkoutHistory(updated);
    historyService.setWorkoutHistory(updated);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedWorkouts = _completedWorkouts;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onGoHome,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primary,
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: AppTheme.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and filter icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Workouts',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  // Show refresh error if any
                  if (_refreshError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: AppTheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _refreshError!,
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _refreshError = null),
                            icon: Icon(Icons.close, color: AppTheme.error, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Collapsible All Workouts section
                  GestureDetector(
                    onTap: () => setState(
                          () => allWorkoutsExpanded = !allWorkoutsExpanded,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'All Workouts',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          allWorkoutsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    child: allWorkoutsExpanded
                        ? Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final isSelected = i == selectedCategory;
                              return ChoiceChip(
                                label: Text(
                                  categories[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => selectedCategory = i),
                                backgroundColor: AppTheme.chipBackground,
                                selectedColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.chipRadius,
                                  ),
                                ),
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.vertical,
                              child: child,
                            );
                          },
                          child: Column(
                            key: ValueKey(filteredWorkouts.length),
                            children: [
                              ...filteredWorkouts.map(
                                    (workout) => _WorkoutCard(
                                  key: ValueKey(workout['name']),
                                  workout: workout,
                                  onStartWorkout: () async {
                                    WorkoutPlan workoutPlan;
                                    if (workout['category'] == 'Custom') {
                                      // For custom workouts, find the plan from the list
                                      workoutPlan = _customWorkouts
                                          .firstWhere(
                                            (p) =>
                                        p.name == workout['name'],
                                      );
                                    } else {
                                      // For predefined workouts, use the existing method
                                      workoutPlan = _getWorkoutPlan(
                                        workout['name'],
                                      );
                                    }

                                    final result =
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WorkoutExecutionScreen(
                                              workoutPlan: workoutPlan,
                                              onWorkoutSaved:
                                              _onWorkoutSaved,
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      _onWorkoutSaved();
                                    }
                                  },
                                  onDelete: workout['category'] == 'Custom'
                                      ? () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Delete Workout',
                                        ),
                                        content: const Text(
                                          'Are you sure you want to delete this workout? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text(
                                              'Cancel',
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text(
                                              'Delete',
                                            ),
                                            style:
                                            TextButton.styleFrom(
                                              foregroundColor:
                                              AppTheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _customWorkoutService
                                          .deleteCustomWorkout(
                                        workout['name'],
                                      );
                                      _loadCustomWorkouts();
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Workout deleted successfully.',
                                            ),
                                            backgroundColor:
                                            AppTheme.success,
                                          ),
                                        );
                                    }
                                  }
                                      : null,
                                  onEdit: workout['category'] == 'Custom'
                                      ? () async {
                                    final workoutPlan =
                                    _customWorkouts.firstWhere(
                                          (p) =>
                                      p.name ==
                                          workout['name'],
                                    );
                                    final result =
                                    await Navigator.of(
                                      context,
                                    ).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateWorkoutScreen(
                                              isEditMode: true,
                                              workoutToEdit:
                                              workoutPlan,
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadCustomWorkouts();
                                    }
                                  }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // Your Workouts section
                  Text(
                    'Your Workouts',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const StartWorkoutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Start Working Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateWorkoutScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadCustomWorkouts();
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingHistory)
                    const Center(child: CircularProgressIndicator())
                  else if (completedWorkouts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: AppTheme.cardPadding,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppTheme.textSubtle,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workouts completed yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your completed workouts will appear here',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StartWorkoutScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.fitness_center),
                            label: Text('Start Workout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.buttonRadius,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: completedWorkouts
                          .map(
                            (session) => _CompletedWorkoutCard(
                          session: session,
                          onDelete: () async {
                            final confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Workout'),
                                content: const Text(
                                  'Are you sure you want to delete this workout from your history?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _deleteWorkout(session);
                            }
                          },
                        ),
                      )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Rest of the widget classes remain the same...
class _WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  final VoidCallback onStartWorkout;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Key? key;

  const _WorkoutCard({
    this.key,
    required this.workout,
    required this.onStartWorkout,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: workout['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(workout['icon'], color: workout['color'], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              workout['duration'],
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${workout['exercises']} exercises',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        workout['difficulty'],
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      workout['difficulty'],
                      style: TextStyle(
                        color: _getDifficultyColor(workout['difficulty']),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (onEdit != null)
                          IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit_outlined),
                            color: AppTheme.secondary,
                            onPressed: onEdit,
                            tooltip: 'Edit Workout',
                          ),
                        if (onDelete != null)
                          IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.error,
                            onPressed: onDelete,
                            tooltip: 'Delete Workout',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout['calories']} cal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: AppTheme.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${workout['rating']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onStartWorkout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppTheme.success;
      case 'intermediate':
        return AppTheme.warning;
      case 'advanced':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _CompletedWorkoutCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback? onDelete;
  const _CompletedWorkoutCard({required this.session, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: session.plan.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  session.plan.icon,
                  color: session.plan.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.plan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.duration.inMinutes} min • ${session.completedSets} sets',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.caloriesBurned ?? 0} cal',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.warning),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(session.startTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                color: AppTheme.primary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkoutDetailsScreen(session: session),
                    ),
                  );
                },
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.error,
                  onPressed: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}