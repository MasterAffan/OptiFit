import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_snackbar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  String? selectedWorkout;

  final List<String> timeSlots = [
    '6:00 AM',
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

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
    _loadScheduledWorkouts();
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
    final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final workoutDetails = workouts.firstWhere((w) => w['name'] == selectedWorkout);
    final newScheduledWorkout = {
      'time': selectedTimeSlot!,
      'workout': selectedWorkout!,
      'color': workoutDetails['color'].value, // store as int
    };
    setState(() {
      if (scheduledWorkouts.containsKey(dateKey)) {
        scheduledWorkouts[dateKey]!.add(newScheduledWorkout);
      } else {
        scheduledWorkouts[dateKey] = [newScheduledWorkout];
      }
    });
    await _saveScheduledWorkouts();
    showCustomSnackBar(
      context,
      message: 'Workout scheduled for ${selectedDate.month}/${selectedDate.day} at $selectedTimeSlot',
      type: SnackBarType.success,
    );
    setState(() {
      selectedTimeSlot = null;
      selectedWorkout = null;
    });
  }

  void _deleteScheduledWorkout(String dateKey, int index) async {
    setState(() {
      scheduledWorkouts[dateKey]!.removeAt(index);
      if (scheduledWorkouts[dateKey]!.isEmpty) {
        scheduledWorkouts.remove(dateKey);
      }
    });
    await _saveScheduledWorkouts();
    showCustomSnackBar(
      context,
      message: 'Workout removed from schedule',
      type: SnackBarType.warning,
    );
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
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your fitness routine and stay consistent',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.subtract(
                              const Duration(days: 1),
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.add(
                              const Duration(days: 1),
                            );
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

            // Time Slots
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
                    'Select Time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: timeSlots
                        .map(
                          (time) => _TimeSlotChip(
                            time: time,
                            isSelected: selectedTimeSlot == time,
                            onTap: () {
                              setState(() {
                                selectedTimeSlot = time;
                              });
                            },
                          ),
                        )
                        .toList(),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
              onPressed:
                  (selectedTimeSlot != null &&
                      selectedWorkout != null)
                  ? _scheduleWorkout
                  : null,
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
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
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
        ...List.generate((daysInMonth + firstWeekday - 1) ~/ 7 + 1, (
          weekIndex,
        ) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isSelected =
                  isCurrentMonth && dayNumber == selectedDate.day;
              final dateKey =
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final hasWorkout =
                  isCurrentMonth && scheduledWorkouts.containsKey(dateKey);

              return Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth
                      ? () {
                          setState(() {
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              dayNumber,
                            );
                          });
                        }
                      : null,
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : (hasWorkout
                                ? AppTheme.primary.withOpacity(0.1)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: hasWorkout
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isCurrentMonth ? '$dayNumber' : '',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: isSelected || hasWorkout
                              ? FontWeight.w700
                              : FontWeight.normal,
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
    final dateKey =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first workout for this day',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...workouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            return _ScheduledWorkoutItem(
              workout: workout,
              onDelete: () => _deleteScheduledWorkout(dateKey, index),
            );
          }),
        ],
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.surface,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workout['duration'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ScheduledWorkoutItem extends StatelessWidget {
  final Map<String, dynamic> workout;
  final VoidCallback onDelete;

  const _ScheduledWorkoutItem({required this.workout, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final Color color = workout['color'] is Color
        ? workout['color']
        : Color(workout['color']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workout['time'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.textSubtle,
          ),
        ],
      ),
    );
  }
}
