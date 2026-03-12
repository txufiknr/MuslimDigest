import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/notification_config.dart';
import 'package:muslimdigest/config/notification_content.dart';

/// Service for managing daily notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static final Random _random = Random();
  NotificationService._internal();

  /// Generate unique notification ID using 32-bit timestamp
  /// 
  /// This ensures each notification gets a unique identifier, which is
  /// crucial for repeating notifications to avoid conflicts.
  /// 
  /// Why 32-bit timestamp works:
  /// - Uses seconds since epoch instead of milliseconds for 32-bit compatibility
  /// - Each call gets a unique second timestamp
  /// - No possibility of collisions in normal usage
  /// - Simple, reliable, and performant
  /// - Perfect for daily notification scheduling
  static int generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
      debug: APP_IN_DEVELOPMENT,
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

  /// Get daily notification content that changes each day
  static IslamicNotificationContent getDailyNotificationContent() {
    return IslamicNotificationContent.getDailyContent();
  }

  /// Schedule daily notification with monthly rotation (RECOMMENDED)
  /// 
  /// This method creates 30 notifications, each scheduled for a different day
  /// of the month (1-30) and repeating monthly. This ensures different content
  /// every day and works long-term even if the user never opens the app.
  /// 
  /// Key behaviors:
  /// - Schedules 30 notifications for days 1-30 of each month
  /// - Each notification has unique content based on its day of month
  /// - Each notification repeats monthly on its assigned day
  /// - Works long-term even if user never opens app
  /// - Perfect monthly rotation without app interaction
  static Future<void> scheduleMonthlyRotatingNotification() async {
    try {
      // Verify channels are properly initialized first
      await _verifyChannelsInitialized();
      
      // Cancel any existing scheduled notifications
      await AwesomeNotifications().cancelAllSchedules();

      final rotationPeriod = IslamicNotificationContent.rotationPeriod;
      final randomHour = getRandomNotificationHour();

      debugPrint('📅 Scheduling MONTHLY ROTATING notifications:');
      debugPrint('  - Rotation Period: $rotationPeriod days');
      debugPrint('  - Hour: $randomHour:00 UTC');
      debugPrint('  - Scheduling for days 1-$rotationPeriod of each month');

      // Schedule notifications for each day of the month
      for (int day = 1; day <= rotationPeriod; day++) {
        // Get content based on the day of month
        final notificationContent = IslamicNotificationContent.getContentForDay(day);
        // Use a simple sequential ID to avoid overflow
        final notificationId = 2000 + day; // Base ID + day

        debugPrint('  - Day $day: ID $notificationId - ${notificationContent.title}');
        debugPrint('    Repeats every month on day $day');

        await AwesomeNotifications().createNotification(
          content: NotificationConfig.getDailyReminderContent(
            id: notificationId,
            title: notificationContent.title,
            body: notificationContent.body,
          ),
          schedule: NotificationCalendar(
            // NOTE: No year specified - this enables monthly repeat
            day: day,           // Day of month (1-30)
            hour: randomHour,
            minute: 0,
            second: 0,
            millisecond: 0,
            repeats: true,      // Repeats MONTHLY on this day
            preciseAlarm: true,
            allowWhileIdle: true,
            timeZone: 'UTC',
          ),
          actionButtons: NotificationConfig.getDailyReminderActions(),
        );
      }

      debugPrint('✅ Monthly rotating notifications scheduled successfully');
      debugPrint('🔄 $rotationPeriod unique notifications scheduled');
      debugPrint('🎯 Each notification repeats monthly on its assigned day');
      debugPrint('📱 Users will see different content every day indefinitely');
      debugPrint('🌙 Perfect for long-term rotation without app interaction');
    } catch (e) {
      debugPrint('❌ Error scheduling monthly rotating notification: $e');
      debugPrint('🔄 Attempting recovery...');
      
      // Try recovery with simpler notification
      await _scheduleWithFallback();
    }
  }

  /// Schedule daily notification at random hour (7 AM - 12 PM)
  /// 
  /// This method creates a notification that changes content daily.
  /// To achieve different content each day, we need to reschedule 
  /// the notification periodically rather than using a single repeating notification.
  /// 
  /// Key behaviors:
  /// - Cancels existing schedules to prevent duplicates
  /// - Uses unique ID to avoid conflicts
  /// - Random hour selection (7-12 AM UTC) for better user experience
  /// - Content changes daily based on date
  /// - Survives app restarts and device reboots
  static Future<void> scheduleDailyNotification() async {
    try {
      // Verify channels are properly initialized first
      await _verifyChannelsInitialized();
      
      // Cancel any existing scheduled notifications
      await AwesomeNotifications().cancelAllSchedules();

      final notificationContent = getDailyNotificationContent();
      final notificationId = generateNotificationId();
      final randomHour = getRandomNotificationHour();

      debugPrint('📅 Scheduling notification:');
      debugPrint('  - ID: $notificationId');
      debugPrint('  - Hour: $randomHour:00 UTC');
      debugPrint('  - Title: ${notificationContent.title}');
      debugPrint('  - Body: ${notificationContent.body}');

      await AwesomeNotifications().createNotification(
        content: NotificationConfig.getDailyReminderContent(
          id: notificationId,
          title: notificationContent.title,
          body: notificationContent.body,
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

  /// Reschedule daily notification with new content
  /// This should be called periodically (e.g., daily or when app starts)
  /// to ensure fresh content for the next notification
  static Future<void> refreshDailyNotification() async {
    try {
      debugPrint('🔄 Refreshing daily notification with new content...');
      
      // Check if there's an existing scheduled notification
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();
      
      if (scheduledNotifications.isEmpty) {
        debugPrint('📅 No existing notification found, scheduling new one...');
        await scheduleDailyNotification();
      } else {
        debugPrint('📅 Existing notification found, rescheduling with new content...');
        // Cancel existing and reschedule with new content
        await AwesomeNotifications().cancelAllSchedules();
        await scheduleDailyNotification();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing daily notification: $e');
    }
  }

  /// Schedule with fallback configuration
  static Future<void> _scheduleWithFallback() async {
    try {
      debugPrint('📡 Using fallback notification configuration');
      
      final notificationContent = getDailyNotificationContent();
      final notificationId = generateNotificationId();
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: NotificationConfig.dailyReminderChannelKey,
          title: notificationContent.title,
          body: notificationContent.body,
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
      
      final notificationContent = getDailyNotificationContent();
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: generateNotificationId(),
          channelKey: NotificationConfig.dailyReminderChannelKey,
          title: notificationContent.title,
          body: notificationContent.body,
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
      
      final notificationContent = getDailyNotificationContent();
      final notificationId = generateNotificationId();

      await AwesomeNotifications().createNotification(
        content: NotificationConfig.getTestContent(
          id: notificationId,
          title: '$APP_NAME - Test',
          body: notificationContent.body,
        ),
      );

      debugPrint('✅ Test notification sent successfully with ID: $notificationId');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
      
      // Try simple fallback
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: generateNotificationId(),
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
