import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/utils/route.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

/// Secure storage singleton instance
/// 
/// Global FlutterSecureStorage instance for secure persistent storage
/// across the entire application. Must be initialized before use.
/// 
/// Example:
/// ```
/// await secureStorage.write(key: 'key', value: 'value');
/// final value = await secureStorage.read(key: 'key');
/// ```
late final FlutterSecureStorage secureStorage;

final inAppReview = InAppReview.instance;
final sharePlus = SharePlus.instance;

final routeObserver = MyRouteObserver();

String get copyrightText => '© ${DateTime.now().year} $APP_COPYRIGHT';

String get userAgent => '$APP_USER_AGENT/$appVersion';