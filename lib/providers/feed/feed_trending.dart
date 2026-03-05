import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedTrendingState = BaseFeedState;

final feedTrendingProvider = NotifierProvider<FeedTrendingNotifier, FeedTrendingState>(FeedTrendingNotifier.new);

class FeedTrendingNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/trending';

  Future<bool> load({int? limit, bool forceRefresh = false, String? requestId}) async {
    return await loadFromEndpoint(endpoint, queryParams: {
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    }, forceRefresh: forceRefresh, requestId: requestId);
  }
}
