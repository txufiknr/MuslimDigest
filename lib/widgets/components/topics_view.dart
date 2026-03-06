import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/button.dart';

/// A reusable widget for displaying topics with loading state and reload functionality
class TopicsView extends ConsumerWidget {
  final Brightness? brightness;
  final Widget Function(String topic) topicBuilder;
  final bool centerContent;
  final VoidCallback? onReload;
  final double chipGap;

  const TopicsView({
    super.key,
    this.brightness,
    required this.topicBuilder,
    this.centerContent = false,
    this.onReload,
    this.chipGap = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TopicsState(availableTopics: availableTopics, isLoading: isLoading) = ref.watch(topicsProvider);

    if (availableTopics.isEmpty) {
      final currentBrightness = brightness ?? Theme.of(context).brightness;
      final content = Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyLoader(color: currentBrightness == Brightness.light ? AppColors.primary : Colors.white),
            if (!isLoading) ...[
              const SizedBox(height: 16),
              MyButton(
                text: "Reload topics", 
                outlined: true, 
                brightness: currentBrightness,
                icon: Icon(CupertinoIcons.arrow_clockwise), 
                onPressed: onReload ?? () {
                  ref.read(topicsProvider.notifier).load();
                },
              ),
            ],
          ],
        ),
      );

      return centerContent ? content.center() : content;
    }

    final topicsWidget = Wrap(
      spacing: chipGap,
      runSpacing: chipGap,
      alignment: centerContent ? WrapAlignment.center : WrapAlignment.start,
      children: availableTopics.map(topicBuilder).toList(),
    );

    return centerContent ? topicsWidget.center() : topicsWidget;
  }
}

/// A convenience widget that includes the topics status text
class TopicsViewWithStatus extends ConsumerWidget {
  final Brightness? brightness;
  final Widget Function(String topic) topicBuilder;
  final bool centerContent;
  final VoidCallback? onReload;
  final String? title;
  final String? emptyStateMessage;
  final TextStyle? titleStyle;
  final TextStyle? statusStyle;
  final double chipGap;

  const TopicsViewWithStatus({
    super.key,
    this.brightness,
    required this.topicBuilder,
    this.centerContent = false,
    this.onReload,
    this.title,
    this.emptyStateMessage,
    this.titleStyle,
    this.statusStyle,
    this.chipGap = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserPreferences(topics: preferredTopics, avoidedTopics: avoidedTopics) = ref.watch(preferencesProvider);

    return Column(
      crossAxisAlignment: centerContent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title ?? 'What interests you?',
          style: titleStyle,
          textAlign: centerContent ? TextAlign.center : TextAlign.start,
        ),
        Text(
          preferredTopics.isEmpty && avoidedTopics.isEmpty 
              ? (emptyStateMessage ?? 'Select all that apply')
              : '${preferredTopics.length} preferred${avoidedTopics.isNotEmpty ? ' - ${avoidedTopics.length} avoided' : ''}',
          style: statusStyle,
          textAlign: centerContent ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        TopicsView(
          brightness: brightness,
          topicBuilder: topicBuilder,
          centerContent: centerContent,
          onReload: onReload,
          chipGap: chipGap,
        ),
      ].addItemInBetween(SizedBox(height: 8,)),
    );
  }
}
