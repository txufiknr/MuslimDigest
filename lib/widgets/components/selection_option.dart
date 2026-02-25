import 'package:flutter/cupertino.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

class SelectionOption<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<T> onChanged;
  final bool fullWidth;

  const SelectionOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.fullWidth = false,
  });

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.textSecondaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppThemes.iconLargeSize,
            color: isSelected ? AppColors.accent : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: h.currentTextTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.accent : AppColors.textPrimaryLight,
            ),
          ).expand(),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: AppThemes.iconMediumSize,
              color: AppColors.accent,
            ),
        ],
      ),
    ).onTap(() => onChanged(value));
  }
}
