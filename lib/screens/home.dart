import 'package:flutter/material.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/mock/feeds.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/feeds.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/variables/user.dart';
import '../variables/app.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/feed_swiper.dart';
import '../widgets/home/reading_streak_footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _currentTopic;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initFeed();
  }

  /// Load feeds and reset read count for new day
  Future<void> _initFeed() async {
    final isNewDay = !isSameDay(today, readLastDate);
    await Future.wait([
      _loadFeed(),
      if (isNewDay) prefs.setInt('read_count', 0),
      if (isNewDay) prefs.setString('read_last_date', today.toIso8601String()),
    ]);
  }

  /// Load feeds from API
  Future<void> _loadFeed() async {
    final response = await ApiService.get('feed');

    if (response.success && response.data != null) {
      final feedItems = List<FeedItem>.from(response.data.map(FeedItem.fromJson));
      debugPrint('[_loadFeed] ${feedItems.length} feed items obtained successfully');

      // Cache feed items locally
      await setFeedItems(feedItems);

    } else {
      debugPrint('[_loadFeed] Failed to fetch feed items: ${response.error}');
      if (!mounted) return;
      final shouldRetry = await showRetryableError(
        context,
        message: 'Failed to load feed. Would you like to retry?',
        footer: 'You can always pull to refresh to reload your feed.',
      );
      if (shouldRetry) {
        await _loadFeed();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _incrementReadCount(String lastClusterId) async {
    // Increment count
    final newCount = (readCount + 1).clamp(0, DAILY_READ_TARGET);
    await prefs.setInt('read_count', newCount);
    await prefs.setString('read_last_date', today.toIso8601String());
    setState(() {});
    
    // Track reading progress to backend for analytics and user engagement
    try {
      final responses = await Future.wait([
        ApiService.post('streaks/increment', {}),
        ApiService.post('history', {'clusterId': lastClusterId}),
      ]);
      await handleStreaksResponse(responses[0]);
      setState(() {});
    } catch (e) {
      // Ignore errors for history tracking - not critical
      debugPrint('Failed to track reading history: $e');
    }
  }

  void _decreaseReadCount() {
    if (readCount > 0) {
      prefs.setInt('read_count', readCount - 1);
      setState(() {});
    }
  }

  void _onTopicChanged(String topic) {
    setState(() => _currentTopic = topic);
    // TODO: reload feeds based on the selected topic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              onTopicChanged: _onTopicChanged,
              currentTopic: _currentTopic,
            ),
            Expanded(
              child: FeedSwiper(
                feedItems: mockFeedItems,
                onSwipeUp: _incrementReadCount,
                onSwipeDown: _decreaseReadCount,
              ),
            ),
            ReadingStreakFooter(),
          ],
        ),
      ),
    );
  }
}
