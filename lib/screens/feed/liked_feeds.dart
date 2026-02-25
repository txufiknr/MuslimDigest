import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_liked.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';
import 'package:muslimdigest/variables/feed.dart';

class LikedFeedsPage extends FeedListBasePage {
  const LikedFeedsPage({super.key})
      : super(
          title: 'Liked Feeds',
          feedType: FeedType.liked,
          actionIcon: CupertinoIcons.heart_fill,
          actionTooltip: 'Unlike',
          placeholderIcon: CupertinoIcons.heart,
          placeholderTooltip: "Your favorite feeds will appear here",
        );

  @override
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider => feedLikedProvider;
}
