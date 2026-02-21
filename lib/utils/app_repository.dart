import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
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
import 'package:muslimdigest/variables/time.dart';

/// Business-logic repository. Uses Ref, never WidgetRef.
/// Expose via provider so it can be watched or read anywhere.
class AppRepository {
  AppRepository(this._ref);

  final Ref _ref;

  User get user => _ref.read(userProvider);
  UserPreferences get preferences => _ref.read(preferencesProvider);
  UserStreaks get streaks => _ref.read(streaksProvider);
  DateTime get readLastDate => _ref.read(readLastDateProvider) ?? today;
  DateTime? get ingestLastDate => _ref.read(ingestLastDateProvider);
  int get readCount => _ref.read(readCountProvider);

  bool get isNewDay => !isToday(readLastDate);

  bool get shouldLoadFeedToday => ingestLastDate == null || !isToday(ingestLastDate!) || _ref.read(feedProvider).isNone;

  // String get firstName {
  //   final name = extractFirstName(user.name);
  //   if (name.isNotEmpty) return name;
  //   return switch (user.gender) {
  //     'male' => 'Brother',
  //     'female' => 'Sister',
  //     _ => 'Friend',
  //   };
  // }

  List<String> get preferredTopics => preferences.topics;
  List<String> get avoidedTopics => preferences.avoidedTopics;

  bool get isStreakToday => _ref.read(streaksProvider.notifier).isStreakToday;
  bool get isDailyDigestDone => isStreakToday || isSameDay(ingestLastDate, streaks.lastReadAt);
  FeedType get homeFeedType => isDailyDigestDone ? FeedType.latest : FeedType.digest;

  Future<bool> loadFeed({FeedType? feedType, String? topic}) async {
    feedType ??= homeFeedType;

    // Check if we should load the feed
    if (feedType == FeedType.digest && !shouldLoadFeedToday) {
      log("[loadFeed] ${feedType.name.toCapitalized()} feed is up to date");
      return true;
    }

    // Check internet connectivity
    if (!await isOnline()) {
      log("[loadFeed] No internet connection, skipping feed load");
      return false;
    }

    return feedType.loadWithRef(_ref, topic: topic);
    // if (feedType == FeedType.latest) {
    //   return _ref.read(feedLatestProvider.notifier).load();
    // }
    // return _ref.read(feedProvider.notifier).load(topic: topic);
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
}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref);
});