import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedTrendingState = BaseFeedState;

final feedTrendingProvider = NotifierProvider<FeedTrendingNotifier, FeedTrendingState>(FeedTrendingNotifier.new);

class FeedTrendingNotifier extends BaseFeedNotifier {
  @override
  String get cacheKey => 'feed/trending';

  Future<bool> load({int? limit}) async {
    return await loadFromEndpoint(
      'feed/trending',
      queryParams: {
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
      },
    );
  }
}