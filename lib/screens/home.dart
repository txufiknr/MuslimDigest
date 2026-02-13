import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/time.dart';
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

  @override
  void initState() {
    super.initState();
    _initFeed();
  }

  /// Load feeds and reset read count for new day
  Future<void> _initFeed() async {
    final isNewDay = !isSameDay(today, readLastDate);
    if (isNewDay) {
      await Future.wait([
        prefs.setInt('read_count', 0),
        prefs.setString('read_last_date', today.toIso8601String()),
      ]);
    }
  }

  void _onTopicChanged(String? topic) {
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
            FeedSwiper(topic: _currentTopic).expand(),
            ReadingStreakFooter(),
          ],
        ),
      ),
    );
  }
}
