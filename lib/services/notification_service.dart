import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/notification_config.dart';

/// Service for managing daily notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static final Random _random = Random();
  NotificationService._internal();

  /// Generate unique notification ID based on date
  static int generateDateBasedId([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    return int.parse("${targetDate.year}${targetDate.month.toString().padLeft(2, '0')}${targetDate.day.toString().padLeft(2, '0')}");
  }

  /// Get random hour for better user experience (7 AM - 12 PM)
  static int getRandomNotificationHour() {
    const bestHours = [7, 8, 9, 10, 11, 12];
    return bestHours[_random.nextInt(bestHours.length)];
  }

  /// Initialize notification service
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      NotificationConfig.DEFAULT_ICON_SMALL, // App icon
      NotificationConfig.channels,
      channelGroups: NotificationConfig.channelGroups,
      debug: APP_IS_DEVELOPMENT,
    );
    
    // Note: Permission request moved to home page for better UX
    // Channels are automatically created via initialize() method
  }

  /// Request notification permissions with detailed permissions
  static Future<bool> requestPermissions() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isAllowed) return true;
      
      return await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: const [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Light,
          NotificationPermission.Vibration,
          NotificationPermission.PreciseAlarms, // For precise scheduled notifications
        ]
      );
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Get a random notification message
  static String getRandomNotification() {
    return (List<String>.from(NOTIFICATIONS)..shuffle()).first;
  }

  /// Schedule daily notification at random hour (7 AM - 12 PM)
  static Future<void> scheduleDailyNotification() async {
    try {
      // Verify channels are properly initialized first
      await _verifyChannelsInitialized();
      
      // Cancel any existing scheduled notifications
      await AwesomeNotifications().cancelAllSchedules();

      final notificationMessage = getRandomNotification();
      final notificationId = generateDateBasedId();
      final randomHour = getRandomNotificationHour();

      debugPrint('📅 Scheduling notification:');
      debugPrint('  - ID: $notificationId');
      debugPrint('  - Hour: $randomHour:00 UTC');
      debugPrint('  - Message: $notificationMessage');

      await AwesomeNotifications().createNotification(
        content: NotificationConfig.getDailyReminderContent(
          id: notificationId,
          title: APP_NAME,
          body: notificationMessage,
        ),
        schedule: NotificationConfig.getDailySchedule(hour: randomHour),
        actionButtons: NotificationConfig.getDailyReminderActions(),
      );

      debugPrint('✅ Daily notification scheduled successfully for $randomHour:00 UTC with ID: $notificationId');
    } catch (e) {
      debugPrint('❌ Error scheduling daily notification: $e');
      debugPrint('🔄 Attempting recovery...');
      
      // Try recovery with simpler notification
      await _scheduleWithFallback();
    }
  }

  /// Schedule with fallback configuration
  static Future<void> _scheduleWithFallback() async {
    try {
      debugPrint('📡 Using fallback notification configuration');
      
      final notificationMessage = getRandomNotification();
      final notificationId = generateDateBasedId();
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: NotificationConfig.dailyReminderChannelKey,
          title: APP_NAME,
          body: notificationMessage,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          showWhen: true,
          autoDismissible: true,
          payload: {'type': 'daily_reminder_fallback'},
        ),
        schedule: NotificationCalendar(
          hour: 8, // Fixed 8 AM UTC for fallback
          minute: 0,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: false, // Less strict for fallback
          allowWhileIdle: true,
          timeZone: 'UTC',
        ),
      );
      
      debugPrint('✅ Fallback notification scheduled successfully');
    } catch (fallbackError) {
      debugPrint('❌ Fallback scheduling also failed: $fallbackError');
      // Last resort: immediate notification
      await _showImmediateNotification();
    }
  }

  /// Show immediate notification as last resort
  static Future<void> _showImmediateNotification() async {
    try {
      debugPrint('🚨 Showing immediate notification as last resort');
      
      final notificationMessage = getRandomNotification();
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: generateDateBasedId(),
          channelKey: NotificationConfig.dailyReminderChannelKey,
          title: APP_NAME,
          body: notificationMessage,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          showWhen: true,
          autoDismissible: true,
          payload: {'type': 'immediate_reminder'},
        ),
      );
      
      debugPrint('✅ Immediate notification shown successfully');
    } catch (immediateError) {
      debugPrint('❌ All notification methods failed: $immediateError');
    }
  }

  /// Verify that notification channels are properly initialized
  static Future<void> _verifyChannelsInitialized() async {
    try {
      // Small delay to ensure channels are registered
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('🔍 Notification channels verified');
    } catch (e) {
      debugPrint('⚠️ Channel verification warning: $e');
      // Continue anyway as channels should be created during initialize
    }
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
    try {
      debugPrint('🧪 Creating test notification...');
      
      final notificationMessage = getRandomNotification();
      final notificationId = generateDateBasedId();

      await AwesomeNotifications().createNotification(
        content: NotificationConfig.getTestContent(
          id: notificationId,
          title: '$APP_NAME - Test',
          body: notificationMessage,
        ),
      );

      debugPrint('✅ Test notification sent successfully with ID: $notificationId');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
      
      // Try simple fallback
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: generateDateBasedId(),
            channelKey: NotificationConfig.testChannelKey,
            title: '$APP_NAME - Test',
            body: 'Test notification',
            payload: {'type': 'test_fallback'},
          ),
        );
        debugPrint('✅ Fallback test notification sent');
      } catch (fallbackError) {
        debugPrint('❌ Fallback test notification failed: $fallbackError');
      }
    }
  }

  /// Debug method to verify icon asset
  static void debugIconAsset() {
    const iconPath = 'assets/images/icons/icon.png';
    debugPrint('🔍 Notification icon path: $iconPath');
    debugPrint('📁 Icon asset should be available in pubspec.yaml assets section');
  }

}
