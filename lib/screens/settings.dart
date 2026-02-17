import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/logo.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';
import 'package:muslimdigest/widgets/components/switch.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

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
          child: Column(
            children: [
              Row(
                children: [
                  Logo(size: 40,),
                  Spacer(),
                  MyIconButton(icon: CupertinoIcons.chevron_left_2, iconColor: Colors.white, onPressed: context.pop),
                ],
              ).withPadding(horizontal: 16, bottom: 8),
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                      darkMode: h.isDarkTheme,
                      onDarkModeChanged: (value) {
                        h.nextTheme();
                        // setState(() {});
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
              ).expand(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDataDialog() async {
    final resetData = await showBottomModalConfirm(
      context,
      title: 'Reset Data',
      message: 'Are you sure you want to reset all data?',
      footer: 'This action cannot be undone.',
      confirmButtonText: 'Yes, reset',
      confirmButtonVariant: MyButtonVariant.error,
      confirmButtonIcon: Icon(CupertinoIcons.arrow_clockwise),
      cancelButtonText: 'No, keep them',
    ) ?? false;
    
    if (resetData && mounted) {
      // TODO: reset data
      showSnackBar(context, 'Data reset successfully');
    }
  }
}

class SettingsHeader extends ConsumerWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final r = ref.read(appRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$GREETINGS, ${r.firstName}',
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
            icon: CupertinoIcons.bookmark_fill,
            title: 'Saved Feeds',
            onTap: () {
              // TODO: Navigate to saved feeds
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: CupertinoIcons.heart_fill,
            title: 'Liked Feeds',
            onTap: () {
              // TODO: Navigate to liked feeds
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: CupertinoIcons.square_grid_2x2_fill,
            title: 'Personalize Your Feed',
            onTap: () {
              // TODO: Navigate to feed personalization
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: CupertinoIcons.person_fill,
            title: 'Edit Profile',
            onTap: () {
              context.push('/welcome');
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
            icon: CupertinoIcons.bell_fill,
            title: 'Notifications',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          SettingsDivider(),
          SettingsTile(
            icon: CupertinoIcons.moon_fill,
            title: 'Dark Mode',
            trailing: MySwitch(
              value: darkMode,
              onChanged: onDarkModeChanged,
            ),
          ),
          SettingsDivider(),
          SettingsTile(
            icon: CupertinoIcons.chat_bubble_fill,
            title: 'Feedback',
            onTap: openStoreListing,
          ),
          SettingsDivider(),
          SettingsTile(
            icon: CupertinoIcons.arrow_clockwise,
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
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      minTileHeight: AppThemes.buttonHeight,
      minLeadingWidth: 0,
      minVerticalPadding: 0,
      leading: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
      title: Text(
        title,
        style: h.currentTextTheme.bodyMedium?.copyWith(
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
      onPressed: () => openUrl(APP_URL_DONATE),
      brightness: Brightness.dark,
      icon: Icon(CupertinoIcons.gift),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => openUrl('mailto:$APP_COMPANY_EMAIL'),
              child: Text(
                'Contact Us',
                style: h.currentTextTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            TextButton(
              onPressed: () => openUrl(APP_URL_PRIVACY),
              child: Text(
                'Privacy Policy',
                style: h.currentTextTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
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
