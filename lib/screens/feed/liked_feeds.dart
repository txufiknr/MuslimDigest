import 'package:flutter/cupertino.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';

class LikedFeedsPage extends FeedListBasePage {
  const LikedFeedsPage({super.key})
      : super(
          title: 'Liked Feeds',
          endpoint: 'feed/liked',
          actionIcon: CupertinoIcons.heart_fill,
          actionTooltip: 'Unlike',
          placeholderIcon: CupertinoIcons.heart,
          placeholderTooltip: "Your favorite feeds will appear here",
        );
}
