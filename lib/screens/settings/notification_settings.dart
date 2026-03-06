import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/selection_option.dart';
import 'package:muslimdigest/variables/settings.dart';
import 'package:muslimdigest/services/notification_service.dart';
import 'package:muslimdigest/utils/notification_scheduler.dart';

class NotificationSettings extends ConsumerStatefulWidget {
  const NotificationSettings({super.key});

  @override
  ConsumerState<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends ConsumerState<NotificationSettings> {
  NotificationType get _selectedType => PrefData.notificationType;
  bool _isLoading = false;
  bool _notificationsEnabled = false;
  int _scheduledCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final areAllowed = await NotificationService.areNotificationsEnabled();
      final status = await NotificationScheduler.getNotificationStatus();
      
      setState(() {
        _notificationsEnabled = areAllowed;
        _scheduledCount = status['scheduledCount'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading notification status: $e');
    }
  }

  Future<void> _onNotificationTypeChanged(NotificationType type) async {
    // Save preference
    await prefs.setString('notification_type', type.name);
    
    // Handle notification preference change
    await NotificationScheduler.handlePreferenceChange(type);
    
    setState(() {});
    await _loadNotificationStatus();
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.showTestNotification();
      if (mounted) {
        showSnackBarSuccess(context, "$APP_NAME test notification sent!");
      }
    } catch (e) {
      if (mounted) {
        showSnackBarError(context, "Failed to send test notification");
        debugPrint('Failed to send test notification: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification status card
        if (_isLoading)
          const CupertinoActivityIndicator()
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _notificationsEnabled ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash_fill,
                  color: _notificationsEnabled ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _notificationsEnabled ? 'Notifications Enabled' : 'Notifications Disabled',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Scheduled: $_scheduledCount notification(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Notification type selections
        ...NotificationType.values.map((type) => SelectionOption<NotificationType>(
          value: type,
          groupValue: _selectedType,
          label: type.label,
          icon: type.icon,
          onChanged: _onNotificationTypeChanged,
          fullWidth: true,
        ).withPadding(bottom: 8)),
        
        const SizedBox(height: 16),
        
        // Test notification button
        MyButton(
          text: "Send Test Notification",
          onPressed: _sendTestNotification,
        ),
        
        const SizedBox(height: 12),
        
        // Close button
        MyButton(text: "Close", outlined: true, onPressed: context.pop),
      ],
    );
  }
}