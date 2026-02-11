import 'package:flutter/material.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Brightness? brightness;
  
  const MyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = brightness == null ? null : brightness == Brightness.dark 
        ? AppThemes.elevatedButtonStyleDark 
        : AppThemes.elevatedButtonStyleLight;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(text),
      ).withOpacity(onPressed == null ? 0.75 : 1.0),
    );
  }
}

class MyOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Brightness? brightness;
  
  const MyOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = brightness == null ? null : brightness == Brightness.dark 
        ? AppThemes.outlinedButtonStyleDark 
        : AppThemes.outlinedButtonStyleLight;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(text),
      ).withOpacity(onPressed == null ? 0.75 : 1.0),
    );
  }
}
