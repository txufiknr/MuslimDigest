import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/topic.dart';

typedef FeedLatestState = BaseFeedState;

final feedLatestProvider = NotifierProvider<FeedLatestNotifier, FeedLatestState>(FeedLatestNotifier.new);

class FeedLatestNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/latest';

  Future<bool> load({String? topic, int? limit}) async {
    final topicValue = topic ?? ref.read(topicProvider);
    return await loadFromEndpoint(
      endpoint,
      queryParams: {
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
        'topic': ?topicValue,
      },
    );
  }
  
  @override
  Future<bool> loadMore({String? topic, int? limit}) async {
    if (!state.hasMore || state.isLoadingMore || state.items == null || state.items!.isEmpty) {
      return false;
    }
    
    // Generate cursor from the last item
    final lastItem = state.items!.last;
    final cursor = generateCursor(lastItem);
    
    if (cursor == null) return false;
    final topicValue = topic ?? ref.read(topicProvider);
    
    // * GET feed/latest?cursor=2023-01-01T12:00:00Z|cluster-123&limit=5
    return await loadFromEndpoint(
      endpoint,
      queryParams: {
        'cursor': cursor,
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
        'topic': ?topicValue,
      },
      isLoadMore: true,
    );
  }
}