import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/widgets/components/topic_chip_selector.dart';
import 'package:muslimdigest/widgets/components/topics_view.dart';
import '../../utils/helpers.dart';
import 'package:muslimdigest/widgets/onboarding/topic_chip.dart';

/// Interests selection step widget for onboarding
class OnboardingInterestsStep extends ConsumerWidget {

  const OnboardingInterestsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);

    return TopicsViewWithStatus(
      brightness: Brightness.dark,
      topicBuilder: (topic) => TopicChipSelector(
        topic: topic,
        colors: TopicChipColors.light(),
        // colors: const TopicChipColors(
        //   neutralText: AppColors.primary,
        //   neutralBackground: Colors.white,
        //   neutralBorder: AppColors.primary,
        //   preferredText: Colors.white,
        //   preferredBackground: AppColors.primary,
        //   avoidedText: Colors.white,
        //   avoidedBackground: AppColors.error,
        //   avoidedBorder: AppColors.error,
        // ),
      ),
      centerContent: true,
      chipGap: 6,
      titleStyle: h.currentTextTheme.labelLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
      ),
      statusStyle: MyHelper(context).currentTextTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}
