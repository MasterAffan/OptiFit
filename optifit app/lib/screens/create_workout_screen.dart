import 'package:flutter/material.dart';
import 'add_exercise_screen.dart';
import '../models/workout_models.dart';
import '../services/custom_workout_service.dart';
import '../theme/theme.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final bool isEditMode;
  final WorkoutPlan? workoutToEdit;

  const CreateWorkoutScreen({
    super.key,
    this.isEditMode = false,
    this.workoutToEdit,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  late List<Exercise> _exercises;

  final CustomWorkoutService _customWorkoutService = CustomWorkoutService();

  @override
  void initState() {
    super.initState();
    _exercises = [];
    if (widget.isEditMode && widget.workoutToEdit != null) {
      final workout = widget.workoutToEdit!;
      _nameController.text = workout.name;
      _durationController.text = workout.duration.replaceAll(' min', '');
      _caloriesController.text = workout.calories ?? '';
      _exercises.addAll(workout.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _addExercise() async {
    final newExercises = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(builder: (context) => const AddExerciseScreen()),
    );

    if (newExercises != null && newExercises.isNotEmpty) {
      setState(() {
        _exercises.addAll(newExercises);
      });
    }
  }

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
      if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one exercise.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      final newWorkout = WorkoutPlan(
        name: _nameController.text,
        duration: '${_durationController.text} min',
        exerciseCount: _exercises.length,
        difficulty: 'Custom',
        icon: Icons.fitness_center,
        color: Colors.blue,
        exercises: _exercises,
        calories: _caloriesController.text,
      );

      _customWorkoutService.saveCustomWorkout(newWorkout);

      Navigator.of(context).pop(true); // Pass true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edit Custom Workout' : 'Create Custom Workout',
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingL,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Workout Name'),
                readOnly: widget.isEditMode,
                validator: (value) =>
                    Validators.validateNotEmpty(value, 'Workout Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.validateNumber(value, 'Duration'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Calories',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.validateNumber(value, 'Estimated Calories'),
              ),
              const SizedBox(height: 24),
              Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(exercise.icon),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.sets} sets, ${exercise.reps} reps, ${exercise.rest} rest',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _exercises.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              if (_exercises.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No exercises added yet.'),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(text: 'Save Workout', onPressed: _saveWorkout),
            ],
          ),
        ),
      ),
    );
  }
}
