import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/config/colors.dart';

/// Configuration for notification channels and settings
class NotificationConfig {
  /// Channel key for daily reminders
  static const String dailyReminderChannelKey = 'daily_reminder';
  
  /// Channel key for test notifications
  static const String testChannelKey = 'test_notifications';
  
  /// Default notification color (purple theme)
  static const Color defaultColor = AppColors.primary;
  
  /// LED color for notifications
  static const Color ledColor = Colors.white;

  /// Get all notification channels
  static List<NotificationChannel> get channels => [
    NotificationChannel(
      channelKey: dailyReminderChannelKey,
      channelName: 'Daily Islamic Reminders',
      channelDescription: 'Daily inspirational Islamic notifications to brighten your day',
      defaultColor: defaultColor,
      ledColor: ledColor,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      criticalAlerts: true,
      playSound: true,
      enableVibration: true,
      defaultRingtoneType: DefaultRingtoneType.Notification,
    ),
    NotificationChannel(
      channelKey: testChannelKey,
      channelName: 'Test Notifications',
      channelDescription: 'Notifications for testing purposes',
      defaultColor: defaultColor,
      ledColor: ledColor,
      importance: NotificationImportance.Default,
      channelShowBadge: true,
      playSound: true,
      enableVibration: true,
      defaultRingtoneType: DefaultRingtoneType.Notification,
    ),
  ];

  /// Get notification content for daily reminder
  static NotificationContent getDailyReminderContent({
    required int id,
    required String title,
    required String body,
  }) {
    return NotificationContent(
      id: id,
      channelKey: dailyReminderChannelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      category: NotificationCategory.Reminder,
      showWhen: true,
      autoDismissible: true,
      backgroundColor: defaultColor,
      displayOnBackground: true,
      displayOnForeground: true,
      wakeUpScreen: false,
      fullScreenIntent: false,
      criticalAlert: false,
      largeIcon: 'asset://assets/images/icons/icon.png',
      payload: {'type': 'daily_reminder'},
    );
  }

  /// Get notification content for test notification
  static NotificationContent getTestContent({
    required int id,
    required String title,
    required String body,
  }) {
    return NotificationContent(
      id: id,
      channelKey: testChannelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      category: NotificationCategory.Reminder,
      showWhen: true,
      autoDismissible: true,
      backgroundColor: defaultColor,
      largeIcon: 'asset://assets/images/icons/icon.png',
      payload: {'type': 'test'},
    );
  }

  /// Get notification schedule for daily 2 AM UTC
  static NotificationCalendar getDailySchedule() {
    return NotificationCalendar(
      hour: 2, // 2 AM UTC
      minute: 0,
      second: 0,
      millisecond: 0,
      repeats: true, // Repeat daily
      preciseAlarm: true,
      allowWhileIdle: true,
      timeZone: 'UTC',
    );
  }
}
