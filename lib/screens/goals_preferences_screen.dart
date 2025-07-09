import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/data_service.dart';

class GoalsPreferencesScreen extends StatefulWidget {
  const GoalsPreferencesScreen({super.key});

  @override
  State<GoalsPreferencesScreen> createState() => _GoalsPreferencesScreenState();
}

class _GoalsPreferencesScreenState extends State<GoalsPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workoutsPerWeekController = TextEditingController();
  final _targetWeightController = TextEditingController();
  List<String> _workoutTypes = ['Strength', 'Cardio', 'HIIT', 'Yoga', 'Mobility'];
  List<String> _selectedTypes = [];
  bool _notifications = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await DataService().getUserPreferences();
    setState(() {
      _workoutsPerWeekController.text = prefs['workoutsPerWeek']?.toString() ?? '';
      _targetWeightController.text = prefs['targetWeight']?.toString() ?? '';
      _selectedTypes = List<String>.from(prefs['workoutTypes'] ?? []);
      _notifications = prefs['notifications'] ?? true;
      _loading = false;
    });
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = {
      'workoutsPerWeek': int.tryParse(_workoutsPerWeekController.text) ?? 0,
      'targetWeight': double.tryParse(_targetWeightController.text) ?? 0.0,
      'workoutTypes': _selectedTypes,
      'notifications': _notifications,
    };
    await DataService().saveUserPreferences(prefs);
    setState(() => _saving = false);
    final snackBar = SnackBar(
      content: const Text('Preferences updated!'),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await Future.delayed(const Duration(seconds: 2));
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Preferences'),
        backgroundColor: AppTheme.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _workoutsPerWeekController,
                      decoration: const InputDecoration(labelText: 'Workouts per week'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a number';
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 14) return 'Enter a valid number (1-14)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetWeightController,
                      decoration: const InputDecoration(labelText: 'Target Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a target weight';
                        final w = double.tryParse(v);
                        if (w == null || w < 30 || w > 300) return 'Enter a valid weight';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Preferred Workout Types', style: Theme.of(context).textTheme.bodyLarge),
                    Wrap(
                      spacing: 8,
                      children: _workoutTypes.map((type) {
                        final selected = _selectedTypes.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                      title: const Text('Enable Notifications'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _savePreferences,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Preferences'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 