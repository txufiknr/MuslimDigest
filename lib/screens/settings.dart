import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode = defaultTheme == Brightness.dark.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentLight,
              AppColors.primary,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SettingsHeader(),
                const SizedBox(height: 32),
                
                // Personal Settings Section
                SettingsSection(
                  title: 'Personal Settings',
                  child: PersonalSettingsSection(),
                ),
                const SizedBox(height: 24),
                
                // App Settings Section
                SettingsSection(
                  title: 'App Settings',
                  child: AppSettingsSection(
                    darkMode: _darkMode,
                    onDarkModeChanged: (value) {
                      setState(() {
                        _darkMode = value;
                      });
                      // TODO: Implement theme switching
                    },
                    onResetData: _showResetDataDialog,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Donate Button
                SettingsDonateButton(),
                const SizedBox(height: 32),
                
                // Footer
                SettingsFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResetDataDialog();
      },
    );
  }
}

// Modular Stateless Widgets

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$GREETINGS, $firstName',
          style: h.currentTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'May the blessings of Allah fill your day with peace, happiness, and success.',
          style: h.currentTextTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  
  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            title,
            style: h.currentTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class PersonalSettingsSection extends StatelessWidget {
  const PersonalSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.bookmark,
            title: 'Saved Feeds',
            onTap: () {
              // TODO: Navigate to saved feeds
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: Icons.favorite,
            title: 'Liked Feeds',
            onTap: () {
              // TODO: Navigate to liked feeds
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: Icons.tune,
            title: 'Personalize Your Feed',
            onTap: () {
              // TODO: Navigate to feed personalization
            },
          ),
        ],
      ),
    );
  }
}

class AppSettingsSection extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onResetData;
  
  const AppSettingsSection({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onResetData,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: darkMode,
              onChanged: onDarkModeChanged,
            ),
          ),
          SettingsDivider(),
          SettingsTile(
            icon: Icons.feedback,
            title: 'Feedback',
            onTap: () {
              // TODO: Navigate to feedback
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: Icons.refresh,
            title: 'Reset Data',
            onTap: onResetData,
          ),
        ],
      ),
    );
  }
}

class SettingsContainer extends StatelessWidget {
  final Widget child;
  
  const SettingsContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
      ),
      title: Text(
        title,
        style: h.currentTextTheme.bodyLarge?.copyWith(
          color: Colors.white,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: Colors.white.withValues(alpha: 0.7),
      ),
      onTap: onTap,
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class SettingsDonateButton extends StatelessWidget {
  const SettingsDonateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return MyButton(
      text: 'Donate',
      onPressed: () {
        // TODO: Navigate to donate page
      },
      brightness: Brightness.dark,
      icon: const Icon(Icons.volunteer_activism),
      variant: MyButtonVariant.success,
    );
  }
}

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Column(
      children: [
        TextButton(
          onPressed: () {
            // TODO: Navigate to contact us
          },
          child: Text(
            'Contact Us',
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigate to privacy policy
          },
          child: Text(
            'Privacy Policy',
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$APP_NAME $appVersion',
          style: h.currentTextTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class ResetDataDialog extends StatelessWidget {
  const ResetDataDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return AlertDialog(
      title: Text(
        'Reset Data',
        style: h.currentTextTheme.titleLarge,
      ),
      content: Text(
        'Are you sure you want to reset all data? This action cannot be undone.',
        style: h.currentTextTheme.bodyMedium,
      ),
      actions: [
        MyButton(
          text: 'Cancel',
          onPressed: () {
            Navigator.of(context).pop();
          },
          outlined: true,
        ),
        MyButton(
          text: 'Reset',
          onPressed: () {
            // TODO: Implement data reset
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Data reset successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          variant: MyButtonVariant.error,
        ),
      ],
    );
  }
}
