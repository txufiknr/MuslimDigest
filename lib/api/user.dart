import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed/feed_liked.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/api.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/variables/user.dart';

final latestSavedData = <String, Map<String, dynamic>?>{};

/// Save user, preferences, and streaks data with retry mechanism
Future<bool> saveAllData({bool force = false}) async {
  final futures = [
    _getLatestData('user', PrefData.user, (user) => user.toJson(), force),
    _getLatestData('preferences', PrefData.preferences, (prefs) => prefs.toJson(), force),
    _getLatestData('settings', PrefData.settings, (settings) => settings.toJson(), force),
    _getLatestData('streaks', PrefData.streaks, (streaks) => streaks.toJson(), force),
  ].nonNulls;

  final responses = await Future.wait(
    futures.map((future) => retryWithBackOff(() => future)),
  );

  final successCount = responses.where((result) => result.success).length;
  final failedCount = responses.length - successCount;
  
  if (failedCount > 0) {
    debugPrint('[saveAllData] $failedCount requests failed after retries');
  }
  
  debugPrint('[saveAllData] Save result: $successCount/${responses.length} success');
  return successCount == responses.length;
}

/// Generic function to get and save latest data if changed
Future? _getLatestData<T>(
  String key,
  T currentData,
  Map<String, dynamic> Function(T) toJson,
  bool force,
) {
  // 1. Compare between latest saved data and curent data
  final latestData = latestSavedData[key];
  final currentDataJson = toJson(currentData);
  if (!force && latestData != null && MapEquality().equals(latestData, currentDataJson)) {
    return null;
  }
  
  // 2. Save data to backend when they're different
  latestSavedData.addAll({key: currentDataJson});
  return ApiService.post(key, currentDataJson);
}

Future<void> logStreak(WidgetRef ref) async {
  final streaksNotifier = ref.read(streaksProvider.notifier);

  // 1. Check if today's streak has been logged
  final isStreakToday = streaksNotifier.isStreakToday;
  if (isStreakToday) return;

  // 2. Earn reading streak today
  final streaks = ref.read(streaksProvider);
  final currentStreak = streaks.currentStreak;
  final longestStreak = streaks.longestStreak;
  final newCurrentStreak = currentStreak + 1;
  final newLongestStreak = max(longestStreak, newCurrentStreak);
  final newStreaks = UserStreaks(
    currentStreak: newCurrentStreak,
    longestStreak: newLongestStreak,
    lastReadAt: today
  );

  // 3. Save user streaks
  await streaksNotifier.setValue(newStreaks);
}

Future<void> resetUserData(WidgetRef ref) async {
  fireAndForget(() => ApiService.post('user/reset'));
  await Future.wait([
    // User data
    ref.read(userProvider.notifier).clear(),
    ref.read(streaksProvider.notifier).clear(),
    ref.read(settingsProvider.notifier).clear(),
    ref.read(preferencesProvider.notifier).clear(),
    // Activity data
    ref.read(topicProvider.notifier).clear(),
    ref.read(readCountProvider.notifier).clear(),
    ref.read(readLastDateProvider.notifier).clear(),
    // Feed data
    ref.read(feedProvider.notifier).clear(),
    ref.read(feedLikedProvider.notifier).clear(),
    ref.read(feedSavedProvider.notifier).clear(),
  ]);
}