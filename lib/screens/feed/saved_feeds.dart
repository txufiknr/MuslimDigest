import 'package:flutter/cupertino.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';

class SavedFeedsPage extends FeedListBasePage {
  const SavedFeedsPage({super.key})
      : super(
          title: 'Saved Feeds',
          endpoint: 'feed/saved',
          actionIcon: CupertinoIcons.bookmark_fill,
          actionTooltip: 'Unsave',
          placeholderIcon: CupertinoIcons.bookmark,
          placeholderTooltip: "Let's save some feeds before they disappear",
        );
}
