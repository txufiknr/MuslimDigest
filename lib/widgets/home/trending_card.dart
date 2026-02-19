import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/widgets/components/card.dart';
import 'package:muslimdigest/widgets/components/logo.dart';

class TrendingFeedsCard extends ConsumerStatefulWidget {
  const TrendingFeedsCard({super.key});

  @override
  ConsumerState<TrendingFeedsCard> createState() => _TrendingFeedsCardState();
}

class _TrendingFeedsCardState extends ConsumerState<TrendingFeedsCard> {
  final _pageController = PageController();
  Timer? _timer;

  List<FeedItem> get _feedItems => FeedType.trending.watchItems(ref);

  void _read(FeedItem feed) {
    // TODO: Open feed
  }

  void _next() {
    _pageController.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(Duration(seconds: 4), (_) => _next());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_feedItems.isEmpty) return Splash();

    final h = MyHelper(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final height = maxWidth * 500 / 1024;
        return SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final feedItem = _feedItems[index % _feedItems.length];
              return MyCard(
                onTap: () => _read(feedItem),
                child: ListView(
                  children: [
                    Text(feedItem.title, textAlign: TextAlign.center, style: h.currentTextTheme.titleSmall,),
                    SizedBox(height: 6,),
                    Text(feedItem.summary, textAlign: TextAlign.center, style: h.currentTextTheme.bodySmall,),
                  ],
                )
              );
            },
          ),
        );
      }
    );
  }
}