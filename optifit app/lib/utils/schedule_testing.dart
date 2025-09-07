import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../models/schedule_models.dart';

class ScheduleTestingUtils {
  static final NotificationService _notificationService = NotificationService();
  static final ScheduleService _scheduleService = ScheduleService();

  // Test notification scheduling
  static Future<void> testNotificationScheduling() async {
    if (!kDebugMode) return;

    debugPrint('=== Testing Notification Scheduling ===');

    // Test 1: Schedule a workout 2 minutes from now
    final testTime = DateTime.now().add(const Duration(minutes: 2));

    await _notificationService.scheduleWorkoutNotifications(
      workoutName: 'Test Workout',
      scheduledTime: testTime,
      dateKey: 'test-${DateTime.now().millisecondsSinceEpoch}',
      workoutIndex: 0,
    );

    debugPrint('Scheduled test workout for: $testTime');

    // Test 2: Check pending notifications
    final pending = await _notificationService.getPendingNotifications();
    debugPrint('Pending notifications: ${pending.length}');

    for (final notification in pending) {
      debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }

  // Run all tests
  static Future<void> runAllTests() async {
    if (!kDebugMode) return;

    debugPrint('\n🧪 Starting Schedule Feature Tests\n');

    await testNotificationScheduling();

    debugPrint('\n✅ All tests completed\n');
  }
}
