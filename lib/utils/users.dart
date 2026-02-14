import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/variables/app.dart';

// Future<void> getUser() async {
//   final responses = await Future.wait([
//     ApiService.get('user'), // Get user data
//     ApiService.get('preferences'), // Get user preferences
//     ApiService.get('streaks'), // Get user reading streaks
//   ]);

//   // Process responses using the utility function
//   await handleUserResponses(responses);
// }

/// Handle user data and preferences responses from API
/// 
/// This function processes the responses from concurrent API calls to fetch
/// user data and preferences. It handles the 404 case by cleaning up invalid
/// user data and provides proper error logging for debugging.
/// 
/// Parameters:
///   - [responses]: List of `ApiResponse` objects containing user and preferences data
/// 
/// Returns:
///   - `Future<void>` - Completes when all data is processed
/// 
/// Example:
/// ```dart
/// final responses = await Future.wait([
///   ApiService.getUser(),
///   ApiService.getPreferences(),
///   ApiService.getStreaks(),
/// ]);
/// await handleUserResponses(responses, newUser: newUser, newUserPreferences: newUserPreferences);
/// ```
Future<void> handleUserResponses(List<ApiResponse> responses, {User? newUser, UserPreferences? newUserPreferences}) async {
  final userResponse = responses[0];
  final preferencesResponse = responses[1];
  final streaksResponse = responses.length > 2 ? responses[2] : null;

  if (userResponse.statusCode == 404) {
    // User not found - clean up invalid user data
    debugPrint('[handleUserResponses] User not found (404), cleaning up user data');
    await Future.wait(['user', 'preferences', 'streaks'].map(prefs.remove));
    return;
  }

  await Future.wait([
    // Handle user response
    handleUserResponse(userResponse, newUser),

    // Handle preferences response
    handlePreferencesResponse(preferencesResponse, newUserPreferences),
    
    // Handle streaks response
    handleStreaksResponse(streaksResponse),
  ]);
}

Future<void> handleUserResponse(ApiResponse? response, User? newData) async {
  if (response == null) return;
  if (response.success && response.data != null) {
    debugPrint('[handleUserResponses] User data obtained successfully');
    // Cache user data locally for offline access
    await setUser(User.fromJson(response.data));
  } else {
    debugPrint('[handleUserResponses] Failed to fetch user data: ${response.error}');
    if (newData != null) await setUser(newData);
  }
}

Future<void> handlePreferencesResponse(ApiResponse? response, UserPreferences? newData) async {
  if (response == null) return;
  if (response.success && response.data != null) {
    debugPrint('[handleUserResponses] User preferences obtained successfully');
    // Cache preferences locally
    final preferences = UserPreferences.fromJson(response.data);
    await setUserPreferences(preferences);
  } else {
    debugPrint('[handleUserResponses] Failed to fetch preferences: ${response.error}');
    if (newData != null) await setUserPreferences(newData);
  }
}

Future<void> handleStreaksResponse(ApiResponse? response) async {
  if (response == null) return;
  if (response.success && response.data != null) {
    debugPrint('[handleUserResponses] User streaks obtained successfully');
    debugPrint('[handleUserResponses] User streaks: ${response.data}');
    // Cache streaks locally
    final streaks = UserStreaks.fromJson(response.data);
    await prefs.setString('streaks', jsonEncode(streaks.toJson()));
  } else {
    debugPrint('[handleUserResponses] Failed to fetch streaks: ${response.error}');
  }
}

Future<void> setUser(User user) async {
  await prefs.setString('user', jsonEncode(user.toJson()));
}

Future<void> setUserPreferences(UserPreferences preferences) async {
  await prefs.setString('preferences', jsonEncode(preferences.toJson()));
}

/// Extracts the first name from a full name string
/// 
/// Removes common honorifics and prefixes like "Mr.", "Mrs.", "Dr.", etc.
/// and returns the first word as the first name.
/// 
/// Parameters:
///   - [fullName]: The full name string to extract the first name from
/// 
/// Returns:
///   - `String` - The extracted first name, or empty string if input is invalid
/// 
/// Example:
/// ```dart
/// final firstName = extractFirstName('Mr. John Doe');
/// print(firstName); // Output: 'John'
/// ```
/// 
/// Note: This function is case-insensitive and handles multiple prefix formats.
/// It is designed to work with common English honorifics and religious titles.
String extractFirstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '';
  
  final trimmedName = fullName.trim();
  
  // Remove common honorifics and prefixes
  final prefixes = ['mr.', 'mrs.', 'ms.', 'miss.', 'dr.', 'prof.', 'sir.', 'madam.', 'brother', 'sister'];
  var nameWithoutPrefix = trimmedName.toLowerCase();
  
  for (final prefix in prefixes) {
    if (nameWithoutPrefix.startsWith(prefix)) {
      nameWithoutPrefix = nameWithoutPrefix.substring(prefix.length).trim();
      break;
    }
  }
  
  // If we removed a prefix, use the modified name, otherwise use original
  final finalName = nameWithoutPrefix != trimmedName.toLowerCase() ? nameWithoutPrefix : trimmedName;
  
  // Split by spaces and get the first word
  final parts = finalName.split(RegExp(r'\s+'));
  return parts.isNotEmpty ? parts.first : finalName;
}