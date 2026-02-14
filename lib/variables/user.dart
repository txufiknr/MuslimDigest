import 'dart:convert';

import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:uuid/uuid.dart';

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
/// final id = userId;
/// print('User ID: $id');
/// ```
String get userId {
  final existingUserId = prefs.getString('user_id');
  if (existingUserId == null) {
    final newUserId = const Uuid().v7();
    prefs.setString('user_id', newUserId);
    return newUserId;
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
/// final currentUser = user;
/// if (currentUser != null) {
///   print('User name: ${currentUser.name}');
/// }
/// ```
User? get user {
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
/// final userPrefs = preferences;
/// if (userPrefs != null) {
///   print('Dark mode: ${userPrefs.darkMode}');
/// }
/// ```
UserPreferences? get preferences {
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
/// final userStreaks = streaks;
/// if (userStreaks != null) {
///   print('Current streak: ${userStreaks.currentStreak}');
/// }
/// ```
UserStreaks? get streaks {
  final streaksString = prefs.getString('streaks');
  if (streaksString == null) return null;
  return UserStreaks.fromJson(jsonDecode(streaksString));
}

/// Returns personalized greeting based on user's first name or gender
/// 
/// Extracts first name from user's full name, falling back to gender-based
/// greetings ("Brother" for male, "Sister" for female) or "Friend" if unknown.
/// 
/// Example:
/// ```
/// final greeting = firstName;
/// print('Hello, $greeting!');
/// ```
String get firstName {
  final userFirstName = extractFirstName(user?.name);
  if (userFirstName.isNotEmpty) return userFirstName;
  if (user?.gender == 'male') return 'Brother';
  if (user?.gender == 'female') return 'Sister';
  return 'Friend';
}

/// Returns the date when the user last read content
/// 
/// Parses the stored date string or returns current date if not found.
/// 
/// Example:
/// ```
/// final lastRead = readLastDate;
/// print('Last read: ${lastRead.toIso8601String()}');
/// ```
DateTime get readLastDate {
  final dateStr = prefs.getString('read_last_date');
  if (dateStr == null) return DateTime.now();
  return DateTime.parse(dateStr);
}

/// Returns the number of articles read today
/// 
/// Retrieves the daily read count from SharedPreferences.
/// 
/// Example:
/// ```
/// final count = readCount;
/// print('Articles read today: $count');
/// ```
int get readCount => prefs.getInt('read_count') ?? 0;

bool get isNewDay => !isSameDay(today, readLastDate);

bool get isFirstRun => user == null;