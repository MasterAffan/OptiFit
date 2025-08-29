import 'package:flutter/material.dart';
import '../models/workout_models.dart';
import '../theme/theme.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _restController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _saveExercise() {
    if (_formKey.currentState!.validate()) {
      final newExercise = Exercise(
        name: _nameController.text,
        sets: int.parse(_setsController.text),
        reps: _repsController.text,
        rest: '${_restController.text}s',
        icon: Icons.fitness_center, // Default icon
      );
      Navigator.of(context).pop(newExercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercise'),
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
                decoration: const InputDecoration(labelText: 'Exercise Name'),
                validator: (value) =>
                    Validators.validateNotEmpty(value, 'Exercise Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _setsController,
                decoration: const InputDecoration(labelText: 'Sets'),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validateNumber(value, 'Sets'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: 'Reps (e.g., 10-12 or 45s)',
                ),
                validator: (value) =>
                    Validators.validateNotEmpty(value, 'Reps'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _restController,
                decoration: const InputDecoration(labelText: 'Rest (seconds)'),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validateNumber(value, 'Rest'),
              ),
              const SizedBox(height: 32),
              AppButton(text: 'Add Exercise', onPressed: _saveExercise),
            ],
          ),
        ),
      ),
    );
  }
}
