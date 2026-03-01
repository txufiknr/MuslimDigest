import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/widgets/onboarding/topic_chip.dart';

/// Reusable widget for topic chip selection with 3-state toggle
/// Can be used in onboarding and personalization pages
class TopicChipSelector extends ConsumerWidget {
  final String topic;
  final VoidCallback? onStateChanged;
  final TopicChipColors colors;

  const TopicChipSelector({
    super.key,
    required this.topic,
    this.onStateChanged,
    this.colors = const TopicChipColors(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    final preferredTopics = preferences.topics;
    final avoidedTopics = preferences.avoidedTopics;
    
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
      colors: colors,
      onStateChanged: (newState) async {
        await _updateTopicState(ref, topic, newState);
        onStateChanged?.call();
      },
    );
  }

  /// Helper method to update topic state in preferences
  static Future<void> _updateTopicState(
    WidgetRef ref,
    String topic,
    TopicState newState,
  ) async {
    final preferences = ref.read(preferencesProvider);
    final newPreferredTopics = Set<String>.from(preferences.topics);
    final newAvoidedTopics = Set<String>.from(preferences.avoidedTopics);
    
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
  }
}
