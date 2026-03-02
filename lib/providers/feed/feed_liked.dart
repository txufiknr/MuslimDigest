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
}
