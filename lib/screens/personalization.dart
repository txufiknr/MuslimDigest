import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/components/setting_section.dart';
import 'package:muslimdigest/widgets/components/topic_chip_selector.dart';
import 'package:muslimdigest/utils/helpers.dart';

class PersonalizationPage extends ConsumerStatefulWidget {
  const PersonalizationPage({super.key});

  @override
  ConsumerState<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends ConsumerState<PersonalizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Personalization',
          style: h.currentTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: h.currentTextTheme.titleSmall,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        final availableTopics = ref.watch(topicsProvider).availableTopics;
        final appRepository = ref.watch(appRepositoryProvider);
        final preferredTopics = appRepository.preferredTopics;
        final avoidedTopics = appRepository.avoidedTopics;

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
              
              if (availableTopics.isEmpty) 
                MyLoader(color: AppColors.primary).center()
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
    return TopicChipSelector(topic: topic);
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
            title: 'Preview',
            children: [
              PreviewSection(
                text: 'This is how your text will appear with the selected size. Swipe ${settings.swipeDirection} to navigate through content.',
                fontSize: settings.textSize.toDouble(),
              ),
            ],
          ),
        ].addItemInBetween(MyDivider().withPaddingVertical(16)),
      ),
    );
  }
}
