import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed/feed_trending.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/contents.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/format.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart' show FeedType;
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/card.dart';
import '../components/icon_button.dart';

const TAB_HEIGHT = AppThemes.buttonHeight;
const TAB_RADIUS = 20.0;

final topicKeysProvider = Provider<List<GlobalKey>>((ref) {
  final topics = ref.watch(preferencesProvider).topics;
  return List.generate(topics.length, (_) => GlobalKey());
});

/// Header widget for the home page containing hamburger menu and topic tabs
class HomeHeader extends ConsumerStatefulWidget {
  final VoidCallback onSeeTrending;
  final VoidCallback onSeeHome;
  const HomeHeader({
    super.key,
    required this.onSeeTrending,
    required this.onSeeHome,
  });

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  final ScrollController _scrollController = ScrollController();

  Set<String> get _topics => ref.watch(preferencesProvider).topics;
  UserStreaks get _streaks => ref.watch(streaksProvider);
  String? get _currentTopic => ref.watch(topicProvider);
  List<GlobalKey> get _topicKeys => ref.watch(topicKeysProvider);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onTopicChanged(WidgetRef ref, String? topic) async {
    await ref.read(topicProvider.notifier).setValue(topic);
    
    // Auto-scroll to selected tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTab(topic);
    });
  }

  void _scrollToSelectedTab(String? topic) {
    const duration = Duration(milliseconds: 300);
    // 1. Scroll to the most left for home feed tab
    if (topic == null) {
      _scrollController.animateTo(0, duration: duration, curve: Curves.ease);
      return;
    }

    // 2. Scroll to currect active topic tab (centered)
    final topics = ref.read(preferencesProvider).topics.toList();
    final topicIndex = topics.indexOf(topic);
    if (topicIndex != -1 && 
        topicIndex < _topicKeys.length && 
        _topicKeys[topicIndex].currentContext != null) {
      Scrollable.ensureVisible(
        _topicKeys[topicIndex].currentContext!,
        duration: duration,
        alignment: 0.5, // Center the item
      );
    }
  }

  Future<void> _showStreaks() async {
    final h = MyHelper(context);

    // States
    final r = ref.read(appRepositoryProvider);
    final shouldShowDigest = r.shouldShowDigest;
    final firstName = ref.read(userProvider).firstName;
    final readCount = ref.read(readCountProvider);
    final streaks = ref.read(streaksProvider);

    // Conditions
    final currentStreak = streaks.currentStreak;
    final readTarget = ref.read(feedProvider).items?.length ?? DAILY_READ_TARGET;
    final isStreakToday = isToday(streaks.lastReadAt);
    final isStreakAlive = currentStreak > 0;

    // Messages
    final streakMessage = isStreakAlive ? "You’ve been learning for ${formatNumber(currentStreak)} days in a row 🌱" : "Let’s start a fresh reading rhythm 🌱";
    final streakHint = isStreakToday
        ? "Come back tomorrow for another streak."
        : shouldShowDigest
          ? "Read ${readTarget - readCount} more for next streak!"
          : currentStreak > 0
            ? "Keep up your daily reading habit"
            : "Nurture your daily knowledge habit";

    await showBottomModalSheetContent(context, title: "Reading Streak", widgets: [
      Text("$GREETINGS, $firstName. $streakMessage", style: h.currentTextTheme.bodyMedium,),
      StreaksCard().withPaddingVertical(16),
      Text(streakHint, textAlign: TextAlign.center, style: h.currentTextTheme.bodyMedium?.copyWith(fontSize: 15, fontStyle: FontStyle.italic),).center(),
      SizedBox(height: 16,),
      MyButton(text: "Keep reading", icon: Icon(CupertinoIcons.book), onPressed: context.pop),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for feed type changes and trigger tabs scroll
    ref.listen<FeedType>(feedTypeProvider, (previous, next) {
      if (!mounted || previous == next) return;
      if (next.isHomeFeed && ref.read(topicProvider) == null) {
        // Auto scroll to zero horizontal position
        _scrollToSelectedTab(null);
      }
    });
    
    // Listen for topic changes and trigger load feed with debounce
    ref.listen<String?>(topicProvider, (previous, next) {
      if (!mounted || previous == next || next != null) return;
      final currentFeedType = ref.read(feedTypeProvider);
      if (currentFeedType.isHomeFeed) {
        // Auto scroll to zero horizontal position
        _scrollToSelectedTab(null);
      }
    });

    final h = MyHelper(context);
    final homeFeedType = ref.read(appRepositoryProvider).homeFeedType;
    final feedType = ref.watch(feedTypeProvider);
    final trendingCount = ref.watch(feedTrendingProvider).total;
    final isTrending = feedType == FeedType.trending;

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
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 8, right: 16),
            children: <Widget>[
              // Reading streak count
              if (_streaks.currentStreak > 0)
              _TopicTab(
                title: formatNumber(_streaks.currentStreak),
                icon: CupertinoIcons.book,
                isSelected: false,
                tabColor: AppColors.success,
                textColor: Colors.white,
                onTap: _showStreaks,
              ),

              // Home feed
              _TopicTab(
                title: homeFeedType.label,
                icon: homeFeedType.icon,
                isSelected: feedType == homeFeedType && _currentTopic == null,
                onTap: widget.onSeeHome,
              ),

              // Trending feed
              if (trendingCount > 0)
              _TopicTab(
                title: FeedType.trending.label,
                icon: FeedType.trending.icon,
                isSelected: isTrending,
                onTap: widget.onSeeTrending,
              ),

              // Topic feeds
              ...List.generate(
                _topics.length,
                (index) {
                  final topicsList = _topics.toList();
                  return _TopicTab(
                    key: _topicKeys[index],
                    title: topicsList[index],
                    isSelected: topicsList[index] == _currentTopic,
                    onTap: () => _onTopicChanged(ref, topicsList[index]),
                  );
                },
              ),

              // Add topic button
              MyIconButton(
                icon: CupertinoIcons.add,
                iconSize: 16,
                tooltip: "Add topic",
                onPressed: () => context.push('/personalization'),
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
  final Color? tabColor;
  final Color? textColor;

  const _TopicTab({
    super.key,
    required this.title,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.tabColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final backgroundColor = tabColor ?? (isSelected ? AppColors.primary : h.currentTheme.colorScheme.surfaceContainerHighest);
    final foregroundColor = textColor ?? (isSelected ? Colors.white : h.currentTheme.colorScheme.onSurface);
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(TAB_RADIUS),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          height: TAB_HEIGHT,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              if (icon != null) Icon(icon, color: foregroundColor, size: 16,),
              Text(
                getTopicLabel(title),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
