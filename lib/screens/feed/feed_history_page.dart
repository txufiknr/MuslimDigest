import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_history.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';
import 'package:muslimdigest/variables/feed.dart';

class FeedHistoryPage extends FeedListBasePage {
  const FeedHistoryPage({super.key})
      : super(
          title: 'History',
          actionIcon: CupertinoIcons.trash,
          actionTooltip: 'Remove from history',
          placeholderIcon: CupertinoIcons.clock,
          placeholderTooltip: 'Your reading history will appear here',
          feedType: FeedType.history,
        );

  @override
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider => feedHistoryProvider;
}
