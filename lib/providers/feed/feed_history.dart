import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedHistoryState = BaseFeedState;

final feedHistoryProvider = NotifierProvider<FeedHistoryNotifier, FeedHistoryState>(FeedHistoryNotifier.new);

class FeedHistoryNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/history';

  Future<bool> load({int? limit}) async {
    return await loadFromEndpoint(endpoint, queryParams: {
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    });
  }
}
