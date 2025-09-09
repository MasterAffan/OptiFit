import 'dart:async';

import 'package:OptiFit/models/schedule_models.dart';
import 'package:OptiFit/services/schedule_service.dart';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/custom_time_picker.dart';
import '../services/notification_service.dart';
import 'workout_execution_screen.dart';
import '../models/workout_models.dart';
import '../services/custom_workout_service.dart';

class ScheduleScreen extends StatefulWidget {
  static const String routeName = '/schedule';
  final Map<String, dynamic>? notificationData; // Keep for potential future use
  const ScheduleScreen({super.key, this.notificationData});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  StreamSubscription? _notificationSubscription;
  int _selectedHour = 6;
  int _selectedMinute = 0;
  String _selectedPeriod = 'AM';

  // --- REFACTORED: Use the ScheduleService ---
  final ScheduleService _scheduleService = ScheduleService();
  final CustomWorkoutService _customWorkoutService = CustomWorkoutService();
  Map<String, List<ScheduledWorkout>> scheduledWorkouts = {};
  // --- END REFACTOR ---

  String? _highlightedWorkoutKey;
  bool _permissionsGranted = false;

  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  String? selectedWorkout;

  final List<Map<String, dynamic>> workouts = [
    {
      'name': 'Upper Body Strength',
      'duration': '45 min',
      'icon': Icons.fitness_center,
      'color': AppTheme.primary,
    },
    {
      'name': 'Lower Body Power',
      'duration': '50 min',
      'icon': Icons.directions_run,
      'color': AppTheme.success,
    },
    {
      'name': 'Full Body HIIT',
      'duration': '30 min',
      'icon': Icons.flash_on,
      'color': AppTheme.warning,
    },
    {
      'name': 'Core & Stability',
      'duration': '25 min',
      'icon': Icons.accessibility_new,
      'color': AppTheme.secondary,
    },
    {
      'name': 'Cardio Session',
      'duration': '40 min',
      'icon': Icons.favorite,
      'color': AppTheme.error,
    },
  ];

  // In schedule_screen.dart

