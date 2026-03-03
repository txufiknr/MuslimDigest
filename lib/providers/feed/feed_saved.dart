import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedSavedState = BaseFeedState;

final feedSavedProvider = NotifierProvider<FeedSavedNotifier, FeedSavedState>(FeedSavedNotifier.new);

class FeedSavedNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/saved';

  Future<bool> load({int? limit, bool forceRefresh = false}) async {
    return await loadFromEndpoint(endpoint, queryParams: {
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    }, forceRefresh: forceRefresh);
  }
}
