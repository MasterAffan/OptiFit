import 'package:flutter/material.dart';

class ScheduledWorkout {
  final String id;
  final String workout;
  final String time;
  final DateTime scheduledDate;
  final Color color;
  final bool notificationsEnabled;
  final DateTime createdAt;

  ScheduledWorkout({
    required this.id,
    required this.workout,
    required this.time,
    required this.scheduledDate,
    required this.color,
    this.notificationsEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout': workout,
      'time': time,
      'scheduledDate': scheduledDate.toIso8601String(),
      'color': color.value,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduledWorkout.fromJson(Map<String, dynamic> json) {
    return ScheduledWorkout(
      id: json['id'],
      workout: json['workout'],
      time: json['time'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      color: Color(json['color']),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  ScheduledWorkout copyWith({
    String? id,
    String? workout,
    String? time,
    DateTime? scheduledDate,
    Color? color,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return ScheduledWorkout(
      id: id ?? this.id,
      workout: workout ?? this.workout,
      time: time ?? this.time,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      color: color ?? this.color,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime get fullScheduledDateTime {
    final timeParts = time.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final period = timeParts[1];

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );
  }

  bool get isUpcoming {
    return fullScheduledDateTime.isAfter(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }
}

class NotificationSettings {
  final bool thirtyMinutesEnabled;
  final bool tenMinutesEnabled;
  final bool exactTimeEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    this.thirtyMinutesEnabled = true,
    this.tenMinutesEnabled = true,
    this.exactTimeEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'thirtyMinutesEnabled': thirtyMinutesEnabled,
      'tenMinutesEnabled': tenMinutesEnabled,
      'exactTimeEnabled': exactTimeEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      thirtyMinutesEnabled: json['thirtyMinutesEnabled'] ?? true,
      tenMinutesEnabled: json['tenMinutesEnabled'] ?? true,
      exactTimeEnabled: json['exactTimeEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }
}
