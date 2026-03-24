import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
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
import 'package:muslimdigest/utils/route.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart' show FeedType;
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
  Map<String, int> get currentReadCountStates => _ref.read(readCountStatesProvider);
  String? get currentTopic => _ref.read(topicProvider);
  FeedType get currentFeedType => _ref.read(feedTypeProvider);

  /// Whether today's digest feed fetch is done or due
  bool get isDailyDigestUpToDate => ingestLastDate != null && isToday(ingestLastDate!) && feedState.isAvailable;
  // "Do we have today's content?"
  bool get shouldFetchDailyDigest => !isDailyDigestUpToDate;

  /// Digest feed is newer than last read (even though it's not today)
  bool get newDigestFeedAvailable => readLastDate == null || ingestLastDate?.isAfter(readLastDate!) == true;

  /// User preferences
  Set<String> get preferredTopics => preferences.topics;
  Set<String> get avoidedTopics => preferences.avoidedTopics;

  /// Whether user completed daily digest reading (streak)
  bool get isStreakToday => _ref.mounted && _ref.read(streaksProvider.notifier).isStreakToday;
  bool get isDailyDigestCompleted => isSameDay(ingestLastDate, streaks.lastReadAt);

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
    log("[resetReadCount] 🚮 Resetting read count");
    if (feedType.isDigest) {
      await initReadCount(force: true);
    } else {
      await _ref.read(readCountStatesProvider.notifier).setValue({
        ...currentReadCountStates..remove(topic ?? feedType.name)
      });
    }
  }
  
  /// Determine home feed type
  bool get shouldShowDigest {
    if (!_ref.mounted || isFirstRun) return true; // always digest for first time user
    log('[homeFeedType] isStreakToday = $isStreakToday');
    log('[homeFeedType] shouldFetchDailyDigest = $shouldFetchDailyDigest');
    log('[homeFeedType] shouldForceReloadDigest = $shouldForceReloadDigest');
    log('[homeFeedType] isDailyDigestCompleted = $isDailyDigestCompleted');
    if (isStreakToday) return false; // has streak today
    return shouldFetchDailyDigest || shouldForceReloadDigest || newDigestFeedAvailable || !isDailyDigestCompleted;
  }

  /// Determine if digest should be reloaded (new day)
  /// Already handles if ingestLastDate is null (isToday accepts null, returning false)
  /// "Should we fetch fresh content for new day?"
  bool get shouldForceReloadDigest => !isToday(ingestLastDate);

  /// Determine home feed type
  FeedType get homeFeedType => shouldShowDigest ? FeedType.digest : FeedType.latest;

  /// Get current page index for a feed type
  int getCurrentPageIndex([FeedType? feedType]) {
    feedType ??= currentFeedType;
    final readCountStates = _ref.read(readCountStatesProvider);
    final readCountStateKey = (feedType.isLatest ? currentTopic : null) ?? feedType.name;
    return readCountStates[readCountStateKey] ?? 0;
  }

  /// Load feed data
  Future<bool> loadFeed({FeedType? feedType, String? topic, bool force = false, String? requestId, Map<String, String>? queryParams}) async {
    feedType ??= homeFeedType;

    if (feedType.isDigest) {
      log('[loadUserFeed] ❓ isDailyDigestUpToDate = $isDailyDigestUpToDate');
      log('[loadUserFeed] ❓ shouldFetchDailyDigest = $shouldFetchDailyDigest');
      log('[loadUserFeed] ❓ ingestLastDate = $ingestLastDate');
      log('[loadUserFeed] ❓ ingestLastDate today = ${ingestLastDate != null && isToday(ingestLastDate!)}');
      log('[loadUserFeed] ❓ feedState.isAvailable = ${feedState.isAvailable}');
      log('[loadUserFeed] ❓ isFirstRun = $isFirstRun');
      log('[loadUserFeed] ❓ currentRoute = $currentRoute');

      // First time user: will load personalized feed after onboarding
      if (isFirstRun && currentRoute != 'home') return false;
      
      // Daily digest is up to date
      if (!force && isDailyDigestUpToDate) {
        log('🧾 Digest feed is up to date, no need to refresh...');
        return false;
      }
    } else {
      // Always load digest feed silently
      unawaited(loadFeed(feedType: FeedType.digest, force: shouldForceReloadDigest));
    }

    // Check internet connectivity
    if (!await isOnline()) {
      log("[loadFeed] ⚠️ No internet connection, skipping feed load");
      return false;
    }

    if (!force && getCurrentPageIndex(feedType) > 0) {
      log("[loadFeed] ⏩ Skipping ${feedType.name} feed reload when at page: ${getCurrentPageIndex(feedType)}");
      return false;
    }

    final isFeedLoaded = await feedType.loadWithRef(_ref, topic: topic, force: force, requestId: requestId, queryParams: queryParams);
    if (isFeedLoaded) {
      if (feedType.isDigest) {
        initReadCount(force: force);
      } else if (force) {
        resetReadCount(feedType, topic);
      }
    }

    return isFeedLoaded;
  }

  /// Initialize active feed tab on every app launch
  Future<void> initActiveFeed() async {
    if (isFirstRun) return; // no need to do anything for first time user
    final trendingCount = _ref.read(feedTrendingProvider).total;
    if (homeFeedType.isDigest || !currentFeedType.isHomeFeed || currentTopic != null || (currentFeedType == FeedType.trending && trendingCount == 0)) {
      // Go back to home feed tab without any topic selected
      log('🧾 [init] initActiveFeed homeFeedType: $homeFeedType');
      await Future.wait([
        _ref.read(topicProvider.notifier).clear(),
        _ref.read(feedTypeProvider.notifier).setValue(homeFeedType),
        if (homeFeedType.isDigest) initReadCount()
        else _initReadCountStates(),
      ]);
    }
  }

  /// Reset latest and trending feed current page to zero on every app launch
  Future<void> _initReadCountStates() async {
    final homeFeedTypes = FeedType.values.where((f) => f.isHomeFeed).map((f) => f.name);
    await _ref.read(readCountStatesProvider.notifier).setValue({
      ...currentReadCountStates..removeWhere((name, _) => !homeFeedTypes.contains(name))
    });
    log('🧾 [init] _initReadCountStates: ${_ref.read(readCountStatesProvider)}');
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