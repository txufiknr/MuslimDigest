import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application-level variables and singleton instances
/// 
/// This file contains global app configuration, theme detection,
/// and shared preferences initialization for the entire application.

/// Device platform brightness and theme detection based on system brightness
/// 
/// Detects the system's current brightness setting to determine
/// the appropriate default theme for the application.
/// 
/// Example:
/// ```
/// if (defaultTheme == Brightness.dark.name) {
///   print('System is in dark mode');
/// }
/// ```
// final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
// final defaultTheme = platformBrightness.name;
final defaultTheme = Brightness.light.name;

/// Application version string
/// 
/// Current version of the Muslim Digest app. This should be
/// updated with each release and displayed in settings/about.
/// 
/// Example:
/// ```
/// print('App version: $appVersion');
/// ```
var appVersion = '1.0.0';

/// Shared preferences singleton instance
/// 
/// Global SharedPreferencesWithCache instance for persistent storage
/// across the entire application. Must be initialized before use.
/// 
/// Example:
/// ```
/// await prefs.setString('key', 'value');
/// final value = prefs.getString('key');
/// ```
late final SharedPreferencesWithCache prefs;