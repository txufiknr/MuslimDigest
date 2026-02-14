import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

class MyHelper {
  MyHelper(this.context);
  final BuildContext context;
  
  // Screen dimensions
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // Theme configurations
  AppTheme get appTheme => ThemeProvider.themeOf(context);
  ThemeData get currentTheme => appTheme.data;
  String get currentThemeID => appTheme.id;
  bool get isLightTheme => currentThemeID == Brightness.light.name;
  bool get isDarkTheme => !isLightTheme;
  TextTheme get currentTextTheme => currentTheme.textTheme;

  // Theme helpers
  Color pickColor(Color light, Color dark) => isLightTheme ? light : dark;
  void nextTheme() => ThemeProvider.controllerOf(context).nextTheme();

  ScaffoldMessengerState? get _scaffoldMessenger => context.mounted ? ScaffoldMessenger.of(context) : null;
  NavigatorState get _navigator => Navigator.of(context);
  
  void pop([dynamic result]) => _navigator.pop(result);
  
  void showSnackBar(String message, {bool showAction = false, String? actionLabel, VoidCallback? action}) {
    _scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        action: showAction ? SnackBarAction(label: actionLabel ?? "Close", onPressed: action ?? pop) : null,
      ),
    );
  }
  void hideSnackBar() => _scaffoldMessenger?.hideCurrentSnackBar();
}