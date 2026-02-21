import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/onboarding/topic_chip.dart';

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
    final appRepository = ref.read(appRepositoryProvider);
    final preferredTopics = appRepository.preferredTopics;
    final avoidedTopics = appRepository.avoidedTopics;
    
    TopicState state;
    if (preferredTopics.contains(topic)) {
      state = TopicState.preferred;
    } else if (avoidedTopics.contains(topic)) {
      state = TopicState.avoided;
    } else {
      state = TopicState.neutral;
    }
    
    return TopicChip(
      topic: topic,
      state: state,
      onStateChanged: (newState) async {
        final preferences = ref.read(preferencesProvider);
        final newPreferredTopics = List<String>.from(preferences.topics);
        final newAvoidedTopics = List<String>.from(preferences.avoidedTopics);
        
        // Remove topic from both lists first
        newPreferredTopics.remove(topic);
        newAvoidedTopics.remove(topic);
        
        // Add to appropriate list based on new state
        switch (newState) {
          case TopicState.preferred:
            newPreferredTopics.add(topic);
            break;
          case TopicState.avoided:
            newAvoidedTopics.add(topic);
            break;
          case TopicState.neutral:
            // Already removed, nothing to add
            break;
        }
        
        await ref.read(preferencesProvider.notifier).setValue(
          preferences.copyWith(
            topics: newPreferredTopics,
            avoidedTopics: newAvoidedTopics,
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(MyHelper h, UserSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppThemes.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Preferences',
            style: h.currentTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Text Size Setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text Size',
                    style: h.currentTextTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Adjust the text size for better readability',
                    style: h.currentTextTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      IconButton(
                        onPressed: settings.textSize > 12 
                            ? () => ref.read(settingsProvider.notifier).updateTextSize(settings.textSize - 2)
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      
                      Expanded(
                        child: Slider(
                          value: settings.textSize.toDouble(),
                          min: 12,
                          max: 24,
                          divisions: 6,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateTextSize(value.round());
                          },
                        ),
                      ),
                      
                      IconButton(
                        onPressed: settings.textSize < 24 
                            ? () => ref.read(settingsProvider.notifier).updateTextSize(settings.textSize + 2)
                            : null,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${settings.textSize}px',
                        style: h.currentTextTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Swipe Direction Setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swipe Direction',
                    style: h.currentTextTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Choose the direction to swipe for next content',
                    style: h.currentTextTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(settingsProvider.notifier).updateSwipeDirection('left'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: settings.swipeDirection == 'left' 
                                  ? AppColors.primary 
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: settings.swipeDirection == 'left' 
                                      ? Colors.white 
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Left',
                                  style: h.currentTextTheme.bodyMedium?.copyWith(
                                    color: settings.swipeDirection == 'left' 
                                        ? Colors.white 
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(settingsProvider.notifier).updateSwipeDirection('right'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: settings.swipeDirection == 'right' 
                                  ? AppColors.primary 
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Right',
                                  style: h.currentTextTheme.bodyMedium?.copyWith(
                                    color: settings.swipeDirection == 'right' 
                                        ? Colors.white 
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: settings.swipeDirection == 'right' 
                                      ? Colors.white 
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preview Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: h.currentTextTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'This is how your text will appear with the selected size. Swipe ${settings.swipeDirection} to navigate through content.',
                      style: h.currentTextTheme.bodyMedium?.copyWith(
                        fontSize: settings.textSize.toDouble(),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
