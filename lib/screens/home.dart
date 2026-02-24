import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/debounce.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/widgets/animations/loading_indicator_bar.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/feed_swiper.dart';
import '../widgets/home/reading_streak_footer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  AppRepository get r => ref.read(appRepositoryProvider);
  bool get _isFeedLoading => _feedType.watch(ref).isLoading;

  late final Debounce _topicChangeDebounce = const Duration(milliseconds: 500).debounce;
  late FeedType _feedType;
  var _isWillExit = false;

  @override
  void initState() {
    _feedType = r.homeFeedType;
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initReadCount();
      _loadFeed();
      fireAndForget(saveAllData);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _topicChangeDebounce.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      fireAndForget(saveAllData);
    } else if (state == AppLifecycleState.resumed) {
      _initReadCount();
      _loadFeed();
    }
  }

  Future<void> _openFeed([FeedType? feedType]) async {
    await ref.read(topicProvider.notifier).clear();
    setState(() {
      _feedType = feedType ?? r.homeFeedType;
    });
    _loadFeed();
  }

  Future<void> _openFeedLatest() => _openFeed(FeedType.latest);
  Future<void> _openFeedTrending() => _openFeed(FeedType.trending);

  Future<void> _loadFeed([String? topic]) async {
    final success = await r.loadFeed(feedType: _feedType, topic: topic);
    if (mounted && !success) return _showLoadFeedFailed(() => _loadFeed(topic));
  }

  /// Reset read count if it's a new day
  void _initReadCount() {
    if (r.isNewDay) {
      log("[home] It's a new day, so reset the read count");
      ref.read(readCountProvider.notifier).setValue(0);
      ref.read(readLastDateProvider.notifier).setValue(today);
    } else {
      log("[home] Welcome back, it's still the same day");
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

      // Debounce rapid topic tab switching to prevent excessive API calls
      _topicChangeDebounce.run(() {
        if (!mounted) return;
        setState(() {
          // _feedType = next == null ? r.homeFeedType : FeedType.latest;
          _feedType = FeedType.latest;
        });
        _loadFeed(next);
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isWillExit) {
          // Save all user data before exit
          fireAndForget(saveAllData);
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
              HomeHeader(
                feedType: _feedType,
                onSeeTrending: _openFeedTrending,
                onSeeHome: _openFeed,
              ),
              FeedSwiper(
                feedType: _feedType,
                onReload: _loadFeed,
                onSeeLatest: _openFeedLatest,
                onSeeHome: _openFeed,
              ).expand(),
              if (_isFeedLoading)
                // Loading indicator at the bottom
                LoadingIndicatorBar()
              else if (_feedType == FeedType.digest)
                // Reading streak progress
                ReadingStreakFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
