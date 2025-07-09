import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/app_button.dart';
import 'start_workout_screen.dart';
import 'schedule_screen.dart';
import '../services/data_service.dart';
import 'workouts_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Home screen following the design system from design.json
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _futureStats;
  final GlobalKey<_AIFitnessInsightCardState> _aiInsightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _futureStats = DataService().getWorkoutStats();
  }

  void _refreshStatsAndInsight() {
    setState(() {
      _futureStats = DataService().getWorkoutStats();
    });
    // Also refresh AI insight
    _aiInsightKey.currentState?.fetchAIInsight();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: AppTheme.paddingLG,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _futureStats,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final stats = snapshot.data!;
                final totalCalories = stats['totalCalories'] ?? 0;
                final totalWorkouts = stats['totalWorkouts'] ?? 0;
                final totalMinutes = stats['totalDuration'] ?? 0;
                final streakDays = stats['streakDays'] ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with navigation buttons
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: Theme.of(context).textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready for your next workout?',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const StartWorkoutScreen(),
                              ),
                            );
                            if (result == true) {
                              _refreshStatsAndInsight();
                            }
                          },
                          icon: const Icon(Icons.fitness_center),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ScheduleScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.schedule),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surface,
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Header section with greeting and profile
                    _buildHeader(),

                    const SizedBox(height: AppTheme.spacingXL),

                    // AI Insight Card
                    _buildAIInsightCard(),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Today's Progress Stats
                    _buildStatsSection(
                      totalCalories: totalCalories,
                      totalWorkouts: totalWorkouts,
                      totalMinutes: totalMinutes,
                      streakDays: streakDays,
                    ),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Quick Actions
                    _buildQuickActionsSection(context),

                    const SizedBox(height: AppTheme.spacingXXL),

                    // Add navigation to workouts screen with refresh
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: AppButton(
                        text: 'View Workout History',
                        icon: Icons.history,
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WorkoutsScreen(),
                            ),
                          );
                          if (result == true) {
                            _refreshStatsAndInsight();
                          }
                        },
                        isFullWidth: true,
                        variant: AppButtonVariant.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DataService().getUserProfile(),
      builder: (context, snapshot) {
        final profileImage = snapshot.data?['profileImage'];
        final userName = snapshot.data?['name'] ?? 'Fitness Enthusiast';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, $userName!',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeHeading,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Ready to crush your goals?',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? FileImage(File(profileImage))
                  : const AssetImage('assets/profile.png') as ImageProvider,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAIInsightCard() {
    return _AIFitnessInsightCard(key: _aiInsightKey);
  }
}

class _AIFitnessInsightCard extends StatefulWidget {
  const _AIFitnessInsightCard({Key? key}) : super(key: key);
  @override
  State<_AIFitnessInsightCard> createState() => _AIFitnessInsightCardState();
}

