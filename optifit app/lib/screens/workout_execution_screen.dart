import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../models/workout_models.dart';
import '../widgets/app_button.dart';
import '../utils/ticker.dart';
import 'workout_details_screen.dart';
import '../services/workout_history_service.dart';
import 'workouts_screen.dart';
import '../main.dart';
import '../widgets/custom_snackbar.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final VoidCallback? onWorkoutSaved;

  const WorkoutExecutionScreen({
    super.key,
    required this.workoutPlan,
    this.onWorkoutSaved,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  late WorkoutSession _session;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  bool _isResting = false;
  Duration _restTimer = Duration.zero;
  late final Ticker _ticker;
  bool _justCompletedLastSet = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _ticker = Ticker(_onTick);
  }

  void _initializeSession() {
    final exercises = widget.workoutPlan.exercises.map((exercise) {
      final sets = List.generate(
        exercise.sets,
        (index) => WorkoutSet(setNumber: index + 1, reps: exercise.reps),
      );
      return WorkoutExercise(exercise: exercise, sets: sets);
    }).toList();

    _session = WorkoutSession(
      plan: widget.workoutPlan,
      startTime: DateTime.now(),
      exercises: exercises,
      isActive: true,
    );
  }

  void _onTick(Duration elapsed) {
    if (_isResting) {
      setState(() {
        _restTimer = elapsed;
      });
    }
  }

  WorkoutExercise get _currentExercise =>
      _session.exercises[_currentExerciseIndex];
  WorkoutSet get _currentSet => _currentExercise.sets[_currentSetIndex];
  bool get _isLastExercise =>
      _currentExerciseIndex == _session.exercises.length - 1;
  bool get _isLastSet => _currentSetIndex == _currentExercise.sets.length - 1;

  void _completeSet() {
    setState(() {
      final updatedSets = List<WorkoutSet>.from(_currentExercise.sets);
      updatedSets[_currentSetIndex] = _currentSet.copyWith(isCompleted: true);

      final updatedExercises = List<WorkoutExercise>.from(_session.exercises);
      updatedExercises[_currentExerciseIndex] = _currentExercise.copyWith(
        sets: updatedSets,
      );

      _session = WorkoutSession(
        plan: _session.plan,
        startTime: _session.startTime,
        exercises: updatedExercises,
        isActive: _session.isActive,
      );
    });

    _moveToNextSet();
  }

  void _skipSet() {
    setState(() {
      final updatedSets = List<WorkoutSet>.from(_currentExercise.sets);
      updatedSets[_currentSetIndex] = _currentSet.copyWith(isSkipped: true);

      final updatedExercises = List<WorkoutExercise>.from(_session.exercises);
      updatedExercises[_currentExerciseIndex] = _currentExercise.copyWith(
        sets: updatedSets,
      );

      _session = WorkoutSession(
        plan: _session.plan,
        startTime: _session.startTime,
        exercises: updatedExercises,
        isActive: _session.isActive,
      );
    });

    _moveToNextSet();
  }

  void _moveToNextSet() {
    _justCompletedLastSet = _isLastSet;

    _startRest();
  }

  void _completeExercise() {
    setState(() {
      final updatedExercises = List<WorkoutExercise>.from(_session.exercises);
      updatedExercises[_currentExerciseIndex] = _currentExercise.copyWith(
        isCompleted: true,
      );

      _session = WorkoutSession(
        plan: _session.plan,
        startTime: _session.startTime,
        exercises: updatedExercises,
        isActive: _session.isActive,
      );
    });

    if (_isLastExercise) {
      _finishWorkout();
    } else {
      _moveToNextExercise();
    }
  }

  void _moveToNextExercise() {
    setState(() {
      _currentExerciseIndex++;
      _currentSetIndex = 0;
      _justCompletedLastSet = false;
    });
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _restTimer = Duration.zero;
      if (!_justCompletedLastSet) {
        _currentSetIndex++;
      }
    });
    _ticker.start();

    final restDuration = _parseRestDuration(_currentExercise.exercise.rest);
    Future.delayed(restDuration, () {
      if (mounted && _isResting) {
        _endRest();
      }
    });
  }

  void _endRest() {
    setState(() {
      _isResting = false;
      _restTimer = Duration.zero;
    });
    _ticker.stop();

    if (_justCompletedLastSet) {
      _completeExercise();
    }
  }

  Duration _parseRestDuration(String rest) {
    if (rest.contains('s')) {
      final seconds = int.tryParse(rest.replaceAll('s', '')) ?? 60;
      return Duration(seconds: seconds);
    }
    return const Duration(seconds: 60);
  }

  void _finishWorkout() {
    final endTime = DateTime.now();
    final int caloriesBurned = _estimateCaloriesBurned();
    final completedSession = WorkoutSession(
      plan: _session.plan,
      startTime: _session.startTime,
      endTime: endTime,
      exercises: _session.exercises,
      isActive: false,
      caloriesBurned: caloriesBurned,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WorkoutCompletionDialog(
        session: completedSession,
        onWorkoutSaved: widget.onWorkoutSaved,
      ),
    );
  }

  int _estimateCaloriesBurned() {
    // 5 kcal per completed set
    int totalSets = 0;
    for (final exercise in _session.exercises) {
      totalSets += exercise.sets.where((s) => s.isCompleted).length;
    }
    return totalSets * 5;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.workoutPlan.name),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: _isResting ? _buildRestView() : _buildExerciseView(),
    );
  }

  Widget _buildExerciseView() {
    return Padding(
      padding: AppTheme.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 32),

          _buildExerciseInfo(),
          const SizedBox(height: 32),

          _buildSetProgress(),
          const SizedBox(height: 32),

          _buildActionButtons(),
          const SizedBox(height: 24),

          Expanded(child: _buildExerciseList()),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentExerciseIndex + 1) / _session.exercises.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercise ${_currentExerciseIndex + 1} of ${_session.exercises.length}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.divider,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildExerciseInfo() {
    return Container(
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.workoutPlan.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentExercise.exercise.icon,
                  color: widget.workoutPlan.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentExercise.exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set ${_currentSetIndex + 1} of ${_currentExercise.sets.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.repeat,
                label: 'Target',
                value: _currentExercise.exercise.reps,
              ),
              const SizedBox(width: 16),
              _InfoChip(
                icon: Icons.timer,
                label: 'Rest',
                value: _currentExercise.exercise.rest,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Progress',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: _currentExercise.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            final isCurrent = index == _currentSetIndex;
            final isCompleted = set.isCompleted;
            final isSkipped = set.isSkipped;

            Color color;
            IconData icon;
            if (isCompleted) {
              color = AppTheme.success;
              icon = Icons.check_circle;
            } else if (isSkipped) {
              color = AppTheme.warning;
              icon = Icons.skip_next;
            } else if (isCurrent) {
              color = AppTheme.primary;
              icon = Icons.play_circle;
            } else {
              color = AppTheme.divider;
              icon = Icons.circle_outlined;
            }

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index < _currentExercise.sets.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      'Set ${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Skip Set',
            icon: Icons.skip_next,
            onPressed: _skipSet,
            variant: AppButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppButton(
            text: 'Complete Set',
            icon: Icons.check,
            onPressed: _completeSet,
            variant: AppButtonVariant.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppTheme.cardPadding,
            child: Text(
              'Workout Plan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _session.exercises.length,
              itemBuilder: (context, index) {
                final exercise = _session.exercises[index];
                final isCurrent = index == _currentExerciseIndex;
                final isCompleted = exercise.isCompleted;
                final isPast = index < _currentExerciseIndex;

                return _ExerciseListItem(
                  exercise: exercise,
                  index: index + 1,
                  isCurrent: isCurrent,
                  isCompleted: isCompleted,
                  isPast: isPast,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestView() {
    final restDuration = _parseRestDuration(_currentExercise.exercise.rest);
    final remaining = restDuration - _restTimer;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);

    String nextExerciseName;
    String nextSetInfo;

    if (_justCompletedLastSet) {
      // Last set of current exercise, show next exercise
      if (_isLastExercise) {
        nextExerciseName = 'Workout Complete!';
        nextSetInfo = 'Great job!';
      } else {
        nextExerciseName =
            _session.exercises[_currentExerciseIndex + 1].exercise.name;
        nextSetInfo = 'Set 1';
      }
    } else {
      // Not last set, show next set of same exercise
      nextExerciseName = _currentExercise.exercise.name;
      nextSetInfo = 'Set ${_currentSetIndex + 1}';
    }

    return Center(
      child: Padding(
        padding: AppTheme.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rest Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Next: $nextExerciseName',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              nextSetInfo,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Skip Rest',
              icon: Icons.skip_next,
              onPressed: _endRest,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isCurrent;
  final bool isCompleted;
  final bool isPast;

  const _ExerciseListItem({
    required this.exercise,
    required this.index,
    required this.isCurrent,
    required this.isCompleted,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (isCompleted) {
      color = AppTheme.success;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      color = AppTheme.primary;
      icon = Icons.play_circle;
    } else if (isPast) {
      color = AppTheme.warning;
      icon = Icons.skip_next;
    } else {
      color = AppTheme.textSubtle;
      icon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withOpacity(0.05)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isCurrent ? AppTheme.primary : AppTheme.divider,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? AppTheme.primary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.sets.length} sets • ${exercise.exercise.reps} reps',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Text(
              '${exercise.sets.where((s) => s.isCompleted).length}/${exercise.sets.length}',
              style: TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutCompletionDialog extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback? onWorkoutSaved;

  const _WorkoutCompletionDialog({required this.session, this.onWorkoutSaved});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: AppTheme.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, size: 64, color: AppTheme.success),
            const SizedBox(height: 16),
            Text(
              'Workout Complete!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job completing ${session.plan.name}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _CompletionStat(
                    icon: Icons.timer,
                    value: '${session.duration.inMinutes}',
                    label: 'Minutes',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CompletionStat(
                    icon: Icons.fitness_center,
                    value: '${session.completedExercises}',
                    label: 'Exercises',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CompletionStat(
                    icon: Icons.repeat,
                    value: '${session.completedSets}',
                    label: 'Sets',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CompletionStat(
                    icon: Icons.local_fire_department,
                    value: '${session.caloriesBurned ?? 0}',
                    label: 'Calories',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Save & Exit',
                    onPressed: () async {
                      try {
                        final historyService = WorkoutHistoryService();
                        await historyService.saveWorkout(session);
                        if (onWorkoutSaved != null) onWorkoutSaved!();
                        showCustomSnackBar(
                          context,
                          message: 'Workout saved successfully!',
                          type: SnackBarType.success,
                        );
                      } catch (e) {
                        showCustomSnackBar(
                          context,
                          message: 'Failed to save workout: $e',
                          type: SnackBarType.error,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) =>
                                const MainScaffold(initialIndex: 1),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    variant: AppButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'View Details',
                    onPressed: () async {
                      try {
                        final historyService = WorkoutHistoryService();
                        await historyService.saveWorkout(session);
                        if (onWorkoutSaved != null) onWorkoutSaved!();
                        showCustomSnackBar(
                          context,
                          message: 'Workout saved successfully!',
                          type: SnackBarType.success,
                        );
                      } catch (e) {
                        showCustomSnackBar(
                          context,
                          message: 'Failed to save workout: $e',
                          type: SnackBarType.error,
                        );
                      }
                      Navigator.of(context).pop(); // Close dialog
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              WorkoutDetailsScreen(session: session),
                        ),
                      );
                      // If coming back from details, pop with result so parent can refresh
                      if (result == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    variant: AppButtonVariant.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CompletionStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
