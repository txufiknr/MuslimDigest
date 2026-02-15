import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'topic_chip.dart';

/// Interests selection step widget for onboarding
class OnboardingInterestsStep extends StatefulWidget {
  final List<String> availableTopics;

  const OnboardingInterestsStep({
    super.key,
    required this.availableTopics,
  });

  @override
  State<OnboardingInterestsStep> createState() => _OnboardingInterestsStepState();
}

class _OnboardingInterestsStepState extends State<OnboardingInterestsStep> {
  List<String> get _selectedTopics => preferredTopics;

  /// Build individual topic chip
  Widget _buildTopicChip(MyHelper h, String topic, bool isSelected) {
    return TopicChip(
      topic: topic,
      isSelected: isSelected,
      onSelected: (selected) async {
        final newSelectedTopics = List<String>.from(_selectedTopics);
        if (selected) {
          newSelectedTopics.add(topic);
        } else {
          newSelectedTopics.remove(topic);
        }
        await setUserPreferences(preferences?.copyWith(topics: newSelectedTopics));
        setState(() {});
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
        
        if (widget.availableTopics.isEmpty) MyLoader(color: Colors.white).center()
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: widget.availableTopics.map((topic) {
              final isSelected = _selectedTopics.contains(topic);
              return _buildTopicChip(h, topic, isSelected);
            }).toList(),
          ).withPaddingHorizontal(16),
      ],
    );
  }
}
