import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/debounce.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
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

  late final Debounce _topicChangeDebounce = const Duration(milliseconds: 500).debounce;
  late final AppLifecycleListener _lifeCycleListener;
  UserPreferences? lastUserPreferences;
  var _isWillExit = false;


  /// Save all user data
  void _saveAllData() {
    fireAndForget(saveAllData);
  }

  void _saveUserPreferences() {
    lastUserPreferences = ref.read(preferencesProvider);
  }

  void _compareUserPreferences() {
    if (lastUserPreferences == null) return;
    final userPreferences = ref.read(preferencesProvider);
    if (userPreferences != lastUserPreferences) {
      r.loadUserFeed(force: true);
    }
    lastUserPreferences = null;
    _saveAllData();
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
    _topicChangeDebounce.dispose();
    _lifeCycleListener.dispose();
    super.dispose();
  }

  Future<void> _openFeed([FeedType? feedType]) async {
    final currentFeedType = feedType ?? r.homeFeedType;
    await Future.wait([
      ref.read(topicProvider.notifier).clear(),
      ref.read(feedTypeProvider.notifier).setValue(currentFeedType),
    ]);
    if (currentFeedType == FeedType.digest) {
      r.loadUserFeed();
    } else {
      _loadFeed();
    }
  }

  Future<void> _openFeedLatest() => _openFeed(FeedType.latest);
  Future<void> _openFeedTrending() => _openFeed(FeedType.trending);

  Future<void> _loadFeed([FeedType? feedType, String? topic]) async {
    feedType ??= ref.read(feedTypeProvider);
    final success = await r.loadFeed(feedType: feedType, topic: topic);
    if (mounted && !success) return _showLoadFeedFailed(() => _loadFeed(feedType, topic));
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

      // Debounce rapid topic tab switching to prevent excessive API calls
      _topicChangeDebounce.run(() {
        if (!mounted) return;
        ref.read(feedTypeProvider.notifier).setValue(FeedType.latest);
        _loadFeed(FeedType.latest, next);
      });
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
        body: SafeArea(
          child: Column(
            children: [
              // Feed type and topic tabs
              HomeHeader(
                onSeeTrending: _openFeedTrending,
                onSeeHome: _openFeed,
              ),
              // Main feed swiper
              FeedSwiper(
                onReload: _loadFeed,
                onSeeLatest: _openFeedLatest,
                onSeeHome: _openFeed,
              ).expand(),
              // Loader or reading streak progressbar
              ReadingStreakFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
