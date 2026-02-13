import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'topic_chip.dart';

/// Interests selection step widget for onboarding
class OnboardingInterestsStep extends StatelessWidget {
  final List<String> availableTopics;
  final List<String> selectedTopics;
  final ValueChanged<List<String>> onTopicsChanged;

  const OnboardingInterestsStep({
    super.key,
    required this.availableTopics,
    required this.selectedTopics,
    required this.onTopicsChanged,
  });

  /// Build individual topic chip
  Widget _buildTopicChip(MyHelper h, String topic, bool isSelected) {
    return TopicChip(
      topic: topic,
      isSelected: isSelected,
      onSelected: (selected) {
        final newSelectedTopics = List<String>.from(selectedTopics);
        if (selected) {
          newSelectedTopics.add(topic);
        } else {
          newSelectedTopics.remove(topic);
        }
        onTopicsChanged(newSelectedTopics);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

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
              final isSelected = selectedTopics.contains(topic);
              return _buildTopicChip(h, topic, isSelected);
            }).toList(),
          ).withPaddingHorizontal(16),
      ],
    );
  }
}
