import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'start_workout_screen.dart';
import 'schedule_screen.dart';
import '../services/data_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int selectedPeriod = 0;
  final List<String> periods = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];

  Future<List<dynamic>> _futureHistory = DataService().getWorkoutHistory();

  @override
  void initState() {
    super.initState();
    _futureHistory = DataService().getWorkoutHistory();
  }

  Map<String, int> _calculateStats(List<dynamic> history) {
    final now = DateTime.now();
    DateTime start;
    if (selectedPeriod == 0) {
      // This week (Monday to now)
      start = now.subtract(Duration(days: now.weekday - 1));
    } else if (selectedPeriod == 1) {
      // This month
      start = DateTime(now.year, now.month, 1);
    } else if (selectedPeriod == 2) {
      // Last 3 months
      start = DateTime(now.year, now.month - 2, 1);
    } else {
      // This year
      start = DateTime(now.year, 1, 1);
    }
    final filtered = history.where((s) => s.startTime.isAfter(start)).toList();
    int workouts = filtered.length;
    int calories = filtered.fold<int>(0, (sum, s) => sum + ((s.caloriesBurned ?? 0) as int));
    int minutes = filtered.fold<int>(0, (sum, s) => sum + (s.duration.inMinutes as int));
    int streak = 0;
    DateTime current = now;
    while (true) {
      final dayWorkouts = filtered.where((s) =>
        s.startTime.year == current.year &&
        s.startTime.month == current.month &&
        s.startTime.day == current.day).toList();
      if (dayWorkouts.isEmpty) break;
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    return {
      'workouts': workouts,
      'calories': calories,
      'minutes': minutes,
      'streak': streak,
    };
  }

  Future<List<Map<String, String>>> _fetchAIInsights(List<dynamic> history) async {
    final stats = _calculateStats(history);
    final totalCalories = stats['calories'];
    final totalWorkouts = stats['workouts'];
    final totalMinutes = stats['minutes'];
    final streak = stats['streak'];
    final period = periods[selectedPeriod];
    // Build a prompt for the AI
    final prompt =
        'Here are the user\'s fitness stats for $period:\n'
        'Total workouts: $totalWorkouts\n'
        'Total calories burned: $totalCalories\n'
        'Total minutes: $totalMinutes\n'
        'Current streak: $streak days\n'
        'Please provide 3 one-line insights about the user\'s progress for this period. For each insight, include a short tag or badge (e.g., +23%, Recommended, New PR!) at the end in square brackets. Format your response as a numbered list.';
    final url = Uri.parse("your server url here");
    final headers = {'Content-Type': 'application/json'};
    final body = {
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful fitness and nutrition assistant. Only answer questions related to gym, fitness, exercise, and nutrition. Keep your answers concise and actionable. Do not use markdown formatting. For each insight, provide a one-line summary and a tag in square brackets at the end.'
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
      final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
      // Parse the numbered list into cards
      final lines = content.split(RegExp(r'\n|\r')).where((l) => l.trim().isNotEmpty).toList();
      final insights = <Map<String, String>>[];
      for (final line in lines) {
        final match = RegExp(r'\d+\.\s*(.+?)\s*\[(.+?)\]').firstMatch(line);
        if (match != null) {
          insights.add({
            'title': match.group(1) ?? '',
            'badge': match.group(2) ?? '',
          });
        }
      }
      return insights;
    } else {
      return [
        {'title': 'Failed to load AI insights', 'badge': 'Error'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureHistory,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final _workoutHistory = snapshot.data!;
        final stats = _calculateStats(_workoutHistory);
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppTheme.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and navigation buttons
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Progress',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const StartWorkoutScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fitness_center),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
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
                    const SizedBox(height: 24),
                    // Period filter chips - horizontally scrollable
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: periods.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final isSelected = i == selectedPeriod;
                          return ChoiceChip(
                            label: Text(
                              periods[i],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() {
                              selectedPeriod = i;
                            }),
                            backgroundColor: AppTheme.chipBackground,
                            selectedColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    // This Week title
                    Text(
                      periods[selectedPeriod],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // 2x2 stat grid
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.track_changes,
                            iconColor: AppTheme.primary,
                            value: stats['workouts'].toString(),
                            label: 'Workouts',
                            delta: '',
                            deltaColor: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department,
                            iconColor: AppTheme.warning,
                            value: stats['calories'].toString(),
                            label: 'Calories',
                            delta: '',
                            deltaColor: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.access_time,
                            iconColor: Colors.purple,
                            value: stats['minutes'].toString(),
                            label: 'Minutes',
                            delta: '',
                            deltaColor: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.flash_on,
                            iconColor: AppTheme.success,
                            value: stats['streak'].toString(),
                            label: 'Day Streak',
                            delta: '',
                            deltaColor: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Workout Frequency title
                    Text(
                      'Workout Frequency',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Real bar chart for workout frequency
                    Container(
                      width: double.infinity,
                      height: 220,
                      padding: AppTheme.cardPadding,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _getMaxWorkoutsPerWeek(_workoutHistory).toDouble() + 1,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value % 1 != 0) return const SizedBox.shrink();
                                          return Text(value.toInt().toString(), style: Theme.of(context).textTheme.bodySmall);
                                        },
                                        interval: 1,
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          final weekLabels = _getLast4WeekLabels();
                                          return Text(weekLabels[value.toInt()], style: Theme.of(context).textTheme.bodySmall);
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(show: false),
                                  barGroups: _getLast4WeeksBarGroups(_workoutHistory),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Workouts completed per week',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // AI Insights title
                    Text(
                      'AI Insights',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, String>>>(
                      future: _fetchAIInsights(_workoutHistory),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final insights = snapshot.data!;
                        return Column(
                          children: [
                            for (final insight in insights)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _InsightCard(
                                  icon: Icons.trending_up,
                                  iconColor: AppTheme.success,
                                  title: insight['title'] ?? '',
                                  subtitle: '',
                                  badge: insight['badge'] ?? '',
                                  badgeColor: AppTheme.success,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Achievements title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Achievements',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) => _AllAchievementsSheet(history: _workoutHistory),
                            );
                          },
                          child: const Text('See All'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Dynamic Achievements list
                    ..._buildDynamicAchievements(_workoutHistory),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper: Get number of workouts per week for the last 4 weeks
  List<int> _getLast4WeeksCounts(List<dynamic> history) {
    final now = DateTime.now();
    List<int> counts = [];
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final count = history.where((s) =>
        s.startTime.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(weekEnd.add(const Duration(days: 1)))
      ).length;
      counts.add(count);
    }
    return counts;
  }

  List<String> _getLast4WeekLabels() {
    final now = DateTime.now();
    List<String> labels = [];
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      labels.add('W${4 - i}');
    }
    return labels;
  }

  int _getMaxWorkoutsPerWeek(List<dynamic> history) {
    final counts = _getLast4WeeksCounts(history);
    return counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
  }

  List<BarChartGroupData> _getLast4WeeksBarGroups(List<dynamic> history) {
    final counts = _getLast4WeeksCounts(history);
    return List.generate(4, (i) =>
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: counts[i].toDouble(),
            color: AppTheme.primary,
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicAchievements(List<dynamic> history) {
    final stats = _calculateStats(history);
    final streak = stats['streak'] ?? 0;
    final totalWorkouts = stats['workouts'] ?? 0;
    // Cardio sessions: count workouts with 'cardio' in the name/type
    int cardioSessions = 0;
    for (final s in history) {
      final name = (s.plan.name ?? '').toString().toLowerCase();
      final type = (s.plan.difficulty ?? '').toString().toLowerCase();
      if (name.contains('cardio') || type.contains('cardio')) {
        cardioSessions++;
      }
    }
    List<Widget> achievements = [];
    // Consistency Champion
    if (streak >= 7) {
      achievements.add(
        _AchievementCard(
          icon: Icons.local_fire_department,
          iconColor: AppTheme.warning,
          title: 'Consistency Champion',
          subtitle: '7+ day workout streak',
          earned: 'Current streak: $streak days',
          earnedColor: AppTheme.success,
        ),
      );
    }
    // Strength Builder
    if (totalWorkouts >= 20) {
      achievements.add(
        _AchievementCard(
          icon: Icons.fitness_center,
          iconColor: AppTheme.primary,
          title: 'Strength Builder',
          subtitle: 'Completed 20+ workouts',
          earned: 'Total: $totalWorkouts workouts',
          earnedColor: AppTheme.success,
        ),
      );
    }
    // Cardio King (progress bar if not yet reached)
    double cardioProgress = (cardioSessions / 100).clamp(0.0, 1.0);
    achievements.add(
      _AchievementCard(
        icon: Icons.favorite,
        iconColor: Colors.red,
        title: 'Cardio King',
        subtitle: 'Complete 100 cardio sessions',
        progress: cardioProgress,
        earned: cardioSessions >= 100 ? 'Achieved!' : 'Progress: $cardioSessions/100',
        earnedColor: cardioSessions >= 100 ? AppTheme.success : AppTheme.textSecondary,
      ),
    );
    if (achievements.isEmpty) {
      achievements.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('No achievements yet. Keep going!', style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return achievements;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String delta;
  final Color deltaColor;
  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label, required this.delta, required this.deltaColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  delta,
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _Bar extends StatelessWidget {
  final String label;
  final double value; // 0.0 - 1.0
  const _Bar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve space for the label and spacing
        final double labelHeight = 20;
        final double spacing = 8;
        final double maxBarHeight = constraints.maxHeight - labelHeight - spacing;
        final double barHeight = (maxBarHeight > 0 ? maxBarHeight : 0) * value;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: barHeight,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              height: labelHeight,
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  const _InsightCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.badge, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String earned;
  final Color earnedColor;
  final double? progress;
  const _AchievementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.earned,
    required this.earnedColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress!,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: earnedColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              earned,
              style: TextStyle(
                color: earnedColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAchievementsSheet extends StatelessWidget {
  final List<dynamic> history;
  const _AllAchievementsSheet({required this.history});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatsStatic(history);
    final streak = stats['streak'] ?? 0;
    final totalWorkouts = stats['workouts'] ?? 0;
    int cardioSessions = 0;
    for (final s in history) {
      final name = (s.plan.name ?? '').toString().toLowerCase();
      final type = (s.plan.difficulty ?? '').toString().toLowerCase();
      if (name.contains('cardio') || type.contains('cardio')) {
        cardioSessions++;
      }
    }
    // Master list of all achievements
    final allAchievements = [
      {
        'icon': Icons.local_fire_department,
        'iconColor': AppTheme.warning,
        'title': 'Consistency Champion',
        'desc': 'Achieve a 7+ day workout streak.',
        'achieved': streak >= 7,
        'progress': streak >= 7 ? null : streak / 7.0,
        'progressText': 'Current streak: $streak/7 days',
      },
      {
        'icon': Icons.fitness_center,
        'iconColor': AppTheme.primary,
        'title': 'Strength Builder',
        'desc': 'Complete 20+ workouts.',
        'achieved': totalWorkouts >= 20,
        'progress': totalWorkouts >= 20 ? null : totalWorkouts / 20.0,
        'progressText': 'Total: $totalWorkouts/20 workouts',
      },
      {
        'icon': Icons.favorite,
        'iconColor': Colors.red,
        'title': 'Cardio King',
        'desc': 'Complete 100 cardio sessions.',
        'achieved': cardioSessions >= 100,
        'progress': cardioSessions >= 100 ? null : cardioSessions / 100.0,
        'progressText': 'Progress: $cardioSessions/100',
      },
      // Add more achievements here if desired
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('All Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: allAchievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final a = allAchievements[i];
                  final achieved = a['achieved'] as bool;
                  final progress = a['progress'] as double?;
                  final progressText = a['progressText'] as String?;
                  final iconColor = achieved ? a['iconColor'] as Color : AppTheme.divider;
                  final textColor = achieved ? null : AppTheme.textSecondary;
                  return Container(
                    padding: AppTheme.cardPadding,
                    decoration: BoxDecoration(
                      color: achieved ? AppTheme.cardBackground : AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(a['icon'] as IconData, color: iconColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] as String, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 2),
                              Text(a['desc'] as String, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor)),
                              if (progress != null) ...[
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppTheme.divider,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${(progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                              ],
                              if (progressText != null) ...[
                                const SizedBox(height: 4),
                                Text(progressText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                        if (achieved)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Achieved', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for static context
Map<String, int> _calculateStatsStatic(List<dynamic> history) {
  final now = DateTime.now();
  DateTime start = DateTime(now.year, now.month, 1);
  final filtered = history.where((s) => s.startTime.isAfter(start)).toList();
  int workouts = filtered.length;
  int calories = filtered.fold<int>(0, (sum, s) => sum + ((s.caloriesBurned ?? 0) as int));
  int minutes = filtered.fold<int>(0, (sum, s) => sum + (s.duration.inMinutes as int));
  int streak = 0;
  DateTime current = now;
  while (true) {
    final dayWorkouts = filtered.where((s) =>
      s.startTime.year == current.year &&
      s.startTime.month == current.month &&
      s.startTime.day == current.day).toList();
    if (dayWorkouts.isEmpty) break;
    streak++;
    current = current.subtract(const Duration(days: 1));
  }
  return {
    'workouts': workouts,
    'calories': calories,
    'minutes': minutes,
    'streak': streak,
  };
} 