import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed/feed_liked.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/providers/feed/feed_trending.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart' show FeedType;

/// Business-logic repository. Uses Ref, never WidgetRef.
/// Expose via provider so it can be watched or read anywhere.
class AppRepository {
  AppRepository(this._ref);

  final Ref _ref;

  User get user => _ref.read(userProvider);
  UserPreferences get preferences => _ref.read(preferencesProvider);
  UserStreaks get streaks => _ref.read(streaksProvider);
  DateTime? get ingestLastDate => _ref.read(ingestLastDateProvider);
  DateTime? get readLastDate => _ref.read(readLastDateProvider);
  int get readCount => _ref.read(readCountProvider);

  /// Whether today's digest feed fetch is done or due
  bool get isDailyDigestUpToDate => ingestLastDate != null && isToday(ingestLastDate!) && _ref.read(feedProvider).isAvailable;
  bool get shouldFetchDailyDigest => !isDailyDigestUpToDate;

  /// Digest feed is newer than last read (even though it's not today)
  bool get newDigestFeedAvailable => readLastDate == null || ingestLastDate?.isAfter(readLastDate!) == true;

  /// Digest feed is available today
  bool get newDigestFeedAvailableToday => isDailyDigestUpToDate;

  /// User preferences
  List<String> get preferredTopics => preferences.topics;
  List<String> get avoidedTopics => preferences.avoidedTopics;

  /// Whether user completed daily digest reading (streak)
  bool get isStreakToday => _ref.read(streaksProvider.notifier).isStreakToday;
  bool get isDailyDigestDone => isSameDay(ingestLastDate, streaks.lastReadAt);

  /// Reset read count if it's a new daily digest
  Future<bool> initReadCount({bool force = false}) async {
    if (newDigestFeedAvailable || force) {
      log("[home] It's a new daily digest, so reset the read count");
      await Future.wait([
        _ref.read(readCountProvider.notifier).setValue(0),
        _ref.read(readLastDateProvider.notifier).setValue(ingestLastDate),
      ]);
      return true;
    } else {
      log("[home] Welcome back, it's still the same daily digest");
      return false;
    }
  }
  
  /// Determine home feed type
  FeedType get homeFeedType => isDailyDigestDone ? FeedType.latest : FeedType.digest;

  Future<bool> loadFeed({FeedType? feedType, String? topic}) async {
    feedType ??= homeFeedType;

    // Check if we should load the feed
    if (feedType == FeedType.digest && isDailyDigestUpToDate) {
      log("[loadFeed] ${feedType.name.toCapitalized()} feed is up to date");
      return true;
    }

    // Check internet connectivity
    if (!await isOnline()) {
      log("[loadFeed] No internet connection, skipping feed load");
      return false;
    }

    return feedType.loadWithRef(_ref, topic: topic);
  }

  /// Load initial user and feed data on app launch/resume
  Future<bool> initData() async {
    if (!await isOnline()) {
      log("[initData] No internet connection, skipping feed load");
      return false;
    }
    final results = await Future.wait<bool>([
      _ref.read(userProvider.notifier).load(),
      _ref.read(feedTrendingProvider.notifier).load(),
      _ref.read(topicsProvider.notifier).load(),
      loadFeed(),
    ]);
    final isSuccess = results.every((result) => result);
    return isSuccess;
  }

  /// Load initial settings data on navigate to settings
  Future<bool> initSettingsData() async {
    if (!await isOnline()) {
      log("[initSettingsData] No internet connection, skipping load");
      return false;
    }
    final results = await Future.wait<bool>([
      _ref.read(feedLikedProvider.notifier).load(),
      _ref.read(feedSavedProvider.notifier).load(),
    ]);
    final isSuccess = results.every((result) => result);
    return isSuccess;
  }
}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref);
});