  @override
  @override
  void initState() {
    super.initState();
    print('DEBUG: ScheduleScreen initState');

    // --- THIS IS THE CRITICAL LOGIC ---
    // Path 1: Handles data when the screen is the FIRST one built (from a notification cold start).
    if (widget.notificationData != null) {
      // This callback ensures the dialog is shown after the screen is fully built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('DEBUG: Handling notificationData from constructor: ${widget.notificationData}');
        _handleNotificationTap(widget.notificationData!);
      });
    }

    // Path 2: Handles notifications tapped while the app is already open.
    _notificationSubscription = notificationPayloadStream.stream.listen((payload) {
      print('DEBUG: Handling notification from stream: $payload');
      if (mounted) {
        _handleNotificationTap(payload);
      }
    });
    // --- END CRITICAL LOGIC ---


    // The rest of your existing initialization logic
    final now = TimeOfDay.now();
    _selectedHour = (now.hour == 0 || now.hour > 12) ? (now.hour - 12) : (now.hour == 0 ? 12 : now.hour);
    _selectedMinute = now.minute;
    _selectedPeriod = now.hour >= 12 ? 'PM' : 'AM';
    _updateSelectedTimeSlot();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    // Check permissions first
    final granted = await NotificationService().requestPermissions();
    setState(() {
      _permissionsGranted = granted;
    });
    // Load the workout data using the service
    await _loadScheduledWorkouts();
  }


  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('DEBUG: _handleNotificationTap called with: $data');
    if (data['type'] == 'workout_reminder') {
      final dateKey = data['dateKey'] as String;
      final workoutIndex = data['workoutIndex'] as int;

      setState(() {
        _highlightedWorkoutKey = '${dateKey}_$workoutIndex';
      });

      _showWorkoutActionDialog(
        workoutName: data['workoutName'] as String,
        dateKey: dateKey,
        workoutIndex: workoutIndex,
      );
    }
  }

  void _showWorkoutActionDialog({
    required String workoutName,
    required String dateKey,
    required int workoutIndex,
  }) {
    print('DEBUG: _showWorkoutActionDialog is now being called for $workoutName');
    // Ensure the context is valid before showing a dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workoutName),
        content: const Text('Your scheduled workout is ready to start!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startScheduledWorkout(workoutName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }

  // --- REFACTORED: Use ScheduleService ---
  Future<void> _loadScheduledWorkouts() async {
    // This will attempt to migrate old data if it exists
    await _scheduleService.migrateOldScheduleFormat();
    final workouts = await _scheduleService.getScheduledWorkouts();
    if (mounted) {
      setState(() {
        scheduledWorkouts = workouts;
      });
    }
  }

  // --- REFACTORED: Use ScheduleService ---
  Future<void> _scheduleWorkout() async {
    if (!_permissionsGranted) {
      showCustomSnackBar(
        context,
        message: 'Please grant notification permissions to receive workout reminders',
        type: SnackBarType.warning,
      );
      return;
    }

    if (selectedWorkout == null || selectedTimeSlot == null) return;

    final workoutDetails = workouts.firstWhere((w) => w['name'] == selectedWorkout);

    await _scheduleService.scheduleWorkout(
      workoutName: selectedWorkout!,
      time: selectedTimeSlot!,
      date: selectedDate,
      color: workoutDetails['color'],
      notificationsEnabled: true,
    );

    // Reload the data from the service to update the UI
    await _loadScheduledWorkouts();

    showCustomSnackBar(
      context,
      message: 'Workout scheduled for ${selectedDate.month}/${selectedDate.day} at $selectedTimeSlot',
      type: SnackBarType.success,
    );

    setState(() {
      selectedWorkout = null;
    });
  }

  // --- REFACTORED: Use ScheduleService ---
  void _deleteScheduledWorkout(String dateKey, int index) async {
    await _scheduleService.deleteScheduledWorkout(dateKey, index);
    // Reload the data from the service to update the UI
    await _loadScheduledWorkouts();
    showCustomSnackBar(
      context,
      message: 'Workout and reminders removed',
      type: SnackBarType.warning,
    );
  }
  // --- Methods _saveScheduledWorkouts and _scheduleNotificationsForWorkout are now REMOVED as service handles them ---

  Future<void> _startScheduledWorkout(String workoutName) async {
    WorkoutPlan? workoutPlan;

    try {
      workoutPlan = _getPredefinedWorkoutPlan(workoutName);
    } catch (e) {
      final customWorkouts = await _customWorkoutService.getCustomWorkouts();
      try {
        workoutPlan = customWorkouts.firstWhere(
              (w) => w.name == workoutName,
        );
      } catch (e) {
        showCustomSnackBar(
          context,
          message: 'Workout not found: $workoutName',
          type: SnackBarType.error,
        );
        return;
      }
    }

    if (workoutPlan != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutExecutionScreen(workoutPlan: workoutPlan!),
        ),
      );
    }
  }

  // --- UI and other helper methods below are updated to use the new data model ---
  // --- No logical changes are needed for the user to make below this line ---

  void _updateSelectedTimeSlot() {
    final hourStr = _selectedHour.toString();
    final minuteStr = _selectedMinute.toString().padLeft(2, '0');
    selectedTimeSlot = '$hourStr:$minuteStr $_selectedPeriod';
  }

  String _formatTimeForDisplay(String? timeSlot) {
    if (timeSlot == null) return 'No time selected';
    final parts = timeSlot.split(' ');
    if (parts.length != 2) return timeSlot;
    final timePart = parts[0];
    final period = parts[1];
    final timeParts = timePart.split(':');
    if (timeParts.length != 2) return timeSlot;
    final hour = timeParts[0].padLeft(2, '0');
    final minute = timeParts[1];
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Schedule'),
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
            Text(
              'Schedule Your Workouts',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your fitness routine and stay consistent',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            if (!_permissionsGranted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications disabled. Enable them to receive workout reminders.',
                        style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
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
                          'Select Date',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.add(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                      Text(
                        'Select Time',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          showCustomSnackBar(
                            context,
                            message: '💡 Tip: Double-tap on hour or minute fields to edit with keyboard',
                            type: SnackBarType.info,
                            duration: const Duration(seconds: 3),
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TimePickerMock(
                    initialTime: TimeOfDay(
                      hour: _selectedPeriod == 'AM'
                          ? (_selectedHour == 12 ? 0 : _selectedHour)
                          : (_selectedHour == 12 ? 12 : _selectedHour + 12),
                      minute: _selectedMinute,
                    ),
                    onChanged: (TimeOfDay time) {
                      setState(() {
                        _selectedHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
                        _selectedMinute = time.minute;
                        _selectedPeriod = time.hour >= 12 ? 'PM' : 'AM';
                        _updateSelectedTimeSlot();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedTimeSlot != null
                        ? 'Selected: ${_formatTimeForDisplay(selectedTimeSlot)}'
                        : 'No time selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    'Select Workout',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...workouts.map(
                        (workout) => _WorkoutOption(
                      workout: workout,
                      isSelected: selectedWorkout == workout['name'],
                      onTap: () {
                        setState(() {
                          selectedWorkout = workout['name'];
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildScheduledWorkouts(),
            const SizedBox(height: 32),
            AppButton(
              text: 'Schedule Workout',
              icon: Icons.schedule,
              onPressed: (selectedTimeSlot != null && selectedWorkout != null) ? _scheduleWorkout : null,
              isFullWidth: true,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Save & Exit',
              icon: Icons.exit_to_app,
              onPressed: () async {
                if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
              isFullWidth: true,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate((daysInMonth + firstWeekday - 1) ~/ 7 + 1, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isSelected = isCurrentMonth && dayNumber == selectedDate.day;
              final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final hasWorkout = isCurrentMonth && scheduledWorkouts.containsKey(dateKey) && (scheduledWorkouts[dateKey]?.isNotEmpty ?? false);

              return Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth
                      ? () {
                    setState(() {
                      selectedDate = DateTime(selectedDate.year, selectedDate.month, dayNumber);
                    });
                  }
                      : null,
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : (hasWorkout ? AppTheme.primary.withOpacity(0.1) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: hasWorkout ? Border.all(color: AppTheme.primary, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        isCurrentMonth ? '$dayNumber' : '',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected || hasWorkout ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildScheduledWorkouts() {
    final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final workoutsForDay = scheduledWorkouts[dateKey] ?? [];

    if (workoutsForDay.isEmpty) {
      return Container(
        width: double.infinity,
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule, color: AppTheme.textSubtle, size: 48),
            const SizedBox(height: 16),
            Text(
              'No workouts scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first workout for this day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
          Text(
            'Scheduled Workouts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...workoutsForDay.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            final isHighlighted = _highlightedWorkoutKey == '${dateKey}_$index';
            return _ScheduledWorkoutItem(
              workout: workout, // Pass the ScheduledWorkout object
              onDelete: () => _deleteScheduledWorkout(dateKey, index),
              onTap: () => _startScheduledWorkout(workout.workout), // Access property
              isHighlighted: isHighlighted,
              dateKey: dateKey,
              workoutIndex: index,
            );
          }),
        ],
      ),
    );
  }

  WorkoutPlan _getPredefinedWorkoutPlan(String workoutName) {
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
        );
      case 'Lower Body Power':
        return WorkoutPlan(
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
        );
      case 'Full Body HIIT':
        return WorkoutPlan(
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
        );
      case 'Core & Stability':
        return WorkoutPlan(
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
        );
      case 'Cardio Session':
        return WorkoutPlan(
          name: 'Cardio Session',
          duration: '40 min',
          exerciseCount: 5,
          difficulty: 'Intermediate',
          icon: Icons.favorite,
          color: AppTheme.error,
          exercises: [
            Exercise(
              name: 'Warm Up',
              sets: 1,
              reps: '5 min',
              rest: '0s',
              icon: Icons.directions_walk,
              instructions: 'Light jogging or marching in place',
              targetMuscles: 'Full Body',
            ),
            Exercise(
              name: 'Running',
              sets: 1,
              reps: '20 min',
              rest: '2 min',
              icon: Icons.directions_run,
              instructions: 'Maintain steady pace',
              targetMuscles: 'Legs, Cardiovascular',
            ),
            Exercise(
              name: 'Jumping Jacks',
              sets: 3,
              reps: '1 min',
              rest: '30s',
              icon: Icons.fitness_center,
              instructions: 'Keep a steady rhythm',
              targetMuscles: 'Full Body',
            ),
            Exercise(
              name: 'High Knees',
              sets: 3,
              reps: '30s',
              rest: '30s',
              icon: Icons.fitness_center,
              instructions: 'Bring knees up to waist level',
              targetMuscles: 'Legs, Core',
            ),
            Exercise(
              name: 'Cool Down',
              sets: 1,
              reps: '5 min',
              rest: '0s',
              icon: Icons.self_improvement,
              instructions: 'Walking and stretching',
              targetMuscles: 'Full Body',
            ),
          ],
        );
      default:
        throw Exception('Workout not found: $workoutName');
    }
  }
}

class _WorkoutOption extends StatelessWidget {
  final Map<String, dynamic> workout;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkoutOption({
    required this.workout,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (workout['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(workout['icon'], color: workout['color'], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        workout['duration'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ScheduledWorkoutItem extends StatelessWidget {
  final ScheduledWorkout workout; // Updated to use the model
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final String dateKey;
  final int workoutIndex;

  const _ScheduledWorkoutItem({
    required this.workout,
    required this.onDelete,
    this.onTap,
    this.isHighlighted = false,
    required this.dateKey,
    required this.workoutIndex,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = workout.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWorkoutOptions(context),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: isHighlighted ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: isHighlighted ? AppTheme.primary : color.withOpacity(0.3),
                width: isHighlighted ? 2 : 1,
              ),
              boxShadow: isHighlighted
                  ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.workout, // Use property from model
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.time, // Use property from model
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_fill,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWorkoutOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workout.workout,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scheduled for ${workout.time}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onTap?.call();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Workout Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Workout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Workout'),
          content: Text('Are you sure you want to delete "${workout.workout}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}