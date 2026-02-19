import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/mock/users.dart';
import 'package:muslimdigest/providers/preferences.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'topic_chip.dart';

/// Interests selection step widget for onboarding
class OnboardingInterestsStep extends ConsumerWidget {

  const OnboardingInterestsStep({super.key});

  /// Build individual topic chip with 3-step tap functionality
  /// 1st tap: select (prefer topic)
  /// 2nd tap: select (avoid topic)
  /// 3rd tap: select (reset/neutral)
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
        final preferences = ref.read(preferencesProvider) ?? newPreferences;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final availableTopics = ref.watch(topicsProvider).availableTopics;
    final appRepository = ref.watch(appRepositoryProvider);
    final preferredTopics = appRepository.preferredTopics;
    final avoidedTopics = appRepository.avoidedTopics;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'What interests you?',
          style: h.currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          preferredTopics.isEmpty && avoidedTopics.isEmpty 
              ? 'Select all that apply' 
              : '${preferredTopics.length} preferred${avoidedTopics.isNotEmpty ? ' - ${avoidedTopics.length} avoided' : ''}',
          style: MyHelper(context).currentTextTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        if (availableTopics.isEmpty) MyLoader(color: Colors.white).center()
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: availableTopics.map((topic) {
              return _buildTopicChip(h, topic, ref);
            }).toList(),
          ).withPaddingHorizontal(16),
      ],
    );
  }
}
