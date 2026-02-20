import 'dart:convert';

import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:uuid/uuid.dart';

String? newUserId;

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
  static String get userId {
    final existingUserId = newUserId ?? prefs.getString('user_id');
    if (existingUserId == null) {
      newUserId = const Uuid().v7();
      prefs.setString('user_id', newUserId!);
      return newUserId!;
    }
    return existingUserId;
  }

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
  static User? get user {
    final userString = prefs.getString('user');
    if (userString == null) return null;
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
  static UserPreferences? get preferences {
    final preferencesString = prefs.getString('preferences');
    if (preferencesString == null) return null;
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
  static UserStreaks? get streaks {
    final streaksString = prefs.getString('streaks');
    if (streaksString == null) return null;
    return UserStreaks.fromJson(jsonDecode(streaksString));
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

  static String? get currentTopic => prefs.getString('topic');
  static String? get feedLastIngest => prefs.getString('feed_last_ingest');
  static DateTime? get feedLastIngestDate => feedLastIngest != null ? DateTime.parse(feedLastIngest!) : null;
}
