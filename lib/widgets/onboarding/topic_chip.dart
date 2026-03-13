import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/contents.dart';
import 'package:muslimdigest/utils/helpers.dart';

enum TopicState { neutral, preferred, avoided }

/// Color configuration for TopicChip states
class TopicChipColors {
  final Color preferredText;
  final Color preferredBackground;
  final Color avoidedText;
  final Color avoidedBackground;
  final Color neutralText;
  final Color neutralBackground;
  final Color avoidedBorder;
  final Color neutralBorder;

  const TopicChipColors({
    this.preferredText = AppColors.accent,
    this.preferredBackground = Colors.white,
    this.avoidedText = Colors.white,
    this.avoidedBackground = AppColors.error,
    this.neutralText = Colors.white,
    this.neutralBackground = AppColors.accentLight,
    this.avoidedBorder = AppColors.error,
    this.neutralBorder = Colors.white,
  });

  /// Create theme-aware colors for light mode
  factory TopicChipColors.light() {
    final colorScheme = AppThemes.lightColorScheme;
    return TopicChipColors(
      preferredText: Colors.white,
      preferredBackground: colorScheme.primary,
      avoidedText: Colors.white,
      avoidedBackground: colorScheme.error,
      neutralText: colorScheme.primary,
      neutralBackground: Colors.white,
      avoidedBorder: colorScheme.error,
      neutralBorder: colorScheme.primary,
    );
  }

  /// Create theme-aware colors for dark mode
  factory TopicChipColors.dark() {
    final colorScheme = AppThemes.darkColorScheme;
    return TopicChipColors(
      preferredText: colorScheme.primary,
      preferredBackground: Colors.white,
      avoidedText: Colors.white,
      avoidedBackground: colorScheme.error,
      neutralText: Colors.white,
      neutralBackground: colorScheme.surface,
      avoidedBorder: colorScheme.error,
      neutralBorder: Colors.white,
    );
  }

  /// Create theme-aware colors based on current theme
  factory TopicChipColors.fromTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? TopicChipColors.dark() : TopicChipColors.light();
  }

  /// Get text color for given state
  Color getTextColor(TopicState state) {
    switch (state) {
      case TopicState.preferred:
        return preferredText;
      case TopicState.avoided:
        return avoidedText;
      case TopicState.neutral:
        return neutralText;
    }
  }

  /// Get background color for given state
  Color getBackgroundColor(TopicState state) {
    switch (state) {
      case TopicState.preferred:
        return preferredBackground;
      case TopicState.avoided:
        return avoidedBackground;
      case TopicState.neutral:
        return neutralBackground;
    }
  }

  /// Get border color for given state
  Color getBorderColor(TopicState state) {
    switch (state) {
      case TopicState.preferred:
      case TopicState.neutral:
        return neutralBorder;
      case TopicState.avoided:
        return avoidedBorder;
    }
  }
}

/// Individual topic chip widget for onboarding interests selection
class TopicChip extends StatelessWidget {
  final String topic;
  final TopicState state;
  final ValueChanged<TopicState> onStateChanged;
  final TopicChipColors colors;

  const TopicChip({
    super.key,
    required this.topic,
    required this.state,
    required this.onStateChanged,
    this.colors = const TopicChipColors(),
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    final isSelected = state != TopicState.neutral;
    
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: EdgeInsets.zero,
      label: Text(
        getTopicLabel(topic),
        style: h.currentTextTheme.bodyMedium?.copyWith(
          color: colors.getTextColor(state),
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
      backgroundColor: colors.getBackgroundColor(state),
      selectedColor: colors.getBackgroundColor(state),
      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      showCheckmark: false,
      side: BorderSide(
        color: colors.getBorderColor(state).withValues(alpha: 0.5),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
