import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/debounce.dart';
import 'package:muslimdigest/services/notifications/notification_scheduler.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/card.dart';
import 'package:muslimdigest/widgets/components/tour.dart';
import 'package:muslimdigest/widgets/user/reads_rank.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/feed_swiper.dart';
import '../widgets/home/reading_streak_footer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  late final Debounce _digestLoadDebounce = const Duration(milliseconds: 500).debounce;
  late final AppLifecycleListener _lifeCycleListener;
  UserPreferences? _lastUserPreferences;
  DateTime? _lastActiveDate;
  var _isWillExit = false;

  // Request cancellation tracking
  String? _currentFeedRequestId;
  static int _requestCounter = 0;
  
  /// Digest summary display tracking (idempotent)
  bool _isDigestSummaryShowing = false;
  
  /// Read notifiers
  AppRepository get r => ref.read(appRepositoryProvider);
  FeedType get _currentFeedType => ref.read(feedTypeProvider);
  int get _currentReadCount => ref.read(readCountProvider);
  bool get _isFeedLoading => ref.watch(feedTypeProvider).watch(ref).isLoading;
  String? get _currentTopic => ref.read(topicProvider);
  // bool get _isDigest => _currentFeedType.isDigest;

  /// Init feed loading with duplicate prevention
  void _initFeed() {
    if (_onActive()) return;

    final feedType = _currentFeedType;
    if (!feedType.isDigest && r.homeFeedType.isDigest) {
      log("[home] 👋 Welcome back! Let's continue with your daily digest");
      _openFeed(force: r.shouldForceReloadDigest);
      return;
    }

    final feedState = feedType.read(ref);

    // Check if feed is already loading (from welcome pre-load or other source)
    if (feedState.isLoading) {
      log('🧾 Feed ${feedType.name} is already loading, skipping duplicate request...');
      return;
    }
    
    // If not loading but feed is empty, reload it
    if (feedState.isNone) {
      log('🧾 Feed ${feedType.name} is empty and need loading...');
      _reloadFeed();
    }
  }

  /// Idempotent digest summary display (safe to call multiple times, only shows once)
  void _showDigestSummaryIdempotent() async {
    if (_isDigestSummaryShowing) {
      log('[HomePage] 👀 Digest summary already showing, skipping duplicate call');
      return;
    }
    
    if (!mounted) return;
    
    _isDigestSummaryShowing = true;
    log("[HomePage] 🌟 Showing today's digest summary");
    
    // Show digest summary and reset flag when complete
    await _showDigestSummary();

    // Reset flag when dialog is dismissed
    _isDigestSummaryShowing = false;
  }

  Future<void> _showDigestSummary() async {
    if (!mounted) return;

    final feedItems = ref.read(feedProvider).items ?? [];
    final totalStories = feedItems.length;
    final totalSeconds = feedItems.fold(0.0, (sum, item) => sum + (item.readTimeSeconds));
    final totalMinutes = (totalSeconds / 60).floor();

    final h = MyHelper(context);

    // States
    final firstName = ref.read(userProvider).firstName;
    final streaks = ref.read(streaksProvider);

    // Conditions
    final currentStreak = streaks.currentStreak;

    final goToDigest = await showBottomModalSheetContent(
      context,
      title: "Today's Digest",
      widgets: <Widget>[
        Text("$GREETINGS, $firstName", style: h.currentTextTheme.titleSmall,),
        SizedBox(height: 8),
        UserReadsRank(),
        const SizedBox(height: 16),
        Text(
          getHijriDate(),
          style: h.currentTextTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        SummaryCard(
          icon: CupertinoIcons.book,
          caption: "$totalStories ${totalStories == 1 ? 'story' : 'stories'} for you",
        ).riseIn(duration: 1000),
        SizedBox(height: 16),
        SummaryCard(
          icon: CupertinoIcons.clock,
          caption: "${totalMinutes.round()} ${totalMinutes.round() == 1 ? 'minute' : 'minutes'} read",
        ).riseIn(delay: 200, duration: 1000),
        SizedBox(height: 16),
        SummaryCard(
          icon: CupertinoIcons.calendar,
          caption: "$currentStreak day streak",
        ).riseIn(delay: 200, duration: 1000),
        SizedBox(height: 24),
        MyButton(text: "Start Reading", icon: Icon(CupertinoIcons.book), onPressed: () => Navigator.pop(context, true)),
      ]
    ) ?? false;

    if (mounted && goToDigest) _openFeed();
  }

  void _onInactive() {
    _lastActiveDate = DateTime.now();
    _saveAllData();
  }

  bool get _isNewDay => !isToday(_lastActiveDate) || r.shouldForceReloadDigest;

  bool _onActive() {
    log('🧾 [init] _onActive _isNewDay: $_isNewDay');
    log('🧾 [init] _onActive r.shouldShowDigest: ${r.shouldShowDigest}');
    
    if (_isNewDay) {
      log("[home] 👋 Welcome back! It's a new day since you left, we'll load your digest");
      _openFeed(force: true);
      
      // Ensure digest summary shows on new day (idempotent)
      _showDigestSummaryIdempotent();
      return true;
    }
    
    _checkNewDigest();
    return false;
  }

  /// Save all user data
  void _saveAllData() {
    fireAndForget(saveAllData);
  }

  void _saveUserPreferences() {
    _lastUserPreferences = ref.read(preferencesProvider);
  }

  void _reloadFeed() {
    final feedType = _currentFeedType;
    if (feedType.isDigest) {
      _checkNewDigest(force: true);
      return;
    }
    _loadFeed(feedType: feedType, topic: _currentTopic, force: true);
    _checkNewDigest();
  }

  void _compareUserPreferences() async {
    if (_lastUserPreferences == null) return;

    final userPreferences = ref.read(preferencesProvider);

    // Check if topic preferences have changed
    final topicsChanged = !setEquals(userPreferences.topics, _lastUserPreferences!.topics);
    final avoidedTopicsChanged = !setEquals(userPreferences.avoidedTopics, _lastUserPreferences!.avoidedTopics);
    final isChanged = topicsChanged || avoidedTopicsChanged;

    log('[_compareUserPreferences] topicsChanged = $topicsChanged');
    log('[_compareUserPreferences] avoidedTopicsChanged = $avoidedTopicsChanged');

    _lastUserPreferences = null;

    if (!isChanged) return;

    // Save all user data, including new preferences
    _saveAllData();

    if (topicsChanged) {
      // Remove removed topic keys from readCountState
      final currentReadCountStates = ref.read(readCountStatesProvider);
      ref.read(readCountStatesProvider.notifier).setValue({
        ...currentReadCountStates..removeWhere((name, _) => !userPreferences.topics.contains(name)),
      });
    }

    final currentTopic = _currentTopic;
    if (currentTopic != null) {
      // Check if current active topic has been removed from interests
      if (!userPreferences.topics.contains(currentTopic)) {
        _openFeed();
      }

      // Check if digest feed need reloading
      _checkNewDigest();
      return;
    }
    
    // Offer to reload the feed after preferences update
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reload = await showBottomModalConfirm(
        context,
        title: "Preferences Updated",
        message: "Would you like to refresh your feed with the new recommendations?",
        confirmButtonText: "Yes, please refresh",
        confirmButtonIcon: Icon(CupertinoIcons.refresh),
        cancelButtonText: "Continue reading",
        cancelButtonIcon: Icon(CupertinoIcons.book),
      );
      if (mounted && reload == true) {
        _reloadFeed();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _lifeCycleListener = AppLifecycleListener(
      onInactive: _onInactive,
      onResume: _onActive,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _saveAllData();
      _initFeed();
      // Request notification permissions and schedule daily reminder
      NotificationScheduler.requestPermissionsAndSchedule();
    });
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
    super.didChangeDependencies();
  }

  // RouteAware lifecycle methods - called in sequence during navigation
  
  /// Called when this route is pushed onto the navigator.
  @override
  void didPush() {
    debugPrint('HOME onStart - Page pushed onto navigator');
  }

  /// Called when a new route is pushed on top of this route.
  @override
  void didPushNext() {
    debugPrint('HOME onPause - Away from this page to another page');
    _saveUserPreferences();
  }

  /// Called when the top route is popped and this route becomes visible again.
  @override
  void didPopNext() {
    debugPrint('HOME onResume - Returning to this page from another page');
    _compareUserPreferences();
  }

  /// Called when this route is popped from the navigator.
  @override
  void didPop() {
    debugPrint('HOME onStop - Page is completely removed');
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _digestLoadDebounce.dispose();
    _lifeCycleListener.dispose();
    super.dispose();
  }

  Future<void> _openFeed({FeedType? feedType, bool force = false}) async {
    final currentFeedType = feedType ?? r.homeFeedType;
    log('[home] _openFeed feedType = $currentFeedType (original: $feedType)');
    await Future.wait([
      ref.read(topicProvider.notifier).clear(),
      ref.read(feedTypeProvider.notifier).setValue(currentFeedType),
    ]);

    _checkNewDigest();

    if (currentFeedType.isDigest) return;

    // Check read count state to optimize feed loading
    final readCountStates = ref.read(readCountStatesProvider);
    final feedTypeKey = currentFeedType.name;
    final readCount = readCountStates[feedTypeKey] ?? 0;

    log('[home] _openFeed readCountStates = $readCountStates');
    log('[home] _openFeed feedTypeKey = $feedTypeKey');
    log('[home] _openFeed readCount = $readCount');
    
    // Skip reloading if user has already read items and not forcing reload
    if (readCount > 0 && !force) return;

    // Load feed - cache check is handled internally
    _loadFeed(feedType: currentFeedType, force: force);
  }

  Future<void> _checkNewDigest({bool force = false}) async {
    await r.loadFeed(force: force);
  }

  Future<void> _openFeedLatest({bool force = false}) => _openFeed(feedType: FeedType.latest, force: force);
  Future<void> _openFeedTrending({bool force = false}) => _openFeed(feedType: FeedType.trending, force: force);

  Future<void> _loadFeed({FeedType? feedType, String? topic, bool force = false}) async {
    feedType ??= _currentFeedType;
    
    // Cancel previous feed/latest topic requests before starting new one
    // This prevents race conditions when user changes topics rapidly
    if (feedType == FeedType.latest && topic != null) {
      cancelFeedLatestTopicRequests();
      log('[home] Cancelled previous feed/latest topic requests for topic: $topic');
    }
    
    // Cancel previous request and create new request ID
    _currentFeedRequestId = 'feed_${++_requestCounter}_${feedType.name}_${topic ?? 'default'}';
    
    log('[home] Starting feed load with request ID: $_currentFeedRequestId');
    
    final success = await r.loadFeed(
      feedType: feedType, 
      topic: topic, 
      force: force,
      requestId: _currentFeedRequestId,
    );

    final readCountStates = ref.read(readCountStatesProvider);
    final feedTypeKey = feedType.name;
    final readCount = readCountStates[feedTypeKey] ?? 0;
    log('[home] _loadFeed readCountStates = $readCountStates');
    log('[home] _loadFeed feedTypeKey = $feedTypeKey');
    log('[home] _loadFeed readCount = $readCount');
    
    // Only show error if this is still the current request
    if (mounted && !success && _currentFeedRequestId != null) {
      return _showLoadFeedFailed(() => _loadFeed(feedType: feedType, topic: topic, force: force));
    }
  }

  Future<void> _showLoadFeedFailed(Future<void> Function() onRetry) async {
    final shouldRetry = await showRetryableError(
      context,
      title: 'Failed to fetch feed items.',
      message: 'Failed to load your feed. Would you like to retry?',
      footer: 'Or try checking your internet connection first.',
    );
    if (shouldRetry) {
      return onRetry();
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for topic changes and trigger load feed with debounce
    ref.listen<String?>(topicProvider, (previous, next) {
      if (!mounted || previous == next) return;
      if (next == null) return;

      ref.read(feedTypeProvider.notifier).setValue(FeedType.latest);

      // Cancel previous API call and start new one
      log('[HomePage] Topic changed from $previous to $next, cancelling previous request');
      _loadFeed(feedType: FeedType.latest, topic: next);
    });

    // Listen for digest load and show digest summary
    ref.listen<FeedState>(feedProvider, (previous, next) {
      if (!mounted || previous == next) return;
      if (!(previous?.isLoading ?? false)) return; // if not previously loading
      if (next.isLoading) return; // if still loading
      if (next.isEmpty) return; // if empty

      final readLastDate = ref.read(readLastDateProvider);
      final isNewDay = readLastDate == null || !isToday(readLastDate);
      final isNewDayBasedOnActive = _isNewDay;
      
      log('[HomePage] Feed loaded: isNewDay=$isNewDay, isNewDayBasedOnActive=$isNewDayBasedOnActive, isDigest=${_currentFeedType.isDigest}');
      
      // Trigger digest summary from feed listener (idempotent - safe to call multiple times)
      // (New day scenarios are handled by _onActive and feed type change listener)
      if (_currentFeedType.isDigest) {
        _digestLoadDebounce.run(_showDigestSummaryIdempotent);
      }
    });
    
    // Listen for digest feed type change and show digest summary
    ref.listen<FeedType>(feedTypeProvider, (previous, next) {
      if (!mounted || previous == next) return;
      if (!next.isDigest) return; // if not digest

      final readCount = _currentReadCount;
      final isNewDay = _isNewDay;
      
      log('[HomePage] Feed type changed to digest: readCount=$readCount, isNewDay=$isNewDay');
      
      // Show digest summary if it's digest (idempotent - safe to call multiple times)
      if (next.isDigest) {
        _digestLoadDebounce.run(_showDigestSummaryIdempotent);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isWillExit) {
          // Save all user data before exit
          _saveAllData();
          _isWillExit = true;
          showSnackBar(context, 'Press back again to exit');
          // if (APP_IN_DEVELOPMENT) _showDigestSummary();
          delay(2000, () {
            _isWillExit = false;
            hideSnackBar(context);
          });
        } else {
          quit();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Feed type and topic tabs
                  HomeHeader(
                    onSeeTrending: _openFeedTrending,
                    onSeeHome: _openFeed,
                  ),
                  // Main feed swiper
                  FeedSwiper(
                    onReload: () => _loadFeed(force: true),
                    onSeeLatest: () => _openFeedLatest(force: true),
                    onSeeHome: () => _openFeed(force: true),
                  ).expand(),
                  // Loader or reading streak progressbar
                  ReadingStreakFooter(),
                ],
              ),
            ),

            // Tour animation
            if (isFirstRun && !_isFeedLoading) Tour()
          ],
        ),
      ),
    );
  }
}
