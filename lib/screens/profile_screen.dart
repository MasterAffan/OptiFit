import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'start_workout_screen.dart';
import 'schedule_screen.dart';
import '../services/data_service.dart';
import 'personal_info_screen.dart';
import 'goals_preferences_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool aiCoachEnabled = true;
  bool notificationsEnabled = true;

  late Future<Map<String, dynamic>> _futureStats;
  late Future<List<dynamic>> _futureHistory;

  String? _profileImagePath;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _futureStats = DataService().getWorkoutStats();
    _futureHistory = DataService().getWorkoutHistory();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DataService().getUserProfile();
    setState(() {
      _profileImagePath = profile['profileImage'];
      _userProfile = profile;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final profile = await DataService().getUserProfile();
      profile['profileImage'] = picked.path;
      await DataService().saveUserProfile(profile);
      setState(() {
        _profileImagePath = picked.path;
        _userProfile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureStats,
      builder: (context, statsSnapshot) {
        return FutureBuilder<List<dynamic>>(
          future: _futureHistory,
          builder: (context, historySnapshot) {
            final stats = statsSnapshot.data ?? {};
            final history = historySnapshot.data ?? [];
            final totalWorkouts = stats['totalWorkouts'] ?? 0;
            final streakDays = stats['streakDays'] ?? 0;
            final totalMinutes = stats['totalDuration'] ?? 0;
            final totalCalories = stats['totalCalories'] ?? 0;
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: AppTheme.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with navigation buttons
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Profile',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StartWorkoutScreen(),
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
                                    builder: (context) =>
                                        const ScheduleScreen(),
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
                        // Profile card
                        Container(
                          width: double.infinity,
                          padding: AppTheme.cardPadding,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundImage:
                                                  _profileImagePath != null &&
                                                      _profileImagePath!.isNotEmpty
                                                  ? FileImage(
                                                      File(_profileImagePath!),
                                                    )
                                                  : const AssetImage(
                                                          'assets/profile.png',
                                                    )
                                                      as ImageProvider,
                                            ),
                                            Positioned(
                                              right: -6,
                                              bottom: -6,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 2,
                                                  ),
                                                ),
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _userProfile?['name'] ?? 'Fitness Enthusiast',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userProfile?['level'] ?? 'Intermediate Level',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Joined January 2024',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ProfileStat(
                                    value: totalWorkouts.toString(),
                                    label: 'Workouts',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: AppTheme.divider,
                                  ),
                                  _ProfileStat(
                                    value: streakDays.toString(),
                                    label: 'Day Streak',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Recent Achievements title
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent Achievements',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (context) =>
                                      _AllAchievementsSheet(history: history),
                                );
                              },
                              child: const Text('See All'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Recent Achievements list (show up to 3 earned)
                        Column(children: _buildRecentAchievements(history)),
                        const SizedBox(height: 32),
                        // Settings list
                        _SettingsTile(
                          icon: Icons.person,
                          title: 'Personal Information',
                          subtitle: 'Edit your profile details',
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PersonalInfoScreen(),
                              ),
                            );
                            if (result == true) _loadProfile();
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.track_changes,
                          title: 'Goals & Preferences',
                          subtitle: 'Set your fitness goals',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GoalsPreferencesScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.security,
                          title: 'Privacy & Security',
                          subtitle: 'Control your data',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacySecurityScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact us',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Workout Summary title
                        Text(
                          'Workout Summary',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        // Workout Summary grid
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.calendar_today,
                                value: _formatMinutes(totalMinutes),
                                label: 'Total Time',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.emoji_events,
                                iconColor: AppTheme.warning,
                                value: totalCalories.toString(),
                                label: 'Calories Burned',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Sign Out button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.logout,
                              color: AppTheme.error,
                            ),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.buttonRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildRecentAchievements(List<dynamic> history) {
    // Use the same logic as _buildDynamicAchievements from progress_screen.dart, but only show earned ones (up to 3)
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
    final achievements = <Widget>[];
    if (streak >= 7) {
      achievements.add(
        _AchievementRow(
          icon: Icons.local_fire_department,
          iconColor: AppTheme.warning,
          title: 'Consistency Champion',
          date: 'Current streak: $streak days',
        ),
      );
    }
    if (totalWorkouts >= 20) {
      achievements.add(
        _AchievementRow(
          icon: Icons.fitness_center,
          iconColor: AppTheme.primary,
          title: 'Strength Builder',
          date: 'Total: $totalWorkouts workouts',
        ),
      );
    }
    if (cardioSessions >= 100) {
      achievements.add(
        _AchievementRow(
          icon: Icons.favorite,
          iconColor: Colors.red,
          title: 'Cardio King',
          date: 'Completed 100 cardio sessions',
        ),
      );
    }
    if (achievements.isEmpty) {
      achievements.add(
        Text(
          'No achievements yet. Keep going!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return achievements.take(3).toList();
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}

// Helper for static context (copied from progress_screen.dart)
Map<String, int> _calculateStatsStatic(List<dynamic> history) {
  final now = DateTime.now();
  DateTime start = DateTime(now.year, now.month, 1);
  final filtered = history.where((s) => s.startTime.isAfter(start)).toList();
  int workouts = filtered.length;
  int calories = filtered.fold<int>(
    0,
    (sum, s) => sum + ((s.caloriesBurned ?? 0) as int),
  );
  int minutes = filtered.fold<int>(
    0,
    (sum, s) => sum + (s.duration.inMinutes as int),
  );
  int streak = 0;
  DateTime current = now;
  while (true) {
    final dayWorkouts = filtered
        .where(
          (s) =>
              s.startTime.year == current.year &&
              s.startTime.month == current.month &&
              s.startTime.day == current.day,
        )
        .toList();
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

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String date;
  const _AchievementRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
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
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events, color: AppTheme.success),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.secondary, size: 28),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.textSubtle),
      onTap: onTap,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? AppTheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
            Text(
              'All Achievements',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
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
                  final iconColor = achieved
                      ? a['iconColor'] as Color
                      : AppTheme.divider;
                  final textColor = achieved ? null : AppTheme.textSecondary;
                  return Container(
                    padding: AppTheme.cardPadding,
                    decoration: BoxDecoration(
                      color: achieved
                          ? AppTheme.cardBackground
                          : AppTheme.background,
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
                              Text(
                                a['title'] as String,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                a['desc'] as String,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: textColor),
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
                                      widthFactor: progress,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                              if (progressText != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  progressText,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (achieved)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Achieved',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
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
