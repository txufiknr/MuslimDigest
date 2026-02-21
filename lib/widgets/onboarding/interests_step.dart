import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/components/topic_chip_selector.dart';
import '../../utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';

/// Interests selection step widget for onboarding
class OnboardingInterestsStep extends ConsumerWidget {

  const OnboardingInterestsStep({super.key});

  /// Build individual topic chip using reusable TopicChipSelector
  Widget _buildTopicChip(MyHelper h, String topic, WidgetRef ref) {
    return TopicChipSelector(topic: topic);
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
