import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

class MyHelper {
  MyHelper(this.context);
  final BuildContext context;
  
  // Screen dimensions
  MediaQueryData get mediaQuery => MediaQuery.of(context);
  EdgeInsets get viewInsets => EdgeInsets.fromViewPadding(View.of(context).viewInsets, View.of(context).devicePixelRatio);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  double get viewInsetsBottom => viewInsets.bottom;

  // Theme configurations
  AppTheme get appTheme => ThemeProvider.themeOf(context);
  ThemeData get currentTheme => appTheme.data;
  String get currentThemeID => appTheme.id;
  bool get isLightTheme => currentThemeID == Brightness.light.name;
  bool get isDarkTheme => !isLightTheme;
  TextTheme get currentTextTheme => currentTheme.textTheme;
  TextStyle? get inputStyle => currentTextTheme.bodyMedium;
  TextStyle? get inputStyleLarge => currentTextTheme.bodyLarge;
  // TODO: are these used?
  TextStyle? get hintStyle => inputStyle?.copyWith(color: currentTheme.hintColor);
  TextStyle? get hintStyleLarge => inputStyleLarge?.copyWith(color: currentTheme.hintColor);

  // Theme helpers
  int pickShade(int lightShade) {
    switch (lightShade) {
      case 50: return isLightTheme ? 50 : 900;
      case 100: return isLightTheme ? 100 : 800;
      case 200: return isLightTheme ? 200 : 700;
      case 300: return isLightTheme ? 300 : 600;
      case 400: return isLightTheme ? 400 : 500;
      case 500: return isLightTheme ? 500 : 400;
      case 600: return isLightTheme ? 600 : 300;
      case 700: return isLightTheme ? 700 : 200;
      case 800: return isLightTheme ? 800 : 100;
      case 900: return isLightTheme ? 900 : 50;
      default: return isLightTheme ? lightShade : 500;
    }
  }
  Color? useColor(MaterialColor color, [int lightShade = 500]) => color[pickShade(lightShade)];
  Color pickColor(Color light, Color dark) => isLightTheme ? light : dark;
  void nextTheme() => ThemeProvider.controllerOf(context).nextTheme();

  ShapeBorder get popupShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15.0),
    side: BorderSide(
      color: currentTheme.colorScheme.outline,
      width: 1.0,
    ),
  );

  Decoration get cardDecoration => BoxDecoration(
    color: currentTheme.colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // NavigatorState get _navigator => Navigator.of(context);
  
  // void pop([dynamic result]) => _navigator.pop(result);
}