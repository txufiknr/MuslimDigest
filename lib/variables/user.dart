import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/settings.dart';
import 'package:uuid/uuid.dart';

var isFirstRun = prefs.getString('user') == null;
bool get isExistingUser => !isFirstRun;

enum Gender {
  male,
  female;

  String get label {
    switch (this) {
      case male: return 'Muslim';
      case female: return 'Muslimah';
    }
  }

  MaterialColor get color {
    switch (this) {
      case male: return Colors.blue;
      case female: return Colors.pink;
    }
  }

  static Gender? fromString(String? name) {
    return values.firstWhereOrNull((e) => e.name == name);
  }
}

class PrefData {
  /// User data and preferences getters
  /// 
  /// This file provides centralized access to user-related data from SharedPreferences
  /// with proper null safety and JSON parsing.

  /// Returns cached user data from SharedPreferences
  /// 
  /// Retrieves stored user information and parses it into User model.
  /// Returns null if no user data is stored.
  /// 
  /// Example:
  /// ```
  /// final currentUser = PrefData.user;
  /// if (currentUser != null) {
  ///   print('User name: ${currentUser.name}');
  /// }
  /// ```
  static User get user {
    final userString = prefs.getString('user');
    if (userString == null) return User(userId: const Uuid().v7());
    return User.fromJson(jsonDecode(userString));
  }

  /// Returns cached user preferences from SharedPreferences
  /// 
  /// Retrieves stored user preferences and parses them into UserPreferences model.
  /// Returns null if no preferences are stored.
  /// 
  /// Example:
  /// ```
  /// final userPrefs = PrefData.preferences;
  /// if (userPrefs != null) {
  ///   print('Dark mode: ${userPrefs.darkMode}');
  /// }
  /// ```
  static UserPreferences get preferences {
    final preferencesString = prefs.getString('preferences');
    if (preferencesString == null) return UserPreferences(userId: user.userId);
    return UserPreferences.fromJson(jsonDecode(preferencesString));
  }

  /// Returns cached user streaks from SharedPreferences
  /// 
  /// Retrieves stored user streaks and parses them into UserStreaks model.
  /// Returns null if no streaks are stored.
  /// 
  /// Example:
  /// ```
  /// final userStreaks = PrefData.streaks;
  /// if (userStreaks != null) {
  ///   print('Current streak: ${userStreaks.currentStreak}');
  /// }
  /// ```
  static UserStreaks get streaks {
    final streaksString = prefs.getString('streaks');
    if (streaksString == null) return UserStreaks();
    return UserStreaks.fromJson(jsonDecode(streaksString));
  }

  /// Returns cached user settings from SharedPreferences
  /// 
  /// Retrieves stored user settings and parses them into UserSettings model.
  /// Returns default settings if no settings are stored.
  /// 
  /// Example:
  /// ```
  /// final userSettings = PrefData.settings;
  /// print('Text size: ${userSettings.textSize}');
  /// print('Swipe direction: ${userSettings.swipeDirection}');
  /// ```
  static UserSettings get settings {
    final settingsString = prefs.getString('settings');
    if (settingsString == null) return UserSettings(userId: user.userId);
    return UserSettings.fromJson(jsonDecode(settingsString));
  }

  /// Returns the date when the user last read content
  /// 
  /// Parses the stored date string or returns current date if not found.
  /// 
  /// Example:
  /// ```
  /// final lastRead = PrefData.readLastDate;
  /// print('Last read: ${lastRead.toIso8601String()}');
  /// ```
  static DateTime get readLastDate {
    final dateStr = prefs.getString('read_last_date');
    if (dateStr == null) return DateTime.now();
    return DateTime.parse(dateStr);
  }

  static NotificationType get notificationType {
    final value = prefs.getString('notification_type');
    if (value == null) return NotificationType.all;
    return NotificationType.fromString(value);
  }

  /// Returns cached user read count states from SharedPreferences
  /// 
  /// Retrieves stored user read count states and parses them into a map.
  /// Returns empty map if no states are stored.
  /// 
  /// Example:
  /// ```
  /// final readCountStates = PrefData.readCountStates;
  /// print('Read count states: $readCountStates');
  /// ```
  static Map<String, int> get readCountStates {
    final statesString = prefs.getString('read_count_states');
    if (statesString == null) return {};
    // final decoded = jsonDecode(statesString) as Map<String, dynamic>;
    // return decoded.map((key, value) => MapEntry(key, value as int));
    return Map<String, int>.from(jsonDecode(statesString));
  }

  static DateTime? get ingestLastFetch {
    final dateStr = prefs.getString('ingest_last_fetch');
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }
}
