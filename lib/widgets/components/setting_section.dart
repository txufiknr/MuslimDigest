import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/helpers.dart';

/// Reusable widget for setting sections with title, description, and content
class SettingSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const SettingSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: h.currentTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

/// Reusable widget for swipe direction selection
class SwipeDirectionSelector extends ConsumerWidget {
  final String currentDirection;
  final ValueChanged<String> onChanged;

  const SwipeDirectionSelector({
    super.key,
    required this.currentDirection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final h = MyHelper(context);
    
    return Row(
      children: [
        Expanded(
          child: _SwipeDirectionButton(
            direction: 'left',
            icon: CupertinoIcons.arrow_left,
            label: 'Left',
            isSelected: currentDirection == 'left',
            onTap: () => onChanged('left'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _SwipeDirectionButton(
            direction: 'right',
            icon: CupertinoIcons.arrow_right,
            label: 'Right',
            isSelected: currentDirection == 'right',
            onTap: () => onChanged('right'),
          ),
        ),
      ],
    );
  }
}

/// Individual swipe direction button
class _SwipeDirectionButton extends StatelessWidget {
  final String direction;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwipeDirectionButton({
    required this.direction,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (direction == 'left') ...[
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: h.currentTextTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Text(
                label,
                style: h.currentTextTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable widget for text size adjustment
class TextSizeSelector extends ConsumerWidget {
  final int currentSize;
  final ValueChanged<int> onChanged;

  const TextSizeSelector({
    super.key,
    required this.currentSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          onPressed: currentSize > 12 
              ? () => onChanged(currentSize - 2)
              : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
          ),
        ),
        
        Expanded(
          child: Slider(
            value: currentSize.toDouble(),
            min: 12,
            max: 24,
            divisions: 6,
            activeColor: AppColors.primary,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        
        IconButton(
          onPressed: currentSize < 24 
              ? () => onChanged(currentSize + 2)
              : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Reusable widget for displaying current text size
class TextSizeDisplay extends StatelessWidget {
  final int size;

  const TextSizeDisplay({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${size}px',
          style: h.currentTextTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Reusable widget for preview section
class PreviewSection extends StatelessWidget {
  final String text;
  final double fontSize;

  const PreviewSection({
    super.key,
    required this.text,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: h.currentTextTheme.bodyMedium?.copyWith(
          fontSize: fontSize,
          height: 1.4,
        ),
      ),
    );
  }
}
