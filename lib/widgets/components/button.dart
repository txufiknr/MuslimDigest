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

class MyButtonLabel extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Brightness? brightness;
  final double size;
  final MyButtonVariant variant;

  const MyButtonLabel(this.label, {
    super.key,
    this.isLoading = false,
    this.brightness,
    this.size = 20,
    this.variant = MyButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Text(label);
    final color = brightness == Brightness.dark ? Colors.white : variant.color;
    return CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ).sized(width: size, height: size);
  }
}

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Brightness? brightness;
  final bool isLoading;
  final bool outlined;
  final MyButtonVariant variant;
  
  const MyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.brightness,
    this.isLoading = false,
    this.outlined = false,
    this.variant = MyButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final buttonHeight = height ?? 56;
    final buttonStyle = brightness == null ? null : brightness == Brightness.dark 
        ? AppThemes.elevatedButtonStyleDark.copyWith(foregroundColor: WidgetStatePropertyAll(variant.color)) 
        : AppThemes.elevatedButtonStyleLight.copyWith(backgroundColor: WidgetStatePropertyAll(variant.color));
    final outlinedButtonStyle = brightness == null ? null : brightness == Brightness.dark 
        ? AppThemes.outlinedButtonStyleDark.copyWith(foregroundColor: WidgetStatePropertyAll(Colors.white)) 
        : AppThemes.outlinedButtonStyleLight.copyWith(foregroundColor: WidgetStatePropertyAll(variant.color));
    final label = MyButtonLabel(
      text,
      isLoading: isLoading,
      brightness: brightness,
      variant: variant,
      size: buttonHeight / 2,
    );
    final onPressedHandler = isDisabled ? null : onPressed;
    
    return (outlined
      ? OutlinedButton(onPressed: onPressedHandler, style: outlinedButtonStyle, child: label)
      : ElevatedButton(onPressed: onPressedHandler, style: buttonStyle, child: label)
    ).withOpacity(isDisabled ? 0.75 : 1.0).sized(
      width: width ?? double.infinity,
      height: buttonHeight,
    );
  }
}
