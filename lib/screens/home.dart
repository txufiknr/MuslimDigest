import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/streaks.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/variables/user.dart';
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
  UserStreaks? get streaks => ref.watch(streaksProvider);
  bool get _isStreakToday => ref.watch(streaksProvider.notifier).isStreakToday;
  bool get _isDailyDigestDone => _isStreakToday || PrefData.feedLastIngestDate == streaks?.lastReadAt;
  FeedType get _homeFeedType => _isDailyDigestDone ? FeedType.latest : FeedType.digest;
  late var _feedType = _homeFeedType;

  AppRepository get r => ref.read(appRepositoryProvider);
  bool get _isFeedLoading => _feedType.watch(ref).isLoading;

  var _isWillExit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initFeed();
      _initReadCount();
      fireAndForget(saveAllData);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      fireAndForget(saveAllData);
    } else if (state == AppLifecycleState.resumed) {
      _initReadCount();
      _initFeed();
    }
  }

  void _seeLatestFeed() {
    setState(() {
      _feedType = _homeFeedType;
    });
  }

  Future<void> _loadFeed([String? topic]) async {
    final success = await _feedType.load(ref, topic: topic);
    if (!mounted) return;
    if (!success) {
      return _showLoadFeedFailed(() => _loadFeed(topic));
    }
  }

  /// Ensure today's feed is loaded
  Future<void> _initFeed() async {
    if (!r.shouldLoadFeedToday) return log("[home] Feed is up to date");
    if (!await isOnline()) {
      log("[home] No internet connection, skipping feed load");
      return;
    }
    log("[home] Feed needs reloading");
    await _loadFeed();
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
                onTopicChanged: _loadFeed,
              ),
              FeedSwiper(
                feedType: _feedType,
                onReload: _loadFeed,
                onSeeLatest: _seeLatestFeed,
                onBackToDigest: () async {
                  // TODO: scroll topic tabs to position 0
                  await prefs.remove('topic');
                  setState(() {});
                  _initFeed();
                },
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
