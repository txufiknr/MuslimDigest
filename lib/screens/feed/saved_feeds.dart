import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/screens/feed/feed_list_base.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'dart:developer' show log;

class SavedFeedsPage extends FeedListBasePage {
  final String? collection;
  
  const SavedFeedsPage({super.key, this.collection})
      : super(
          title: collection ?? 'Saved Feeds',
          feedType: FeedType.saved,
          actionIcon: CupertinoIcons.bookmark_fill,
          actionTooltip: 'Unsave',
          placeholderIcon: CupertinoIcons.bookmark,
          placeholderTooltip: collection != null 
            ? 'No feeds in "$collection"' 
            : "Let's save some feeds before they disappear",
        );

  @override
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider => feedSavedProvider;
  
  @override
  Map<String, String>? get queryParams {
    final params = collection != null ? {'collection': collection!} : null;
    log('[SavedFeedsPage] QueryParams: $params for collection: $collection');
    return params;
  }
}
