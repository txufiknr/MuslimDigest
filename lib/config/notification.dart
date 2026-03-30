import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/config/colors.dart';

/// Configuration for notification channels and settings
class NotificationConfig {
  /// Channel group key for Islamic reminders
  static const String islamicRemindersGroupKey = 'islamic_reminders';
  
  /// Channel key for daily reminders
  static const String dailyReminderChannelKey = 'daily_reminder';
  
  /// Channel key for test notifications
  static const String testChannelKey = 'test_notifications';
  
  /// Default notification color (purple theme)
  static const Color defaultColor = AppColors.primary;
  
  /// LED color for notifications
  static const Color ledColor = Colors.white;

  static const DEFAULT_ICON_LARGE = 'resource://drawable/res_logo';
  static const DEFAULT_ICON_SMALL = 'resource://drawable/res_favicon';

  /// Get all notification channel groups
  static List<NotificationChannelGroup> get channelGroups => [
    NotificationChannelGroup(
      channelGroupKey: islamicRemindersGroupKey,
      channelGroupName: 'Islamic Reminders',
    ),
  ];

  /// Get all notification channels
  static List<NotificationChannel> get channels => [
    NotificationChannel(
      channelKey: dailyReminderChannelKey,
      channelName: 'Daily Islamic Reminders',
      channelDescription: 'Daily inspirational Islamic notifications to brighten your day',
      channelGroupKey: islamicRemindersGroupKey,
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
      channelGroupKey: islamicRemindersGroupKey,
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
      notificationLayout: NotificationLayout.BigText,
      category: NotificationCategory.Reminder,
      showWhen: true,
      autoDismissible: true,
      backgroundColor: defaultColor,
      displayOnBackground: true,
      displayOnForeground: true,
      wakeUpScreen: false,
      fullScreenIntent: false,
      criticalAlert: false,
      icon: DEFAULT_ICON_SMALL,
      largeIcon: DEFAULT_ICON_LARGE,
      payload: {'type': 'daily_reminder', 'id': id.toString()},
    );
  }

  /// Get action buttons for daily reminder
  static List<NotificationActionButton> getDailyReminderActions() => [
    NotificationActionButton(
      key: 'OPEN_APP',
      label: 'Open App',
    ),
    NotificationActionButton(
      key: 'SHARE',
      label: 'Share',
    ),
  ];

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
      icon: DEFAULT_ICON_SMALL,
      largeIcon: DEFAULT_ICON_LARGE,
      payload: {'type': 'test'},
    );
  }

  /// Get notification schedule for daily at random hour (7 AM - 12 PM)
  /// 
  /// Creates a NotificationCalendar that repeats indefinitely.
  /// The `repeats: true` flag is the key to long-term daily scheduling.
  /// 
  /// How this works for long-term scheduling:
  /// - No end date specified = repeats forever
  /// - System handles daily triggers automatically
  /// - Survives app restarts, device reboots, and app updates
  /// - UTC timezone ensures consistent timing globally
  /// 
  /// Note: Only ONE notification needs to be created with this schedule.
  /// The Android/iOS notification systems will handle the daily repetition.
  static NotificationCalendar getDailySchedule({int? hour}) {
    final scheduleHour = hour ?? 8; // Default to 8 AM if not specified
    return NotificationCalendar(
      hour: scheduleHour,
      minute: 0,
      second: 0,
      millisecond: 0,
      repeats: true, // Repeat daily
      preciseAlarm: true,
      allowWhileIdle: true,
      timeZone: 'UTC',
    );
  }

  /// Get notification schedule for specific date
  static NotificationCalendar getSpecificDateSchedule(DateTime dateTime) {
    return NotificationCalendar(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      hour: dateTime.hour,
      minute: dateTime.minute,
      second: 0,
      millisecond: 0,
      preciseAlarm: true,
      allowWhileIdle: true,
      timeZone: 'UTC',
    );
  }
}
