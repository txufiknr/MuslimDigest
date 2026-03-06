import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/utils/notification_scheduler.dart';

/// Controller for handling notification events
class NotificationController {
  /// Handle notification actions (taps, buttons, etc.)
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    debugPrint('🔔 Notification action received: ${receivedAction.payload}');
    
    // Handle the notification action using the scheduler
    NotificationScheduler.handleForegroundNotification(receivedAction);
  }

  /// Handle notification creation
  static Future<void> onNotificationCreated(ReceivedNotification receivedNotification) async {
    debugPrint('📝 Notification created: ${receivedNotification.id}');
  }

  /// Handle notification display
  static Future<void> onNotificationDisplayed(ReceivedNotification receivedNotification) async {
    debugPrint('👁️ Notification displayed: ${receivedNotification.id}');
  }

  /// Handle notification dismissal
  static Future<void> onDismissActionReceived(ReceivedAction receivedAction) async {
    debugPrint('❌ Notification dismissed: ${receivedAction.payload}');
  }
}
