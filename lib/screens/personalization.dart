import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/setting_section.dart';
import 'package:muslimdigest/widgets/components/topic_chip_selector.dart';
import 'package:muslimdigest/widgets/onboarding/topic_chip.dart';
import 'package:muslimdigest/utils/helpers.dart';

class PersonalizationPage extends ConsumerStatefulWidget {
  const PersonalizationPage({super.key});

  @override
  ConsumerState<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends ConsumerState<PersonalizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _firstName => ref.read(userProvider).firstName;

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
          labelStyle: h.currentTextTheme.titleSmall,
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
        final TopicsState(availableTopics: availableTopics, isLoading: isLoading) = ref.watch(topicsProvider);
        final UserPreferences(topics: preferredTopics, avoidedTopics: avoidedTopics) = ref.watch(preferencesProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppThemes.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What interests you?',
                style: h.currentTextTheme.titleMedium,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                preferredTopics.isEmpty && avoidedTopics.isEmpty 
                    ? 'Select topics you prefer or want to avoid' 
                    : '${preferredTopics.length} preferred${avoidedTopics.isNotEmpty ? ' - ${avoidedTopics.length} avoided' : ''}',
                style: h.currentTextTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (availableTopics.isEmpty) Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyLoader(color: AppColors.primary),
                  if (!isLoading) MyButton(text: "Reload topics", outlined: true, icon: Icon(CupertinoIcons.arrow_clockwise), onPressed: () {
                    ref.read(topicsProvider.notifier).load();
                  }),
                ],
              ).center()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTopics.map((topic) {
                    return _buildTopicChip(h, topic, ref);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicChip(MyHelper h, String topic, WidgetRef ref) {
    return TopicChipSelector(
      topic: topic,
      colors: const TopicChipColors(
        neutralText: AppColors.primary,
        neutralBackground: Colors.white,
        neutralBorder: AppColors.primary,
        preferredText: Colors.white,
        preferredBackground: AppColors.primary,
        avoidedText: Colors.white,
        avoidedBackground: AppColors.error,
        avoidedBorder: AppColors.error,
      ),
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
           
          // Preview Section
          SettingSection(
            children: [
              PreviewSection(
                text: '$GREETINGS, $_firstName. Welcome to $APP_NAME - $APP_DESCRIPTION. This is how your article text will appear with the selected size. Swipe ${settings.swipeDirection.name} to navigate to the next article, and swipe to the opposite direction to undo.',
                fontSize: settings.textSize.toDouble(),
              ),
            ],
          ),
        ].addItemInBetween(MyDivider().withPaddingVertical(AppThemes.contentPadding)),
      ),
    );
  }
}
