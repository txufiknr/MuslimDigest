import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/user.dart';
import '../components/my_icon_button.dart';

const TAB_HEIGHT = AppThemes.buttonHeight;
const TAB_RADIUS = 20.0;

/// Header widget for the home page containing hamburger menu and topic tabs
class HomeHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final topics = preferences?.topics ?? [];

    return Container(
      height: TAB_HEIGHT,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(right: 0),
      child: Row(
        children: [
          // Hamburger menu button
          MyIconButton(
            icon: CupertinoIcons.bars,
            // iconSize: 16,
            tooltip: "Settings",
            onPressed: () => context.push('/settings'),
            backgroundColor: Colors.grey[100],
            size: TAB_HEIGHT,
            radius: TAB_RADIUS,
          ),
          
          // Topic tabs
          ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 8, right: 16),
            children: <Widget>[
              if (streaks != null) 
                Container(
                  height: TAB_HEIGHT,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(TAB_RADIUS),
                  ),
                  child: Text(
                    '🔥 ${streaks!.currentStreak}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              _TopicTab(
                title: 'My Digest',
                isSelected: currentTopic == null,
                onTap: () => _onTopicChanged(null),
              ),
              ...List.generate(
                topics.length,
                (index) => _TopicTab(
                  title: topics[index],
                  isSelected: topics[index] == currentTopic,
                  onTap: () => _onTopicChanged(topics[index]),
                ),
              ),
              // Add topic menu button
              MyIconButton(
                icon: CupertinoIcons.add,
                iconSize: 16,
                tooltip: "Add topic",
                onPressed: () => context.push('/settings'),
                backgroundColor: Colors.grey[100],
                size: TAB_HEIGHT,
                radius: TAB_RADIUS,
              ),
              // TODO: add "+ Add topic" as the last button (go to "/settings")
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
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: TAB_HEIGHT,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(TAB_RADIUS),
        ),
        child: Text(
          title.toCapitalized(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
