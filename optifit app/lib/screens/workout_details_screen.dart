import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../models/workout_models.dart';
import '../widgets/app_button.dart';
import '../main.dart';
import '../widgets/custom_snackbar.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  final WorkoutSession session;

  const WorkoutDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Workout Details'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with workout summary
            _buildWorkoutHeader(),
            const SizedBox(height: 24),

            // Overall stats
            _buildOverallStats(context),
            const SizedBox(height: 24),

            // Exercise breakdown
            _buildExerciseBreakdown(context),
            const SizedBox(height: 24),

            // Performance insights
            _buildPerformanceInsights(),
            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHeader() {
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: session.plan.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  session.plan.icon,
                  color: session.plan.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed on ${_formatDate(session.startTime)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(
                icon: Icons.timer,
                value: '${session.duration.inMinutes}',
                label: 'Minutes',
              ),
              const SizedBox(width: 24),
              _HeaderStat(
                icon: Icons.fitness_center,
                value: '${session.completedExercises}',
                label: 'Exercises',
              ),
              const SizedBox(width: 24),
              _HeaderStat(
                icon: Icons.repeat,
                value: '${session.completedSets}',
                label: 'Sets',
              ),
              const SizedBox(width: 24),
              _HeaderStat(
                icon: Icons.local_fire_department,
                value: '${session.caloriesBurned ?? 0}',
                label: 'Calories',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(BuildContext context) {
    final totalSets = session.totalSets;
    final completedSets = session.completedSets;
    final skippedSets = session.exercises.fold(0, (sum, e) => 
      sum + e.sets.where((s) => s.isSkipped).length);
    final completionRate = totalSets > 0 ? (completedSets / totalSets * 100).round() : 0;

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
            'Overall Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Completion Rate',
                  value: '$completionRate%',
                  subtitle: '$completedSets/$totalSets sets',
                  color: AppTheme.primary,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Skipped Sets',
                  value: '$skippedSets',
                  subtitle: 'Sets skipped',
                  color: AppTheme.warning,
                  icon: Icons.skip_next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseBreakdown(BuildContext context) {
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
            'Exercise Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...session.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _ExerciseDetailCard(
              exercise: exercise,
              index: index + 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    final totalSets = session.totalSets;
    final completedSets = session.completedSets;
    
    String insight;
    Color insightColor;
    IconData insightIcon;

    if (completedSets == totalSets) {
      insight = "Perfect! You completed all sets. Great dedication!";
      insightColor = AppTheme.success;
      insightIcon = Icons.celebration;
    } else if (completedSets >= totalSets * 0.8) {
      insight = "Excellent work! You completed most of your workout.";
      insightColor = AppTheme.success;
      insightIcon = Icons.thumb_up;
    } else if (completedSets >= totalSets * 0.6) {
      insight = "Good effort! Consider completing more sets next time.";
      insightColor = AppTheme.warning;
      insightIcon = Icons.trending_up;
    } else {
      insight = "Keep pushing! Try to complete more sets in your next workout.";
      insightColor = AppTheme.error;
      insightIcon = Icons.fitness_center;
    }

    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: insightColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: insightColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(insightIcon, color: insightColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                color: insightColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Share Workout',
            icon: Icons.share,
            onPressed: () async {
              final summary = _buildShareSummary();
              try {
                await Share.share(summary);
              } catch (e) {
                showCustomSnackBar(
                  context,
                  message: 'Failed to share workout: $e',
                  type: SnackBarType.error,
                );
              }
            },
            variant: AppButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppButton(
            text: 'Back to Home',
            icon: Icons.home,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainScaffold(initialIndex: 1),
                ),
                (route) => false,
              );
            },
            variant: AppButtonVariant.primary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _buildShareSummary() {
    final date = _formatDate(session.startTime);
    final duration = session.duration.inMinutes;
    final exercises = session.exercises.map((e) =>
      '- ${e.exercise.name}: ${e.sets.length} sets x ${e.exercise.reps}').join('\n');
    return '''🏋️ Workout: ${session.plan.name}
Date: $date
Duration: $duration min
Sets: ${session.completedSets}
Exercises:\n$exercises\n
Shared from OptiFit!''';
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;

  const _ExerciseDetailCard({
    required this.exercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final completedSets = exercise.sets.where((s) => s.isCompleted).length;
    final skippedSets = exercise.sets.where((s) => s.isSkipped).length;
    final totalSets = exercise.sets.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.exercise.sets} sets • ${exercise.exercise.reps} reps',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (exercise.isCompleted)
                Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SetIndicator(
                label: 'Completed',
                count: completedSets,
                total: totalSets,
                color: AppTheme.success,
              ),
              const SizedBox(width: 16),
              _SetIndicator(
                label: 'Skipped',
                count: skippedSets,
                total: totalSets,
                color: AppTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetIndicator extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SetIndicator({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count/$total',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 