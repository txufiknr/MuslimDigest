import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
// import 'package:muslimdigest/providers/feed/feed_liked.dart';
// import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/providers/feed/feed_trending.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/topic.dart';
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
import 'package:muslimdigest/variables/user.dart';

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
  FeedState get feedState => _ref.read(feedProvider);

  /// Whether today's digest feed fetch is done or due
  bool get isDailyDigestUpToDate => ingestLastDate != null && isToday(ingestLastDate!) && feedState.isAvailable;
  bool get shouldFetchDailyDigest => !isDailyDigestUpToDate; // && !feedState.isLoading;

  /// Digest feed is newer than last read (even though it's not today)
  bool get newDigestFeedAvailable => readLastDate == null || ingestLastDate?.isAfter(readLastDate!) == true;

  /// Digest feed is available today
  bool get newDigestFeedAvailableToday => isDailyDigestUpToDate;

  /// User preferences
  Set<String> get preferredTopics => preferences.topics;
  Set<String> get avoidedTopics => preferences.avoidedTopics;

  /// Whether user completed daily digest reading (streak)
  bool get isStreakToday {
    if (!_ref.mounted) return false;
    return _ref.read(streaksProvider.notifier).isStreakToday;
  }
  bool get isDailyDigestDone => isSameDay(ingestLastDate, streaks.lastReadAt);

  /// Reset read count if it's a new daily digest
  Future<bool> initReadCount({bool force = false}) async {
    if (newDigestFeedAvailable || force) {
      log("[home] 🧾 It's a new daily digest, read count has been reset");
      await Future.wait([
        _ref.read(readCountProvider.notifier).setValue(0),
        _ref.read(readLastDateProvider.notifier).setValue(ingestLastDate),
      ]);
      return true;
    } else {
      log("[home] 👋 Welcome back, it's still the same daily digest");
      return false;
    }
  }

  Future<void> resetReadCount(FeedType feedType, String? topic) async {
    if (feedType == FeedType.digest) {
      await initReadCount(force: true);
    } else {
      final newStates = _ref.read(readCountStatesProvider)..remove(topic ?? feedType.name);
      await _ref.read(readCountStatesProvider.notifier).setValue(newStates);
    }
  }
  
  /// Determine home feed type
  // FeedType get homeFeedType => shouldFetchDailyDigest || !isDailyDigestDone ? FeedType.digest : FeedType.latest;
  FeedType get homeFeedType {
    if (isFirstRun) return FeedType.digest; // always digest for first time user
    if (!_ref.mounted) return FeedType.latest;
    return !isStreakToday && (shouldFetchDailyDigest || !isDailyDigestDone) ? FeedType.digest : FeedType.latest;
  }

  Future<bool> loadFeed({FeedType? feedType, String? topic, bool force = false}) async {
    feedType ??= homeFeedType;

    // Check if we should load the feed
    if (!force && feedType == FeedType.digest && isDailyDigestUpToDate) {
      log("[loadFeed] ✅ ${feedType.name.toCapitalized()} feed is up to date");
      return true;
    }

    // Check internet connectivity
    if (!await isOnline()) {
      log("[loadFeed] ⚠️ No internet connection, skipping feed load");
      return false;
    }

    // Reset swiper page index to zero
    if (force) unawaited(resetReadCount(feedType, topic));

    return feedType.loadWithRef(_ref, topic: topic, force: force);
  }

  Future<void> loadUserFeed({bool force = false}) async {
    // Intentional design: skips feed loading during splash for first-time users to
    // prioritize onboarding experience, only loading the daily digest after they complete
    // the initial setup and reach the home screen.
    if (isFirstRun) return;
    
    if (!force && !shouldFetchDailyDigest) return;
    log('[loadUserFeed] isDailyDigestUpToDate: $isDailyDigestUpToDate');
    log('[loadUserFeed] isDailyDigestDone: $isDailyDigestDone');
    log('[loadUserFeed] readLastDate: $readLastDate');
    log('[loadUserFeed] ingestLastDate: $ingestLastDate');
    log('[loadUserFeed] today: $today');
    log('[loadUserFeed] isToday(ingestLastDate): ${isToday(ingestLastDate!)}');
    log('[loadUserFeed] homeFeedType: ${homeFeedType.name}');
    log('[loadUserFeed] shouldFetchDailyDigest: $shouldFetchDailyDigest');
    final isFeedLoaded = await loadFeed(force: force);
    log("[loadUserFeed] ${isFeedLoaded ? '✅ Feed loaded successfully (${homeFeedType.name})' : '❌ Failed to load feed (${homeFeedType.name})'}");
    if (isFeedLoaded && homeFeedType == FeedType.digest) {
      await initReadCount(force: force);
    }
  }

  /// Initialize active feed tab on every app launch
  Future<void> initActiveFeed() async {
    if (isFirstRun) return; // no need to do anything for first time user
    final currentFeedType = _ref.read(feedTypeProvider);
    final currentTopic = _ref.read(topicProvider);
    final trendingCount = _ref.watch(feedTrendingProvider).total;
    if (!currentFeedType.isHomeFeed || currentTopic != null || (currentFeedType == FeedType.trending && trendingCount == 0)) {
      // Go back to home feed tab without any topic selected
      await Future.wait([
        _ref.read(topicProvider.notifier).clear(),
        _ref.read(feedTypeProvider.notifier).setValue(homeFeedType),
        _initReadCountStates(),
      ]);
    }
  }

  Future<void> _initReadCountStates() async {
    final currentReadCountStates = _ref.read(readCountStatesProvider);
    final homeFeedTypes = FeedType.values.where((f) => f.isHomeFeed).map((f) => f.name);
    currentReadCountStates.removeWhere((name, _) => !homeFeedTypes.contains(name));
    await _ref.read(readCountStatesProvider.notifier).setValue({
      ...currentReadCountStates
    });
    log('🧾 init read count states: ${_ref.read(readCountStatesProvider)}');
  }

  /// Load initial user and feed data on app launch/resume
  Future<bool> initData() async {
    if (!await isOnline()) {
      log("[initData] ⚠️ No internet connection, skipping feed load");
      return false;
    }
    final results = await Future.wait<bool>([
      if (isExistingUser) _ref.read(userProvider.notifier).load(),
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
      log("[initSettingsData] ⚠️ No internet connection, skipping load");
      return false;
    }
    final results = await Future.wait<bool>([
      _ref.read(userProvider.notifier).load(),
    ]);
    final isSuccess = results.every((result) => result);
    return isSuccess;
  }
}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref);
});