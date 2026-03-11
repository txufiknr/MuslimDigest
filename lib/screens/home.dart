import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/notification_scheduler.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/tour.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/feed_swiper.dart';
import '../widgets/home/reading_streak_footer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  AppRepository get r => ref.read(appRepositoryProvider);

  // late final Debounce _topicChangeDebounce = const Duration(milliseconds: 500).debounce;
  late final AppLifecycleListener _lifeCycleListener;
  UserPreferences? lastUserPreferences;
  var _isWillExit = false;
  
  // Request cancellation tracking
  String? _currentFeedRequestId;
  static int _requestCounter = 0;

  /// Init feed loading
  void _initFeed() async {
    final feedType = ref.read(feedTypeProvider);
    final isNone = feedType.read(ref).isNone;
    if (isNone) {
      log('🧾 Feed is empty and need loading...');
      await r.loadUserFeed(force: true);
      if (mounted && r.newDigestFeedAvailable) {
        final h = MyHelper(context);
        final feedItems = ref.read(feedProvider).items ?? [];
        final totalStories = feedItems.length;
        final totalMinutes = feedItems.fold(0.0, (sum, item) => sum + (item.readTimeSeconds));
        showBottomModalSheetContent(
          context,
          title: "Today's Digest",
          widgets: [
            Row(
              children: [
                Icon(CupertinoIcons.book, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "$totalStories ${totalStories == 1 ? 'story' : 'stories'} for you",
                  style: h.currentTextTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.clock, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "${totalMinutes.round()} ${totalMinutes.round() == 1 ? 'minute' : 'minutes'} read",
                  style: h.currentTextTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.lightbulb, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Curated content tailored to your interests",
                      style: h.currentTextTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
        );
      }
    }
  }

  /// Save all user data
  void _saveAllData() {
    fireAndForget(saveAllData);
  }

  void _saveUserPreferences() {
    lastUserPreferences = ref.read(preferencesProvider);
  }

  void _reloadFeed() {
    final feedType = ref.read(feedTypeProvider);
    final topic = ref.read(topicProvider);
    _loadFeed(feedType: feedType, topic: topic, force: true);
  }

  void _compareUserPreferences() async {
    if (lastUserPreferences == null) return;
    final userPreferences = ref.read(preferencesProvider);
    
    // Check if topic preferences have changed
    final topicsChanged = !setEquals(userPreferences.topics, lastUserPreferences!.topics);
    final avoidedTopicsChanged = !setEquals(userPreferences.avoidedTopics, lastUserPreferences!.avoidedTopics);
    final isChanged = topicsChanged || avoidedTopicsChanged;

    log('[_compareUserPreferences] topicsChanged = $topicsChanged');
    log('[_compareUserPreferences] avoidedTopicsChanged = $avoidedTopicsChanged');
    
    lastUserPreferences = null;

    if (!isChanged) return;
    _saveAllData();

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
      onInactive: _saveAllData,
      onResume: r.loadUserFeed,
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
    // _topicChangeDebounce.dispose();
    _lifeCycleListener.dispose();
    super.dispose();
  }

  Future<void> _openFeed({FeedType? feedType, bool force = false}) async {
    final currentFeedType = feedType ?? r.homeFeedType;
    await Future.wait([
      ref.read(topicProvider.notifier).clear(),
      ref.read(feedTypeProvider.notifier).setValue(currentFeedType),
    ]);
    if (currentFeedType == FeedType.digest) {
      r.loadUserFeed();
    } else {
      // Check read count state to optimize feed loading
      final readCountStates = ref.read(readCountStatesProvider);
      final feedTypeKey = currentFeedType.name;
      final readCount = readCountStates[feedTypeKey] ?? 0;
      
      // Skip reloading if user has already read items
      if (readCount > 0) return;

      // Load feed - cache check is handled internally
      _loadFeed(feedType: currentFeedType);
    }
  }

  Future<void> _openFeedLatest({bool force = false}) => _openFeed(feedType: FeedType.latest, force: force);
  Future<void> _openFeedTrending({bool force = false}) => _openFeed(feedType: FeedType.trending, force: force);

  Future<void> _loadFeed({FeedType? feedType, String? topic, bool force = false}) async {
    feedType ??= ref.read(feedTypeProvider);
    
    // Cancel previous request and create new request ID
    _currentFeedRequestId = 'feed_${++_requestCounter}_${feedType?.name ?? 'unknown'}_${topic ?? 'default'}';
    
    log('[HomePage] Starting feed load with request ID: $_currentFeedRequestId');
    
    final success = await r.loadFeed(
      feedType: feedType, 
      topic: topic, 
      force: force,
      requestId: _currentFeedRequestId,
    );
    
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

      // Debounce rapid topic tab switching to prevent excessive API calls
      // _topicChangeDebounce.run(() {
        // if (!mounted) return;
        // Cancel previous feed request and start new one
        log('[HomePage] Topic changed from $previous to $next, cancelling previous request');
        _loadFeed(feedType: FeedType.latest, topic: next);
      // });
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
                    onSeeHome: _openFeed,
                  ).expand(),
                  // Loader or reading streak progressbar
                  ReadingStreakFooter(),
                ],
              ),
            ),

            // Tour animation
            if (isFirstRun) Tour()
          ],
        ),
      ),
    );
  }
}
