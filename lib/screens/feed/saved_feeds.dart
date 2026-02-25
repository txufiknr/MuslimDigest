import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
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

  @override
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider => feedSavedProvider;
}
