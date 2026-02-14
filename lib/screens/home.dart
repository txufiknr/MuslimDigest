import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/feeds.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/variables/user.dart';
import '../variables/app.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/feed_swiper.dart';
import '../widgets/home/reading_streak_footer.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> args;
  const HomePage({this.args = const {}, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // late final _isFeedLoaded = widget.args['feedLoaded'] as bool? ?? true;
  // late var _isLoading = !_isFeedLoaded;
  var _isLoading = false;
  var _isWillExit = false;

  @override
  void initState() {
    super.initState();
    final isFeedLoaded = widget.args['feedLoaded'] as bool? ?? true;
    if (!isFeedLoaded) {
      _showLoadFeedFailed(_loadFeeds);
    }
    _initReadCount();
  }

  /// Reset read count for new day
  void _initReadCount() {
    final isNewDay = !isSameDay(today, readLastDate);
    if (isNewDay) {
      prefs.setInt('read_count', 0);
      prefs.setString('read_last_date', today.toIso8601String());
    }
  }

  Future<void> _loadFeeds([String? topic]) async {
    setState(() { _isLoading = true; });
    final loadFeedsSuccess = await loadFeeds(topic: topic);
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (!loadFeedsSuccess) {
      return _showLoadFeedFailed(() => _loadFeeds(topic));
    }
  }

  Future<void> _showLoadFeedFailed(Future<void> Function() onRetry) async {
    final shouldRetry = await showRetryableError(
      context,
      title: 'Failed to fetch feed items.',
      message: 'Failed to load your feed. Would you like to retry?',
      footer: 'You can always pull to refresh to reload your feed.',
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
    final h = MyHelper(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isWillExit) {
          // Save all user data before exit
          unawaited(saveAllData());
          _isWillExit = true;
          h.showSnackBar('Press back again to exit');
          delay(2000, () {
            _isWillExit = false;
            h.hideSnackBar();
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
                onTopicChanged: _loadFeeds,
              ),
              FeedSwiper(isLoading: _isLoading).expand(),
              ReadingStreakFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
