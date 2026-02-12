import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';

enum MyButtonVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  info;

  Color get color {
    switch (this) {
      case MyButtonVariant.primary:
        return AppColors.primary;
      case MyButtonVariant.secondary:
        return AppColors.secondary;
      case MyButtonVariant.success:
        return AppColors.success;
      case MyButtonVariant.warning:
        return AppColors.warning;
      case MyButtonVariant.error:
        return AppColors.error;
      case MyButtonVariant.info:
        return AppColors.info;
    }
  }
}

enum IconPlacement {
  left,
  right,
  top,
  bottom;
}

class MyButtonLabel extends StatelessWidget {
  final String label;
  final bool outlined;
  final bool isLoading;
  final Brightness brightness;
  final double size;
  final MyButtonVariant variant;
  final Widget? icon;
  final IconPlacement iconPlacement;

  const MyButtonLabel(this.label, {
    super.key,
    this.outlined = false,
    this.isLoading = false,
    this.brightness = Brightness.light,
    this.size = 20,
    this.variant = MyButtonVariant.primary,
    this.icon,
    this.iconPlacement = IconPlacement.left,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = outlined
      ? (brightness == Brightness.dark ? Colors.white : variant.color)
      : (brightness == Brightness.dark ? variant.color : Colors.white);
    final textWidget = Text(label, style: TextStyle(color: textColor));

    if (icon == null && !isLoading) return textWidget;
    final iconSize = size * 0.75;
    final iconGap = size * 0.35;

    final iconWidget = isLoading ? CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(textColor),
    ).squared(iconSize)
      
    : IconTheme(
      data: IconThemeData(
        color: textColor,
        size: iconSize,
      ),
      child: icon!,
    );

    switch (iconPlacement) {
      case IconPlacement.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(width: iconGap),
            textWidget,
          ],
        );
      case IconPlacement.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            textWidget,
            SizedBox(width: iconGap),
            iconWidget,
          ],
        );
      case IconPlacement.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(height: iconGap),
            textWidget,
          ],
        );
      case IconPlacement.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            textWidget,
            SizedBox(height: iconGap),
            iconWidget,
          ],
        );
    }
  }
}

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Brightness brightness;
  final bool isLoading;
  final bool outlined;
  final MyButtonVariant variant;
  final Widget? icon;
  final IconPlacement iconPlacement;
  
  const MyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.brightness = Brightness.light,
    this.isLoading = false,
    this.outlined = false,
    this.variant = MyButtonVariant.primary,
    this.icon,
    this.iconPlacement = IconPlacement.left,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final buttonHeight = height ?? 56;
    
    // Create custom button styles with proper WidgetStateProperty wrapping
    final isDarkTheme = brightness == Brightness.dark;
    final buttonStyle = outlined ? AppThemes.outlinedButtonStyleLight.copyWith(
      side: WidgetStatePropertyAll(BorderSide(color: isDarkTheme ? Colors.white : variant.color)),
      foregroundColor: WidgetStatePropertyAll(isDarkTheme ? Colors.white : variant.color),
    ) : AppThemes.elevatedButtonStyleLight.copyWith(
      backgroundColor: WidgetStatePropertyAll(isDarkTheme ? Colors.white : variant.color),
      foregroundColor: WidgetStatePropertyAll(isDarkTheme ? variant.color : Colors.white),
    );
    
    final label = MyButtonLabel(
      text,
      isLoading: isLoading,
      brightness: brightness,
      variant: variant,
      size: buttonHeight / 2,
      icon: icon,
      iconPlacement: iconPlacement,
      outlined: outlined,
    );
    final onPressedHandler = isDisabled ? null : onPressed;
    
    return (outlined
      ? OutlinedButton(onPressed: onPressedHandler, style: buttonStyle, child: label)
      : ElevatedButton(onPressed: onPressedHandler, style: buttonStyle, child: label)
    ).withOpacity(isDisabled ? 0.75 : 1.0).sized(
      width: width ?? double.infinity,
      height: buttonHeight,
    );
  }
}
