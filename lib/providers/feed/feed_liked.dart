import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedLikedState = BaseFeedState;

final feedLikedProvider = NotifierProvider<FeedLikedNotifier, FeedLikedState>(FeedLikedNotifier.new);

class FeedLikedNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/liked';

  Future<bool> load({int? limit}) async {
    return await loadFromEndpoint(endpoint, queryParams: {
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    });
  }
  
  @override
  Future<bool> loadMore({int? limit}) async {
    if (!state.hasMore || state.isLoadingMore || state.items == null || state.items!.isEmpty) {
      return false;
    }
    
    // Generate cursor from the last item
    final lastItem = state.items!.last;
    final cursor = generateCursor(lastItem);
    
    if (cursor == null) return false;
    
    return await loadFromEndpoint(
      endpoint,
      queryParams: {
        'cursor': cursor,
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
      },
      isLoadMore: true,
    );
  }
}
