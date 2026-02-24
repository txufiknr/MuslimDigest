import 'package:flutter/cupertino.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';
import 'package:muslimdigest/variables/feed.dart';

class SavedFeedsPage extends FeedListBasePage {
  const SavedFeedsPage({super.key})
      : super(
          title: 'Saved Feeds',
          feedType: FeedType.saved,
          actionIcon: CupertinoIcons.bookmark_fill,
          actionTooltip: 'Unsave',
          placeholderIcon: CupertinoIcons.bookmark,
          placeholderTooltip: "Let's save some feeds before they disappear",
        );
}
