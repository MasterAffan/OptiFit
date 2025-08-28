import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/app_button.dart';
import '../models/workout_models.dart';
import 'workout_execution_screen.dart';

class StartWorkoutScreen extends StatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  WorkoutPlan? selectedWorkout;
  
  final List<WorkoutPlan> workouts = [
    WorkoutPlan(
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
          instructions: 'Keep your body in a straight line from head to heels',
          targetMuscles: 'Chest, Triceps, Shoulders',
        ),
        Exercise(
          name: 'Pull-ups',
          sets: 3,
          reps: '8-10',
          rest: '90s',
          icon: Icons.fitness_center,
          instructions: 'Pull your chin above the bar with controlled movement',
          targetMuscles: 'Back, Biceps',
        ),
        Exercise(
          name: 'Dumbbell Rows',
          sets: 3,
          reps: '12-15',
          rest: '60s',
          icon: Icons.fitness_center,
          instructions: 'Keep your back straight and pull the weight to your hip',
          targetMuscles: 'Back, Biceps',
        ),
        Exercise(
          name: 'Shoulder Press',
          sets: 3,
          reps: '10-12',
          rest: '75s',
          icon: Icons.fitness_center,
          instructions: 'Press the weights overhead while keeping your core tight',
          targetMuscles: 'Shoulders, Triceps',
        ),
        Exercise(
          name: 'Bicep Curls',
          sets: 3,
          reps: '12-15',
          rest: '45s',
          icon: Icons.fitness_center,
          instructions: 'Keep your elbows close to your body throughout the movement',
          targetMuscles: 'Biceps',
        ),
        Exercise(
          name: 'Tricep Dips',
          sets: 3,
          reps: '10-12',
          rest: '60s',
          icon: Icons.fitness_center,
          instructions: 'Lower your body until your upper arms are parallel to the ground',
          targetMuscles: 'Triceps, Chest',
        ),
        Exercise(
          name: 'Plank',
          sets: 3,
          reps: '30s',
          rest: '45s',
          icon: Icons.accessibility_new,
          instructions: 'Hold your body in a straight line from head to heels',
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
    ),
    WorkoutPlan(
      name: 'Lower Body Power',
      duration: '50 min',
      exerciseCount: 6,
      difficulty: 'Advanced',
      icon: Icons.directions_run,
      color: AppTheme.success,
      exercises: [
        Exercise(
          name: 'Squats',
          sets: 4,
          reps: '12-15',
          rest: '90s',
          icon: Icons.fitness_center,
          instructions: 'Keep your chest up and knees behind your toes',
          targetMuscles: 'Quadriceps, Glutes, Hamstrings',
        ),
        Exercise(
          name: 'Deadlifts',
          sets: 3,
          reps: '8-10',
          rest: '120s',
          icon: Icons.fitness_center,
          instructions: 'Keep your back straight and lift with your legs',
          targetMuscles: 'Hamstrings, Glutes, Lower Back',
        ),
        Exercise(
          name: 'Lunges',
          sets: 3,
          reps: '10-12 each leg',
          rest: '60s',
          icon: Icons.fitness_center,
          instructions: 'Step forward and lower your back knee toward the ground',
          targetMuscles: 'Quadriceps, Glutes, Hamstrings',
        ),
        Exercise(
          name: 'Calf Raises',
          sets: 4,
          reps: '15-20',
          rest: '45s',
          icon: Icons.fitness_center,
          instructions: 'Raise your heels as high as possible',
          targetMuscles: 'Calves',
        ),
        Exercise(
          name: 'Glute Bridges',
          sets: 3,
          reps: '12-15',
          rest: '60s',
          icon: Icons.fitness_center,
          instructions: 'Lift your hips while squeezing your glutes',
          targetMuscles: 'Glutes, Hamstrings',
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
    ),
    WorkoutPlan(
      name: 'Full Body HIIT',
      duration: '30 min',
      exerciseCount: 10,
      difficulty: 'Beginner',
      icon: Icons.flash_on,
      color: AppTheme.warning,
      exercises: [
        Exercise(
          name: 'Jumping Jacks',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Jump while raising your arms overhead',
          targetMuscles: 'Full Body',
        ),
        Exercise(
          name: 'Mountain Climbers',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Alternate bringing your knees to your chest',
          targetMuscles: 'Core, Shoulders',
        ),
        Exercise(
          name: 'Burpees',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Squat, jump back to plank, jump forward, jump up',
          targetMuscles: 'Full Body',
        ),
        Exercise(
          name: 'High Knees',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Run in place while bringing your knees up high',
          targetMuscles: 'Legs, Core',
        ),
        Exercise(
          name: 'Push-ups',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Keep your body in a straight line',
          targetMuscles: 'Chest, Triceps, Shoulders',
        ),
        Exercise(
          name: 'Squats',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Keep your chest up and knees behind your toes',
          targetMuscles: 'Quadriceps, Glutes',
        ),
        Exercise(
          name: 'Plank',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.accessibility_new,
          instructions: 'Hold your body in a straight line',
          targetMuscles: 'Core, Shoulders',
        ),
        Exercise(
          name: 'Jump Rope',
          sets: 1,
          reps: '30s',
          rest: '15s',
          icon: Icons.fitness_center,
          instructions: 'Jump rope or simulate the motion',
          targetMuscles: 'Legs, Cardio',
        ),
        Exercise(
          name: 'Rest',
          sets: 1,
          reps: '60s',
          rest: '0s',
          icon: Icons.timer,
          instructions: 'Take a full minute to recover',
          targetMuscles: 'Recovery',
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
    ),
    WorkoutPlan(
      name: 'Core & Stability',
      duration: '25 min',
      exerciseCount: 7,
      difficulty: 'Beginner',
      icon: Icons.accessibility_new,
      color: AppTheme.secondary,
      exercises: [
        Exercise(
          name: 'Plank',
          sets: 3,
          reps: '30s',
          rest: '30s',
          icon: Icons.accessibility_new,
          instructions: 'Hold your body in a straight line from head to heels',
          targetMuscles: 'Core, Shoulders',
        ),
        Exercise(
          name: 'Side Plank',
          sets: 3,
          reps: '20s each side',
          rest: '30s',
          icon: Icons.accessibility_new,
          instructions: 'Hold your body in a straight line on your side',
          targetMuscles: 'Core, Obliques',
        ),
        Exercise(
          name: 'Bird Dog',
          sets: 3,
          reps: '10 each side',
          rest: '30s',
          icon: Icons.accessibility_new,
          instructions: 'Extend opposite arm and leg while keeping your core stable',
          targetMuscles: 'Core, Back',
        ),
        Exercise(
          name: 'Dead Bug',
          sets: 3,
          reps: '10 each side',
          rest: '30s',
          icon: Icons.accessibility_new,
          instructions: 'Lower opposite arm and leg while keeping your back flat',
          targetMuscles: 'Core',
        ),
        Exercise(
          name: 'Russian Twists',
          sets: 3,
          reps: '15 each side',
          rest: '30s',
          icon: Icons.accessibility_new,
          instructions: 'Rotate your torso from side to side',
          targetMuscles: 'Core, Obliques',
        ),
        Exercise(
          name: 'Superman',
          sets: 3,
          reps: '10',
          rest: '30s',
          icon: Icons.accessibility_new,
          instructions: 'Lift your chest and legs off the ground',
          targetMuscles: 'Back, Glutes',
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
    ),
    WorkoutPlan(
      name: 'Test',
      duration: '5 min',
      exerciseCount: 1,
      difficulty: 'Beginner',
      icon: Icons.bolt,
      color: Colors.grey,
      exercises: [
        Exercise(
          name: 'Test Exercise',
          sets: 1,
          reps: '1',
          rest: '0s',
          icon: Icons.bolt,
          instructions: 'Just a test exercise.',
          targetMuscles: 'Test',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Start Workout'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Choose Your Workout',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a workout plan to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            // Workout Selection
            Container(
              width: double.infinity,
              padding: AppTheme.cardPadding,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Workouts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...workouts.map((workout) => _WorkoutOption(
                        workout: workout,
                        isSelected: selectedWorkout?.name == workout.name,
                        onTap: () {
                          setState(() {
                            selectedWorkout = workout;
                          });
                        },
                      )),
                ],
              ),
            ),

            if (selectedWorkout != null) ...[
              const SizedBox(height: 24),
              // Exercise List
              Container(
                width: double.infinity,
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
                        Expanded(
                          child: Text(
                            'Exercise List',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedWorkout!.exercises.length} exercise',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...selectedWorkout!.exercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      return _ExerciseItem(
                        exercise: exercise,
                        index: index + 1,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Workout Summary
              Container(
                width: double.infinity,
                padding: AppTheme.cardPadding,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _SummaryItem(
                          icon: Icons.access_time,
                          label: 'Duration',
                          value: selectedWorkout!.duration,
                        ),
                        _SummaryItem(
                          icon: Icons.fitness_center,
                          label: 'Exercises',
                          value: '${selectedWorkout!.exercises.length}',
                        ),
                        _SummaryItem(
                          icon: Icons.trending_up,
                          label: 'Difficulty',
                          value: selectedWorkout!.difficulty,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // Start Button
              AppButton(
                text: 'Start Workout',
                icon: Icons.play_arrow,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutExecutionScreen(
                        workoutPlan: selectedWorkout!,
                      ),
                    ),
                  );
                },
                isFullWidth: true,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkoutOption extends StatelessWidget {
  final WorkoutPlan workout;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkoutOption({
    required this.workout,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int totalSets = workout.exercises.fold(0, (sum, e) => sum + e.sets);
    final int estimatedCalories = totalSets * 5;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: workout.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    workout.icon,
                    color: workout.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
                                workout.duration,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${workout.exercises.length} exercises',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$estimatedCalories cal',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(workout.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    workout.difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(workout.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _ExerciseItem extends StatelessWidget {
  final Exercise exercise;
  final int index;

  const _ExerciseItem({
    required this.exercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            exercise.icon,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 18,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${exercise.sets} sets',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Text(
                      '${exercise.reps} reps',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Text(
                      '${exercise.rest} rest',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textSubtle,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.primary,
            size: 19,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 