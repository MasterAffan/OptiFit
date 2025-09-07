import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../main.dart';
import '../screens/schedule_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String _workoutChannelId = 'workout_reminders';
  static const String _workoutChannelName = 'Workout Reminders';
  static const String _workoutChannelDescription = 'Notifications for scheduled workouts';

  Future<void> initialize() async {
    print('🔧 Initializing notification service...');

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    final initialized = await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('📱 Notification plugin initialized: $initialized');

    // Create notification channel for Android
    await _createNotificationChannel();

    print('✅ Notification service initialization complete');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _workoutChannelId,
      _workoutChannelName,
      description: _workoutChannelDescription,
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('📢 Android notification channel created');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    if (response.payload == null) return;
       final data = json.decode(response.payload!);

       // Push named route via global navigatorKey
       navigatorKey.currentState?.pushNamed(
         ScheduleScreen.routeName,
         arguments: data,
       );
  }

  Future<bool> requestPermissions() async {
    print('🔐 Requesting notification permissions...');

    bool granted = false;

    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      final status = await Permission.notification.request();
      granted = status == PermissionStatus.granted;

      print('📱 Android notification permission: $status');

      // For Android 12+ (API 31+) - exact alarm permission
      if (granted) {
        try {
          final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
          print('⏰ Exact alarm permission: $exactAlarmStatus');
        } catch (e) {
          print('⚠️ Exact alarm permission not available: $e');
        }
      }

    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }

      print('🍎 iOS notification permission: $granted');
    }

    print('✅ Notification permissions granted: $granted');
    return granted;
  }

  Future<void> scheduleWorkoutNotifications({
    required String workoutName,
    required DateTime scheduledTime,
    required String dateKey,
    required int workoutIndex,
  }) async {
    print('📅 Scheduling notifications for: $workoutName at $scheduledTime');

    // Cancel any existing notifications for this workout
    await cancelWorkoutNotifications(dateKey, workoutIndex);

    // Check if the scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      print('⚠️ Scheduled time is in the past, skipping notifications');
      return;
    }

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledTime, tz.local);
    print('🌍 Scheduled time in timezone: $scheduledTZ');

    // For testing: Schedule a notification 1 minute from now
    if (kDebugMode) {
      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      await _scheduleNotification(
        id: 99999, // Test ID
        title: 'Test Notification',
        body: 'This is a test notification for $workoutName! 🧪',
        scheduledTime: testTime,
        payload: json.encode({
          'type': 'workout_reminder',
          'workoutName': workoutName,
          'dateKey': dateKey,
          'workoutIndex': workoutIndex,
          'minutesBefore': 0,
        }),
      );
      print('🧪 Test notification scheduled for: $testTime');
    }

    // Schedule 30 minutes before
    final thirtyMinBefore = scheduledTZ.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _scheduleNotification(
        id: _getNotificationId(dateKey, workoutIndex, 30),
        title: 'Workout Reminder',
        body: '$workoutName starts in 30 minutes! Get ready to crush your goals! 💪',
        scheduledTime: thirtyMinBefore,
        payload: json.encode({
          'type': 'workout_reminder',
          'workoutName': workoutName,
          'dateKey': dateKey,
          'workoutIndex': workoutIndex,
          'minutesBefore': 30,
        }),
      );
      print('⏰ 30-min notification scheduled for: $thirtyMinBefore');
    }

    // Schedule 10 minutes before
    final tenMinBefore = scheduledTZ.subtract(const Duration(minutes: 10));
    if (tenMinBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _scheduleNotification(
        id: _getNotificationId(dateKey, workoutIndex, 10),
        title: 'Workout Starting Soon!',
        body: '$workoutName starts in 10 minutes! Time to get moving! ⏰',
        scheduledTime: tenMinBefore,
        payload: json.encode({
          'type': 'workout_reminder',
          'workoutName': workoutName,
          'dateKey': dateKey,
          'workoutIndex': workoutIndex,
          'minutesBefore': 10,
        }),
      );
      print('⏰ 10-min notification scheduled for: $tenMinBefore');
    }

    // Schedule at exact time
    if (scheduledTZ.isAfter(tz.TZDateTime.now(tz.local))) {
      await _scheduleNotification(
        id: _getNotificationId(dateKey, workoutIndex, 0),
        title: 'Workout Time!',
        body: 'Your $workoutName is starting now! Let\'s do this! 🔥',
        scheduledTime: scheduledTZ,
        payload: json.encode({
          'type': 'workout_reminder',
          'workoutName': workoutName,
          'dateKey': dateKey,
          'workoutIndex': workoutIndex,
          'minutesBefore': 0,
        }),
      );
      print('⏰ Exact time notification scheduled for: $scheduledTZ');
    }

    // Show pending notifications count
    final pending = await getPendingNotifications();
    print('📊 Total pending notifications: ${pending.length}');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _workoutChannelId,
        _workoutChannelName,
        channelDescription: _workoutChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          '',
          contentTitle: null,
          htmlFormatContentTitle: false,
          summaryText: null,
          htmlFormatSummaryText: false,
        ),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'workout_reminder',
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Notification $id scheduled successfully for $scheduledTime');
    } catch (e) {
      print('❌ Failed to schedule notification $id: $e');
    }
  }

  int _getNotificationId(String dateKey, int workoutIndex, int minutesBefore) {
    final dateHash = dateKey.hashCode.abs() % 10000;
    return dateHash + (workoutIndex * 1000) + minutesBefore;
  }

  Future<void> cancelWorkoutNotifications(String dateKey, int workoutIndex) async {
    final ids = [
      _getNotificationId(dateKey, workoutIndex, 30),
      _getNotificationId(dateKey, workoutIndex, 10),
      _getNotificationId(dateKey, workoutIndex, 0),
    ];

    for (final id in ids) {
      await _notificationsPlugin.cancel(id);
    }

    print('🗑️ Cancelled notifications for workout $workoutIndex on $dateKey');
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Test method to show immediate notification
  Future<void> showTestNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _workoutChannelId,
        _workoutChannelName,
        channelDescription: _workoutChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      12345,
      'Test Notification',
      'If you see this, notifications are working! 🎉',
      notificationDetails,
    );
  }
}

class NotificationNavigationHandler {
  static Function(Map<String, dynamic>)? _onNotificationTapped;

  static void setNotificationHandler(Function(Map<String, dynamic>) handler) {
    _onNotificationTapped = handler;
    print('🔗 Notification handler set');
  }

  static void handleNotificationTap(Map<String, dynamic> data) {
    print('📱 Handling notification tap: $data');
    _onNotificationTapped?.call(data);
  }
}
