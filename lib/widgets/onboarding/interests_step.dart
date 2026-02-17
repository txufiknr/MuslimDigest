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

  /// Build individual topic chip
  /// TODO: tap twice to avoid topic, sequence:
  /// 1st tap: select (prefer topic)
  /// 2nd tap: select (avoid topic)
  /// 3rd tap: select (reset/neutral)
  Widget _buildTopicChip(MyHelper h, String topic, bool isSelected, WidgetRef ref) {
    return TopicChip(
      topic: topic,
      isSelected: isSelected,
      onSelected: (selected) async {
        final selectedTopics = ref.read(appRepositoryProvider).preferredTopics;
        final newSelectedTopics = List<String>.from(selectedTopics);
        if (selected) {
          newSelectedTopics.add(topic);
        } else {
          newSelectedTopics.remove(topic);
        }
        final preferences = ref.read(preferencesProvider) ?? newPreferences;
        await ref.read(preferencesProvider.notifier).setValue(preferences.copyWith(topics: newSelectedTopics));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final availableTopics = ref.watch(topicsProvider).availableTopics;

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
          'Select all that apply',
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
              final selectedTopics = ref.watch(appRepositoryProvider).preferredTopics;
              final isSelected = selectedTopics.contains(topic);
              return _buildTopicChip(h, topic, isSelected, ref);
            }).toList(),
          ).withPaddingHorizontal(16),
      ],
    );
  }
}
