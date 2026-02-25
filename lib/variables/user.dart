import 'dart:convert';

import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/settings.dart';
import 'package:uuid/uuid.dart';

enum Gender {
  male,
  female;

  String get label {
    switch (this) {
      case male: return 'Muslim';
      case female: return 'Muslimah';
    }
  }

  static Gender fromString(String name) {
    return values.firstWhere((e) => e.name == name);
  }
}

class PrefData {
  /// User data and preferences getters
  /// 
  /// This file provides centralized access to user-related data from SharedPreferences
  /// with proper null safety and JSON parsing.

  /// Returns user ID, generating a new one if it doesn't exist
  /// 
  /// This ensures a consistent user identifier across app sessions.
  /// 
  /// Example:
  /// ```
  /// final id = PrefData.userId;
  /// print('User ID: $id');
  /// ```
  // static String get userId {
  //   final existingUserId = user.userId;
  //   return existingUserId;
  // }

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

  // static String? get currentTopic => prefs.getString('topic');
  // static String? get feedLastIngest => prefs.getString('ingest_last_date');
  // static DateTime? get feedLastIngestDate => feedLastIngest != null ? DateTime.parse(feedLastIngest!) : null;

  static NotificationType get notificationType {
    final value = prefs.getString('notification_type');
    if (value == null) return NotificationType.all;
    return NotificationType.fromString(value);
  }
}