class _AIFitnessInsightCardState extends State<_AIFitnessInsightCard> {
  String? _aiInsight;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchAIInsight();
  }

  Future<void> fetchAIInsight() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await DataService().getWorkoutStats();
      final totalCalories = stats['totalCalories'] ?? 0;
      final totalWorkouts = stats['totalWorkouts'] ?? 0;
      final totalMinutes = stats['totalDuration'] ?? 0;
      final streakDays = stats['streakDays'] ?? 0;
      // Fetch most recent workout session
      final history = await DataService().getWorkoutHistory();
      if (history.isEmpty) {
        setState(() {
          _aiInsight = "Log your first workout to unlock personalized AI insights!";
          _loading = false;
          _error = null;
        });
        return;
      }
      String recentWorkoutSummary = '';
      if (history.isNotEmpty) {
        final recent = history.last;
        final plan = recent.plan;
        final date = recent.startTime.toLocal().toString().split(' ')[0];
        final duration = recent.duration.inMinutes;
        final calories = recent.caloriesBurned ?? 0;
        final exercises = recent.exercises.map((e) {
          final ex = e.exercise;
          final sets = e.sets.length;
          final completedSets = e.sets.where((s) => s.isCompleted).length;
          return '- ${ex.name}: $completedSets/$sets sets completed';
        }).join('\n');
        recentWorkoutSummary =
          'Most recent workout:\n'
          '- Name: ${plan.name}\n'
          '- Date: $date\n'
          '- Duration: $duration min\n'
          '- Calories burned: $calories\n'
          '- Exercises:\n$exercises';
      }
      final prompt =
          'Here are the user\'s recent fitness stats:\n'
          'Total calories burned: $totalCalories\n'
          'Total workouts: $totalWorkouts\n'
          'Total minutes: $totalMinutes\n'
          'Current streak: $streakDays days\n'
          '${recentWorkoutSummary.isNotEmpty ? recentWorkoutSummary + '\n' : ''}'
          'Give a personalized, motivational fitness insight or suggestion for the user based on these stats and their most recent workout.';
      final url = Uri.parse('your server url here');
      final headers = {'Content-Type': 'application/json'};
      final body = {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful fitness and nutrition assistant. Only answer questions related to gym, fitness, exercise, and nutrition. Keep your answers concise (2-4 sentences). Do not provide long lists or detailed breakdowns unless specifically asked. Do not use bullet points, numbered lists, or markdown formatting (such as **bold** or *italics*). Write in plain sentences only. Give motivational, actionable, and positive insights based on the user\'s stats and their most recent workout.'
          },
          {'role': 'user', 'content': prompt}
        ]
      };
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiInsight = data['choices']?[0]?['message']?['content']?.toString() ?? 'No insight available.';
        });
      } else {
        setState(() {
          _error = 'Error: Server returned status \\${response.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.spacingM,
        horizontal: AppTheme.spacingL,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusL,
        boxShadow: AppTheme.featuredShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 22),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'AI Fitness Insight',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSubtitle,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (_aiInsight != null)
            Text(
              _aiInsight!,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }
}

Widget _buildStatsSection({
  required int totalCalories,
  required int totalWorkouts,
  required int totalMinutes,
  required int streakDays,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Today's Progress",
        style: TextStyle(
          fontSize: AppTheme.fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: AppTheme.spacingL),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingM,
        mainAxisSpacing: AppTheme.spacingM,
        childAspectRatio: 1.2,
        children: [
          _buildStatCard(
            icon: Icons.local_fire_department,
            iconColor: AppTheme.warning,
            value: totalCalories.toString(),
            label: 'Calories',
          ),
          _buildStatCard(
            icon: Icons.track_changes,
            iconColor: AppTheme.success,
            value: totalWorkouts.toString(),
            label: 'Workouts',
          ),
          _buildStatCard(
            icon: Icons.access_time,
            iconColor: const Color(0xFF7C3AED),
            value: totalMinutes.toString(),
            label: 'Minutes',
          ),
          _buildStatCard(
            icon: Icons.emoji_events,
            iconColor: AppTheme.error,
            value: streakDays.toString(),
            label: 'Day Streak',
          ),
        ],
      ),
    ],
  );
}

Widget _buildStatCard({
  required IconData icon,
  required Color iconColor,
  required String value,
  required String label,
}) {
  return Container(
    padding: AppTheme.cardPadding,
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: AppTheme.borderRadiusM,
      boxShadow: AppTheme.baseShadow,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuickActionsSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quick Actions',
        style: TextStyle(
          fontSize: AppTheme.fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: AppTheme.spacingL),
      Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Start Workout',
              icon: Icons.track_changes,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StartWorkoutScreen(),
                  ),
                );
              },
              variant: AppButtonVariant.primary,
              isFullWidth: true,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: AppButton(
              text: 'Schedule',
              icon: Icons.calendar_today,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ScheduleScreen(),
                  ),
                );
              },
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    ],
  );
}
