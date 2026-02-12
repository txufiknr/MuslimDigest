import 'package:flutter/material.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App info
final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
final defaultTheme = platformBrightness == Brightness.dark ? APP_UI_THEME_DARK : APP_UI_THEME_LIGHT;
var appVersion = '1.0.0';

// User info
User? user;

// Singleton instances
late final SharedPreferencesWithCache prefs;

// Shared preferences
String? get userId => prefs.getString('user_id');