import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/topic_chip_selector.dart';
import '../../utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/onboarding/topic_chip.dart';

/// Interests selection step widget for onboarding
class OnboardingInterestsStep extends ConsumerWidget {

  const OnboardingInterestsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final TopicsState(availableTopics: availableTopics, isLoading: isLoading) = ref.watch(topicsProvider);
    final UserPreferences(topics: preferredTopics, avoidedTopics: avoidedTopics) = ref.watch(preferencesProvider);

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
        
        if (availableTopics.isEmpty) Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyLoader(color: Colors.white),
            if (!isLoading) MyButton(text: "Reload topics", outlined: true, icon: Icon(CupertinoIcons.arrow_clockwise), onPressed: () {
              ref.read(topicsProvider.notifier).load();
            }),
          ],
        ).center()
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: availableTopics.map((topic) {
              return TopicChipSelector(topic: topic, colors: TopicChipColors.light());
            }).toList(),
          ).withPaddingHorizontal(16),
      ],
    );
  }
}
