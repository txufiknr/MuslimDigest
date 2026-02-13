import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import '../../utils/helpers.dart';

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
    return GestureDetector(
      onTap: () {
        final newSelectedTopics = List<String>.from(selectedTopics);
        if (isSelected) {
          newSelectedTopics.remove(topic);
        } else {
          newSelectedTopics.add(topic);
        }
        onTopicsChanged(newSelectedTopics);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          topic,
          style: h.currentTextTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
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
        
        if (availableTopics.isEmpty)
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ).center()
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: availableTopics.map((topic) {
              final isSelected = selectedTopics.contains(topic);
              return _buildTopicChip(h, topic, isSelected);
            }).toList(),
          ),
      ],
    );
  }
}
