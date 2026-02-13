import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

/// Individual topic chip widget for onboarding interests selection
class TopicChip extends StatelessWidget {
  final String topic;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const TopicChip({
    super.key,
    required this.topic,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(
        topic.toCapitalized(),
        style: h.currentTextTheme.bodyMedium?.copyWith(
          color: isSelected ? AppColors.accent : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: AppColors.accentLight.withValues(alpha: 0.9),
      selectedColor: Colors.white,

      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      showCheckmark: false,

      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
