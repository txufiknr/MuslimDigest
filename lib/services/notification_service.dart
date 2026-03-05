import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/notification_config.dart';

/// Service for managing daily notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize notification service
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'asset://assets/images/icons/icon.png', // App icon
      NotificationConfig.channels,
      debug: true,
    );

    // Request notification permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  static Future<bool> _requestPermissions() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// Get a random notification message
  static String getRandomNotification() {
    // final index = Random().nextInt(NOTIFICATIONS.length);
    // return NOTIFICATIONS[index];
    return (NOTIFICATIONS..shuffle()).first;
  }

  /// Schedule daily notification at 2 AM UTC
  static Future<void> scheduleDailyNotification() async {
    // Cancel any existing scheduled notifications
    await AwesomeNotifications().cancelAllSchedules();

    final notificationMessage = getRandomNotification();

    await AwesomeNotifications().createNotification(
      content: NotificationConfig.getDailyReminderContent(
        id: 1,
        title: APP_NAME,
        body: notificationMessage,
      ),
      schedule: NotificationConfig.getDailySchedule(),
    );

    debugPrint('✅ Daily notification scheduled for 2 AM UTC');
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    debugPrint('❌ All notifications cancelled');
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Show immediate test notification
  static Future<void> showTestNotification() async {
    final notificationMessage = getRandomNotification();

    await AwesomeNotifications().createNotification(
      content: NotificationConfig.getTestContent(
        id: 99,
        title: '$APP_NAME - Test',
        body: notificationMessage,
      ),
    );

    debugPrint('🔔 Test notification sent with icon');
  }

  /// Debug method to verify icon asset
  static void debugIconAsset() {
    const iconPath = 'assets/images/icons/icon.png';
    debugPrint('🔍 Notification icon path: $iconPath');
    debugPrint('📁 Icon asset should be available in pubspec.yaml assets section');
  }
}
