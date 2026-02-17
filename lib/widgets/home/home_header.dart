import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/streaks.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/providers/preferences.dart';
import 'package:muslimdigest/variables/user.dart';
import '../components/icon_button.dart';

const TAB_HEIGHT = AppThemes.buttonHeight;
const TAB_RADIUS = 20.0;

/// Header widget for the home page containing hamburger menu and topic tabs
class HomeHeader extends ConsumerWidget {
  final Function(String?) onTopicChanged;
  const HomeHeader({
    super.key,
    required this.onTopicChanged,
  });

  void _onTopicChanged(String? topic) {
    if (topic == null) {
      prefs.remove('topic');
    } else {
      prefs.setString('topic', topic);
    }
    onTopicChanged(topic);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final topics = ref.watch(preferencesProvider)?.topics ?? [];
    final streaks = ref.watch(streaksProvider);

    return Container(
      height: TAB_HEIGHT,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(right: 0),
      child: Row(
        children: [
          // Hamburger menu button
          MyIconButton(
            icon: CupertinoIcons.line_horizontal_3_decrease,
            tooltip: "Settings",
            onPressed: () => context.push('/settings'),
            backgroundColor: h.currentTheme.colorScheme.surfaceContainerHighest,
            size: TAB_HEIGHT,
            radius: TAB_RADIUS,
          ),
          
          // Topic tabs
          ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 8, right: 16),
            children: <Widget>[
              if (streaks != null) 
                // Container(
                //   height: TAB_HEIGHT,
                //   decoration: BoxDecoration(
                //     color: Colors.orange[100],
                //     borderRadius: BorderRadius.circular(TAB_RADIUS),
                //   ),
                //   child: Text(
                //     '🔥 ${streaks!.currentStreak}',
                //     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                //   ),
                // ),
              _TopicTab(
                title: '${streaks.currentStreak}',
                icon: CupertinoIcons.flame_fill,
                isSelected: false,
                onTap: () {
                  // TODO: show reading streak bottom sheet
                },
              ),
              _TopicTab(
                title: 'My Digest',
                icon: CupertinoIcons.antenna_radiowaves_left_right,
                isSelected: PrefData.currentTopic == null,
                onTap: () => _onTopicChanged(null),
              ),
              ...List.generate(
                topics.length,
                (index) => _TopicTab(
                  title: topics[index],
                  isSelected: topics[index] == PrefData.currentTopic,
                  onTap: () => _onTopicChanged(topics[index]),
                ),
              ),
              // Add topic menu button
              MyIconButton(
                icon: CupertinoIcons.add,
                iconSize: 16,
                tooltip: "Add topic",
                onPressed: () => context.push('/settings'),
                backgroundColor: h.currentTheme.colorScheme.surfaceContainerHighest,
                size: TAB_HEIGHT,
                radius: TAB_RADIUS,
              ),
            ].addItemInBetween(SizedBox(width: 8,)),
          ).expand(),
        ],
      ),
    );
  }
}

/// Individual topic tab widget
class _TopicTab extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicTab({
    required this.title,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    // final tabColor = isSelected ? AppColors.primary : Colors.grey[100];
    // final textColor = isSelected ? Colors.white : Colors.black87;
    final tabColor = isSelected ? AppColors.primary : h.currentTheme.colorScheme.surfaceContainerHighest;
    final textColor = isSelected ? Colors.white : Colors.black87;
    return Material(
      color: tabColor,
      borderRadius: BorderRadius.circular(TAB_RADIUS),
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          height: TAB_HEIGHT,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              if (icon != null) Icon(icon, color: textColor, size: 16,),
              Text(
                title.toCapitalized(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ].addItemInBetween(SizedBox(width: 8,)),
          ),
        ),
      ),
    );
  }
}
