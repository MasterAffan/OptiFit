import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, dynamic>? notificationData;
  const ScheduleScreen({super.key, this.notificationData});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedHour = 6;
  int _selectedMinute = 0;
  String _selectedPeriod = 'AM';

  // New state variables for notifications
  final NotificationService _notificationService = NotificationService();
  final CustomWorkoutService _customWorkoutService = CustomWorkoutService();
  String? _highlightedWorkoutKey; // For highlighting workout from notification
  bool _permissionsGranted = false;

  void _updateSelectedTimeSlot() {
    final hourStr = _selectedHour.toString(); // No leading zero for saving
    final minuteStr = _selectedMinute.toString().padLeft(2, '0'); // Leading zero for minutes
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

    final hour = timeParts[0].padLeft(2, '0'); // Add leading zero for display
    final minute = timeParts[1];

    return '$hour:$minute $period';
  }

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

  Map<String, List<Map<String, dynamic>>> scheduledWorkouts = {};

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _selectedHour = (now.hour == 0 || now.hour > 12) ? (now.hour - 12) : (now.hour == 0 ? 12 : now.hour);
    _selectedMinute = now.minute;
    _selectedPeriod = now.hour >= 12 ? 'PM' : 'AM';
    _updateSelectedTimeSlot();
    _loadScheduledWorkouts();
    _initializeNotifications();
    _checkForNotificationNavigation();
    if (widget.notificationData != null) {
      // Defer until after build so UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(widget.notificationData!);
      });
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    final granted = await _notificationService.requestPermissions();
    setState(() {
      _permissionsGranted = granted;
    });

    // Set up notification tap handler
    NotificationNavigationHandler.setNotificationHandler((data) {
      _handleNotificationTap(data);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (data['type'] == 'workout_reminder') {
      final dateKey = data['dateKey'] as String;
      final workoutIndex = data['workoutIndex'] as int;

      setState(() {
        _highlightedWorkoutKey = '${dateKey}_$workoutIndex';
      });

      // Show workout action dialog
      _showWorkoutActionDialog(
        workoutName: data['workoutName'] as String,
        dateKey: dateKey,
        workoutIndex: workoutIndex,
      );
    }
  }

  void _checkForNotificationNavigation() {
    // Handle app launch from notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if there's navigation data passed from main.dart
    });
  }

  void _showWorkoutActionDialog({
    required String workoutName,
    required String dateKey,
    required int workoutIndex,
  }) {
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

  Future<void> _startScheduledWorkout(String workoutName) async {
    WorkoutPlan? workoutPlan;

    // Try to find in predefined workouts
    try {
      workoutPlan = _getPredefinedWorkoutPlan(workoutName);
    } catch (e) {
      // Try custom workouts
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

  Future<void> _loadScheduledWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('scheduledWorkouts');
    if (jsonString != null) {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        scheduledWorkouts = decoded.map((key, value) => MapEntry(
          key,
          (value as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['color'] = Color(map['color']);
            return map;
          }).toList(),
        ));
      });
    }
  }

  Future<void> _saveScheduledWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert Color to int for storage
    final toSave = scheduledWorkouts.map((key, value) => MapEntry(
      key,
      value.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['color'] = (map['color'] is Color) ? (map['color'] as Color).value : map['color'];
        return map;
      }).toList(),
    ));
    final jsonString = json.encode(toSave);
    await prefs.setString('scheduledWorkouts', jsonString);
  }

  Future<void> _scheduleWorkout() async {
    if (!_permissionsGranted) {
      showCustomSnackBar(
        context,
        message: 'Please grant notification permissions to receive workout reminders',
        type: SnackBarType.warning,
      );
      return;
    }

    final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final workoutDetails = workouts.firstWhere((w) => w['name'] == selectedWorkout);
    final newScheduledWorkout = {
      'time': selectedTimeSlot!,
      'workout': selectedWorkout!,
      'color': workoutDetails['color'].value,
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // Add unique ID
    };

    setState(() {
      if (scheduledWorkouts.containsKey(dateKey)) {
        scheduledWorkouts[dateKey]!.add(newScheduledWorkout);
      } else {
        scheduledWorkouts[dateKey] = [newScheduledWorkout];
      }
    });

    await _saveScheduledWorkouts();

    // Schedule notifications
    final workoutIndex = (scheduledWorkouts[dateKey]?.length ?? 1) - 1;
    await _scheduleNotificationsForWorkout(
      workoutName: selectedWorkout!,
      dateKey: dateKey,
      workoutIndex: workoutIndex,
    );

    showCustomSnackBar(
      context,
      message: 'Workout scheduled for ${selectedDate.month}/${selectedDate.day} at $selectedTimeSlot with reminders',
      type: SnackBarType.success,
    );

    setState(() {
      selectedTimeSlot = null;
      selectedWorkout = null;
    });
  }

  Future<void> _scheduleNotificationsForWorkout({
    required String workoutName,
    required String dateKey,
    required int workoutIndex,
  }) async {
    final workout = scheduledWorkouts[dateKey]![workoutIndex];
    final timeStr = workout['time'] as String;

    // Parse the time string (e.g., "7:30 PM")
    final timeParts = timeStr.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final period = timeParts[1];

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    await _notificationService.scheduleWorkoutNotifications(
      workoutName: workoutName,
      scheduledTime: scheduledDateTime,
      dateKey: dateKey,
      workoutIndex: workoutIndex,
    );
  }

  void _deleteScheduledWorkout(String dateKey, int index) async {
    // Cancel notifications before deleting
    await _notificationService.cancelWorkoutNotifications(dateKey, index);

    setState(() {
      scheduledWorkouts[dateKey]!.removeAt(index);
      if (scheduledWorkouts[dateKey]!.isEmpty) {
        scheduledWorkouts.remove(dateKey);
      }
    });

    await _saveScheduledWorkouts();
    showCustomSnackBar(
      context,
      message: 'Workout and reminders removed from schedule',
      type: SnackBarType.warning,
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
            // Header
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

            // Permission status indicator
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

            // Add this after the permission status indicator and before the calendar
            if (kDebugMode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Text(
                      '🧪 Debug Tools',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              print('🧪 Testing immediate notification...');
                              await _notificationService.showTestNotification();
                            },
                            child: const Text('Test Notification'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              print('🧪 Checking permissions...');
                              final granted = await _notificationService.requestPermissions();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Permissions: ${granted ? "Granted" : "Denied"}')),
                              );
                            },
                            child: const Text('Check Permissions'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Calendar
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

            // Custom Time Picker
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

            // Scheduled Workouts for Selected Date
            _buildScheduledWorkouts(),

            const SizedBox(height: 32),

            // Schedule Button
            AppButton(
              text: 'Schedule Workout',
              icon: Icons.schedule,
              onPressed: (selectedTimeSlot != null && selectedWorkout != null) ? _scheduleWorkout : null,
              isFullWidth: true,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 16),
            // Save & Exit Button
            AppButton(
              text: 'Save & Exit',
              icon: Icons.exit_to_app,
              onPressed: () async {
                await _saveScheduledWorkouts();
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
        // Day headers
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
        // Calendar grid
        ...List.generate((daysInMonth + firstWeekday - 1) ~/ 7 + 1, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isSelected = isCurrentMonth && dayNumber == selectedDate.day;
              final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final hasWorkout = isCurrentMonth && scheduledWorkouts.containsKey(dateKey);

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
    final workouts = scheduledWorkouts[dateKey] ?? [];

    if (workouts.isEmpty) {
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
          ...workouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            final isHighlighted = _highlightedWorkoutKey == '${dateKey}_$index';
            return _ScheduledWorkoutItem(
              workout: workout,
              onDelete: () => _deleteScheduledWorkout(dateKey, index),
              onTap: () => _startScheduledWorkout(workout['workout']),
              isHighlighted: isHighlighted,
              dateKey: dateKey,
              workoutIndex: index,
            );
          }),
        ],
      ),
    );
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
                color: workout['color'].withOpacity(0.1),
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
  final Map<String, dynamic> workout;
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
    final Color color = workout['color'] is Color ? workout['color'] : Color(workout['color']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('🖱️ Workout card tapped: ${workout['workout']}');
            // Show bottom sheet with options
            _showWorkoutOptions(context);
          },
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
                        workout['workout'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout['time'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to start workout or delete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSubtle,
                          fontStyle: FontStyle.italic,
                        ),
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
    print('💬 Showing workout options dialog');
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workout['workout'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scheduled for ${workout['time']}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    print('🏃‍♂️ Starting workout: ${workout['workout']}');
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
                    print('🗑️ Deleting workout: ${workout['workout']}');
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
          content: Text('Are you sure you want to delete "${workout['workout']}"?'),
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