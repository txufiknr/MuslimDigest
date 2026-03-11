import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:muslimdigest/config/constants.dart';

/// Controller for handling notification events
class NotificationController {
  /// Handle notification actions (taps, buttons, etc.)
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    debugPrint('🔔 Notification action received: ${receivedAction.payload}');
    
    final data = receivedAction.payload;
    if (data == null) {
      debugPrint('⚠️ No payload data in notification');
      return;
    }

    // Handle button actions
    if (receivedAction.buttonKeyPressed.isNotEmpty) {
      await _handleButtonAction(receivedAction.buttonKeyPressed, data);
      return;
    }

    // Handle notification tap (no button pressed)
    await _handleNotificationTap(data);
  }

  /// Handle button-specific actions
  static Future<void> _handleButtonAction(String buttonKey, Map<String, String?> data) async {
    try {
      switch (buttonKey) {
        case 'OPEN_APP':
          debugPrint('📱 Open app button pressed');
          // Navigate to main app content
          await _navigateToMainContent();
          break;
          
        case 'SHARE':
          debugPrint('📤 Share button pressed');
          await _shareContent(data);
          break;
          
        default:
          debugPrint('🤷 Unknown button action: $buttonKey');
      }
    } catch (e) {
      debugPrint('❌ Error handling button action $buttonKey: $e');
    }
  }

  /// Handle notification tap (no button)
  static Future<void> _handleNotificationTap(Map<String, String?> data) async {
    debugPrint('👆 Notification tapped');
    
    // For now, just navigate to main content
    // The existing scheduler handler can be called if needed
    await _navigateToMainContent();
  }

  /// Share notification content
  static Future<void> _shareContent(Map<String, String?> data) async {
    try {
      final title = data['title'] ?? 'Islamic Reminder';
      final body = data['body'] ?? 'Daily Islamic inspiration';
      
      await sharePlus.share(
        ShareParams(
          title: title,
          subject: body,
          text: SHARE_MESSAGE,
        ),
      );
      debugPrint('✅ Content shared successfully');
    } catch (e) {
      debugPrint('❌ Error sharing content: $e');
    }
  }

  /// Navigate to main app content
  static Future<void> _navigateToMainContent() async {
    try {
      // This would typically use your navigation system (like GoRouter)
      // For now, we'll just log the navigation intent
      debugPrint('🧭 Navigating to main content');
      // Example: context.go('/home');
    } catch (e) {
      debugPrint('❌ Error navigating to main content: $e');
    }
  }

  /// Handle notification creation
  static Future<void> onNotificationCreated(ReceivedNotification receivedNotification) async {
    debugPrint('💭 Notification created: ${receivedNotification.id}');
  }

  /// Handle notification display
  static Future<void> onNotificationDisplayed(ReceivedNotification receivedNotification) async {
    debugPrint('👀 Notification displayed: ${receivedNotification.id}');
  }

  /// Handle notification dismissal
  static Future<void> onDismissActionReceived(ReceivedAction receivedAction) async {
    debugPrint('❌ Notification dismissed: ${receivedAction.payload}');
  }
}
