import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/services/notifications/notification_service.dart';
import 'package:muslimdigest/services/notifications/notification_controller.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/variables/settings.dart';
import 'package:muslimdigest/config/notification_config.dart';
import 'package:muslimdigest/config/constants.dart';

/// Helper class for managing notification scheduling and lifecycle
/// 
/// Daily Notification Architecture:
/// 1. Creates ONE notification with `repeats: true` flag
/// 2. System handles daily repetition automatically
/// 3. No need to reschedule every day
/// 4. Continues indefinitely until manually cancelled
/// 
/// Key Methods:
/// - initialize(): Sets up notification system without permissions
/// - requestPermissionsAndSchedule(): Gets permissions and schedules daily notification
/// - rescheduleDailyNotification(): Handles app updates/restarts
/// - handlePreferenceChange(): Enables/disables based on user settings
class NotificationScheduler {
  /// Initialize notifications without requesting permissions (for app startup)
  static Future<void> initialize() async {
    try {
      // Initialize the notification service only (no permission request)
      await NotificationService.initialize();
      
      // Set up notification listeners for foreground notifications
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceived,
        onNotificationCreatedMethod: NotificationController.onNotificationCreated,
        onNotificationDisplayedMethod: NotificationController.onNotificationDisplayed,
        onDismissActionReceivedMethod: NotificationController.onDismissActionReceived,
      );
      
      debugPrint('📅 Notification system initialized (permissions not requested yet)');
    } catch (e) {
      debugPrint('❌ Error initializing notification system: $e');
      // Add retry logic for initialization
      if (e.toString().contains('MediaSource.Resource')) {
        debugPrint('🔄 Icon asset issue detected, continuing without custom icon');
        // Retry with default icon
        try {
          await AwesomeNotifications().initialize(
            null, // Use default app icon
            NotificationConfig.channels,
            debug: APP_IN_DEVELOPMENT,
          );
          debugPrint('✅ Notification system initialized with default icon');
        } catch (retryError) {
          debugPrint('❌ Initialization retry failed: $retryError');
        }
      }
    }
  }

  /// Request permissions and schedule daily reminder (called from home page)
  static Future<void> requestPermissionsAndSchedule() async {
    try {
      // Request notification permissions
      final areAllowed = await NotificationService.requestPermissions();
      
      if (areAllowed) {
        debugPrint('✅ Notification permissions granted');
        // Schedule the daily notification if user preference allows
        await _scheduleIfPreferenceAllows();
      } else {
        debugPrint('⚠️ Notification permissions denied');
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }

  /// Schedule daily reminder based on user preference (internal method)
  static Future<void> _scheduleIfPreferenceAllows() async {
    try {
      // Check user's notification preference
      final notificationType = PrefData.notificationType;
      
      if (notificationType != NotificationType.none) {
        // Schedule the daily notification for 'all' or 'digest' types
        await _scheduleWithRetry();
        debugPrint('📅 Daily notification scheduled with randomized timing (7 AM - 12 PM UTC)');
      } else {
        debugPrint('📅 Notifications disabled by user preference');
      }
    } catch (e) {
      debugPrint('❌ Error scheduling daily notification: $e');
      // Retry with delay if it's a channel issue
      if (e.toString().contains('channel')) {
        debugPrint('🔄 Retrying notification scheduling after delay...');
        await Future.delayed(const Duration(seconds: 2));
        try {
          await _scheduleWithRetry();
          debugPrint('✅ Retry successful - daily notification scheduled');
        } catch (retryError) {
          debugPrint('❌ Retry failed: $retryError');
        }
      }
    }
  }

  /// Schedule notification with retry logic
  static Future<void> _scheduleWithRetry() async {
    try {
      await NotificationService.scheduleDailyNotification();
    } catch (e) {
      debugPrint('❌ First attempt failed: $e');
      // Wait a moment and try again
      await Future.delayed(const Duration(milliseconds: 500));
      await NotificationService.scheduleDailyNotification();
    }
  }

  /// Reschedule daily notification (useful after app updates)
  static Future<void> rescheduleDailyNotification() async {
    try {
      // Check user preference before rescheduling
      final notificationType = PrefData.notificationType;
      
      if (notificationType != NotificationType.none) {
        await _scheduleIfPreferenceAllows();
        debugPrint('🔄 Daily notification rescheduled');
      } else {
        debugPrint('🔄 Skipping reschedule - notifications disabled by user');
      }
    } catch (e) {
      debugPrint('❌ Error rescheduling daily notification: $e');
    }
  }

  /// Handle notification preference change
  static Future<void> handlePreferenceChange(NotificationType newType) async {
    try {
      if (newType == NotificationType.none) {
        // Disable all notifications
        await NotificationService.cancelAllNotifications();
        debugPrint('🔕 Notifications disabled by user preference');
      } else {
        // Enable daily notifications (both 'all' and 'digest' are the same)
        await _scheduleIfPreferenceAllows();
        debugPrint('🔔 Notifications enabled by user preference: ${newType.name}');
      }
    } catch (e) {
      debugPrint('❌ Error handling preference change: $e');
    }
  }

  /// Handle notification received when app is in foreground
  static void handleForegroundNotification(ReceivedAction receivedAction) {
    debugPrint('🔔 Foreground notification received: ${receivedAction.payload}');
    
    // Handle different notification types
    final notificationType = receivedAction.payload?['type'];
    
    switch (notificationType) {
      case 'daily_reminder':
        _handleDailyReminder(receivedAction);
        break;
      case 'test':
        _handleTestNotification(receivedAction);
        break;
      default:
        debugPrint('🤷 Unknown notification type: $notificationType');
    }
  }

  /// Handle daily reminder notification
  static void _handleDailyReminder(ReceivedAction receivedAction) {
    debugPrint('📖 Daily reminder notification tapped');
    // You can navigate to a specific screen or perform an action
    // For example, navigate to the home screen or open today's digest
  }

  /// Handle test notification
  static void _handleTestNotification(ReceivedAction receivedAction) {
    debugPrint('🧪 Test notification tapped');
    // Handle test notification actions
  }

  /// Get notification status information
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final areAllowed = await NotificationService.areNotificationsEnabled();
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();
      
      return {
        'areAllowed': areAllowed,
        'scheduledCount': scheduledNotifications.length,
        'scheduledNotifications': scheduledNotifications.map((n) => {
          'id': n.content?.id,
          'title': n.content?.title,
          'body': n.content?.body,
          'scheduledTime': n.schedule?.toString(),
        }).toList(),
      };
    } catch (e) {
      debugPrint('❌ Error getting notification status: $e');
      return {
        'areAllowed': false,
        'scheduledCount': 0,
        'scheduledNotifications': [],
        'error': e.toString(),
      };
    }
  }

  /// Debug method to print current notification status
  static Future<void> debugNotificationStatus() async {
    final status = await getNotificationStatus();
    debugPrint('📊 Notification Status:');
    debugPrint('  - Allowed: ${status['areAllowed']}');
    debugPrint('  - Scheduled: ${status['scheduledCount']} notifications');
    
    if (status['scheduledNotifications'].isNotEmpty) {
      debugPrint('  - Scheduled notifications:');
      for (final notification in status['scheduledNotifications']) {
        debugPrint('    * ID: ${notification['id']} - ${notification['title']}');
      }
    }
  }
}
