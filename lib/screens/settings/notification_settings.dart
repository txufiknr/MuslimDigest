import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/selection_option.dart';
import 'package:muslimdigest/variables/settings.dart';

class NotificationSettings extends ConsumerStatefulWidget {
  const NotificationSettings({super.key});

  @override
  ConsumerState<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends ConsumerState<NotificationSettings> {
  NotificationType get _selectedType => PrefData.notificationType;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification type selections
        ...NotificationType.values.map((type) => SelectionOption<NotificationType>(
          value: type,
          groupValue: _selectedType,
          label: type.label,
          icon: type.icon,
          onChanged: (value) {
            prefs.setString('notification_type', value.name);
            setState(() {});
          },
          fullWidth: true,
        ).withPadding(bottom: 8)),
        const SizedBox(height: 8),
        MyButton(text: "Close", onPressed: context.pop),
      ],
    );
  }
}