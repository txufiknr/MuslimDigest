import 'dart:async';
import 'dart:math' show max;
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed/feed_liked.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/providers/feed/feed_trending.dart';
import 'package:muslimdigest/providers/feed/feed_latest.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
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

final latestSavedData = <String, dynamic>{};

/// Saves the latest versions of all user-related data to backend with retry mechanism
Future<bool> saveAllData({bool force = false}) async {
  final futures = [
    _getLatestData<User>('user', PrefData.user, (user) => user.toJson(), force),
    _getLatestData<UserPreferences>('preferences', PrefData.preferences, (prefs) => prefs.toJson(), force),
    _getLatestData<UserSettings>('settings', PrefData.settings, (settings) => settings.toJson(), force),
    _getLatestData<UserStreaks>('streaks', PrefData.streaks, (streaks) => streaks.toJson(), force),
  ].nonNulls;

  final responses = await Future.wait(
    futures.map((future) => retryWithBackOff(() => future)),
  );

  final successCount = responses.where((result) => result.success).length;
  final failedCount = responses.length - successCount;
  
  if (failedCount > 0) {
    log('[saveAllData] ⚠️ $failedCount requests failed after retries');
  }
  
  log('[saveAllData] ${failedCount > 0 ? '⚠️' : '✅'} Save result: $successCount/${responses.length} success');
  return successCount == responses.length;
}

/// Generic function to track and save the latest data if changed
Future? _getLatestData<T>(
  String key,
  T currentData,
  Map<String, dynamic> Function(T) toJson,
  bool force,
) {
  // 1. Compare between latest saved data and current data using == operator
  final latestData = latestSavedData[key] as T?;
  if (!force && latestData != null && latestData == currentData) {
    return null;
  }
  
  // 2. Save data to backend when they're different
  latestSavedData[key] = currentData;
  return ApiService.post(key, toJson(currentData));
}

/// Logs the user's reading streak
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

/// Resets all user data
Future<void> resetUserData(WidgetRef ref) async {
  fireAndForget(() => ApiService.post('user/reset'));
  
  await Future.wait<void>([
    // Clear all feed caches first to ensure cache invalidation
    ref.read(feedCacheProvider).clearAllCache(),
    // User data
    ref.read(userProvider.notifier).clear(),
    ref.read(streaksProvider.notifier).clear(),
    ref.read(settingsProvider.notifier).clear(),
    ref.read(preferencesProvider.notifier).clear(),
    // Activity data
    ref.read(topicProvider.notifier).clear(),
    ref.read(readCountProvider.notifier).clear(),
    ref.read(readCountStatesProvider.notifier).clear(),
    ref.read(readLastDateProvider.notifier).clear(),
    ref.read(feedTypeProvider.notifier).reset(),
    // Feed data
    ref.read(feedProvider.notifier).clear(),
    ref.read(feedLikedProvider.notifier).clear(),
    ref.read(feedSavedProvider.notifier).clear(),
    ref.read(feedTrendingProvider.notifier).clear(),
    ref.read(feedLatestProvider.notifier).clear(),
  ]);
}