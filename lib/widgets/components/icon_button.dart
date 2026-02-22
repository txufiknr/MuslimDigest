import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/helpers.dart';

/// Custom IconButton widget with consistent styling and tooltip support
class MyIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final Color? iconColor;
  final double radius;
  final bool outlined;

  const MyIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.iconColor,
    this.radius = 20.0,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor ?? h.currentTheme.colorScheme.onSurface),
      iconSize: iconSize,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: size == null ? null : Size(size!, size!),
        shape: RoundedRectangleBorder(
          side: outlined ? BorderSide(color: h.currentTheme.colorScheme.outline) : BorderSide.none,
          borderRadius: BorderRadius.circular(radius),
        ),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
