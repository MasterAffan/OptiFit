import 'package:flutter/material.dart';
import '../models/predefined_exercises.dart';
import '../models/workout_models.dart';
import '../theme/theme.dart';
import 'create_exercise_screen.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final List<Exercise> _selectedExercises = [];
  List<Exercise> _filteredExercises = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredExercises = predefinedExercises;
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = predefinedExercises
          .where((exercise) => exercise.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercises'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: AppTheme.paddingM,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Exercises',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isSelected = _selectedExercises.contains(exercise);
                return ListTile(
                  leading: Icon(exercise.icon),
                  title: Text(exercise.name),
                  subtitle: Text(exercise.targetMuscles ?? ''),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _toggleExerciseSelection(exercise);
                    },
                  ),
                  onTap: () {
                    _toggleExerciseSelection(exercise);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: AppTheme.paddingM,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newExercise = await Navigator.of(context)
                          .push<Exercise>(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CreateExerciseScreen(),
                            ),
                          );
                      if (newExercise != null) {
                        Navigator.of(context).pop([newExercise]);
                      }
                    },
                    child: const Text('Create Custom Exercise'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedExercises.isNotEmpty
                        ? () {
                            Navigator.of(context).pop(_selectedExercises);
                          }
                        : null,
                    child: const Text('Add Selected'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
