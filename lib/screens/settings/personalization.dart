import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/setting_section.dart';
import 'package:muslimdigest/widgets/components/topic_chip_selector.dart';
import 'package:muslimdigest/widgets/components/topics_view.dart';
import 'package:muslimdigest/widgets/onboarding/topic_chip.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:go_router/go_router.dart';

class PersonalizationPage extends ConsumerStatefulWidget {
  const PersonalizationPage({super.key});

  @override
  ConsumerState<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends ConsumerState<PersonalizationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // String get _firstName => ref.read(userProvider).firstName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: h.currentTheme.scaffoldBackgroundColor,
      appBar: MyAppBar(
        title: 'Personalization',
        bottom: TabBar(
          controller: _tabController,
          dividerColor: h.currentTheme.colorScheme.outline,
          labelStyle: h.currentTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Interests'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInterestsTab(h),
          _buildSettingsTab(h, settings),
        ],
      ),
    );
  }

  Widget _buildInterestsTab(MyHelper h) {
    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppThemes.contentPadding),
          child: TopicsViewWithStatus(
            topicBuilder: (topic) => _buildTopicChip(h, topic, ref),
            centerContent: false,
            emptyStateMessage: 'Select topics you prefer or want to avoid',
            titleStyle: h.currentTextTheme.titleSmall,
            statusStyle: h.currentTextTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicChip(MyHelper h, String topic, WidgetRef ref) {
    return TopicChipSelector(
      topic: topic,
      colors: TopicChipColors.fromTheme(context),
    );
  }

  Widget _buildSettingsTab(MyHelper h, UserSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppThemes.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Text Size Setting
          SettingSection(
            title: 'Text Size',
            description: 'Adjust the text size for better readability',
            children: [
              TextSizeSelector(
                currentSize: settings.textSize,
                onChanged: (value) => ref.read(settingsProvider.notifier).updateTextSize(value),
              ),
              const SizedBox(height: 8),
              TextSizeDisplay(size: settings.textSize),
            ],
          ),
           
          // Swipe Direction Setting
          SettingSection(
            title: 'Swipe Direction',
            description: 'Choose the direction to swipe for next content',
            children: [
              SwipeDirectionSelector(
                currentDirection: settings.swipeDirection,
                onChanged: (value) => ref.read(settingsProvider.notifier).updateSwipeDirection(value),
              ),
            ],
          ),
          
          // Hidden Content Management Section
          SettingSection(
            title: 'Hidden Content',
            description: 'Manage your avoided sources and hidden feed items',
            children: [
              _HiddenContentButton(
                h,
                icon: CupertinoIcons.eye_slash,
                title: 'Avoided Sources',
                count: _avoidedSourcesCount,
                onTap: () => context.push('/hidden_content?tab=0'),
              ),
              _HiddenContentButton(
                h,
                icon: CupertinoIcons.hand_thumbsdown,
                title: 'Hidden Feeds',
                count: _hiddenFeedsCount,
                onTap: () => context.push('/hidden_content?tab=1'),
              ),
            ],
          ),
        ].addItemInBetween(MyDivider().withPaddingVertical(AppThemes.contentPadding)),
      ),
    );
  }

  /// Get the count of avoided sources from user preferences
  int get _avoidedSourcesCount => ref.watch(preferencesProvider).avoidedSources.length;

  /// Get the count of hidden feeds from all feed providers
  int get _hiddenFeedsCount => ref.watch(feedNotInterestedProvider).total;

  /// Build a hidden content management button with count
  Widget _HiddenContentButton(MyHelper h, {
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: h.currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: h.currentTheme.colorScheme.outline,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: h.currentTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count items',
                      style: h.currentTheme.textTheme.bodySmall?.copyWith(
                        color: h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ).expand(),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
