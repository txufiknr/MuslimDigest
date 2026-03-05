import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';
import 'package:muslimdigest/variables/feed.dart';

class FeedNotInterestedPage extends FeedListBasePage {
  const FeedNotInterestedPage({super.key})
      : super(
          title: 'Hidden Feeds',
          actionIcon: CupertinoIcons.trash,
          actionTooltip: 'Remove from hidden',
          placeholderIcon: CupertinoIcons.hand_thumbsdown,
          placeholderTooltip: 'Feeds you mark as not interested will appear here',
          feedType: FeedType.notInterested,
          useScaffold: false,
        );

  @override
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider => feedNotInterestedProvider;
}
