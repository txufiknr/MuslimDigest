import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

enum TopicState { neutral, preferred, avoided }

/// Individual topic chip widget for onboarding interests selection
class TopicChip extends StatelessWidget {
  final String topic;
  final TopicState state;
  final ValueChanged<TopicState> onStateChanged;

  const TopicChip({
    super.key,
    required this.topic,
    required this.state,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    final isSelected = state != TopicState.neutral;
    final Color textColor;
    final Color backgroundColor;
    
    switch (state) {
      case TopicState.preferred:
        textColor = AppColors.accent;
        backgroundColor = Colors.white;
        break;
      case TopicState.avoided:
        textColor = Colors.white;
        backgroundColor = AppColors.error;
        break;
      case TopicState.neutral:
        textColor = Colors.white;
        backgroundColor = AppColors.accentLight.withValues(alpha: 0.9);
        break;
    }
    
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(
        topic.toCapitalized(),
        style: h.currentTextTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        TopicState newState;
        switch (state) {
          case TopicState.neutral:
            newState = TopicState.preferred;
            break;
          case TopicState.preferred:
            newState = TopicState.avoided;
            break;
          case TopicState.avoided:
            newState = TopicState.neutral;
            break;
        }
        onStateChanged(newState);
      },
      backgroundColor: backgroundColor,
      selectedColor: backgroundColor,

      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      showCheckmark: false,

      side: BorderSide(
        color: state == TopicState.avoided 
            ? AppColors.error.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
