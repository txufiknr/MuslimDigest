import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/variables/feed.dart';

class FeedbackForm extends StatefulWidget {
  final String feedId;
  const FeedbackForm({required this.feedId, super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _textController = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.suggestion;

  Future<void> _submit() async {
    final categoryLabel = _selectedCategory.label;
    final result = await submitFeedback(widget.feedId, _selectedCategory.name, _textController.text.trim());
    if (!mounted) return;
    if (result.successful) {
      showSnackBarSuccess(context, '$categoryLabel has been sent successfully');
      context.pop(result);
    } else {
      showSnackBarError(context, result.error ?? 'Failed to send ${categoryLabel.toLowerCase()}');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text('Message', style: h.currentTheme.textTheme.labelMedium).left(),
        const SizedBox(height: 8),
        
        // Message input
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondaryLight.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 5,
            minLines: 3,
            style: h.currentTheme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Share your thoughts, suggestions, or report issues...',
              hintStyle: h.hintStyle,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackCategory.values.map((type) {
            final isSelected = _selectedCategory == type;
            return ChoiceChip(
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: AppThemes.iconMediumSize,
                    color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: h.currentTheme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = type);
                }
              },
              backgroundColor: AppColors.backgroundLight,
              selectedColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
              ),
              side: BorderSide(color: isSelected ? AppColors.accent : h.currentTheme.colorScheme.outline)
            );
          }).toList(),
        ).fullWidth(),
    
        SizedBox(height: 32,),
        
        // Action buttons
        MyButton(
          text: "Send Feedback",
          icon: Icon(CupertinoIcons.paperplane),
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        MyButton(
          text: "Cancel",
          outlined: true,
          onPressed: context.pop,
        ),
      ],
    );
  }
}
