import 'package:flutter/material.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
final defaultTheme = platformBrightness == Brightness.dark ? APP_UI_THEME_DARK : APP_UI_THEME_LIGHT;

// Singleton instances
late final SharedPreferencesWithCache prefs;

// Shared preferences
String? get userId => prefs.getString('uuid');