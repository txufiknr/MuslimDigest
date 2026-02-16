import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/base_feed_notifier.dart';

typedef FeedLatestState = BaseFeedState;

final feedLatestProvider = NotifierProvider<FeedLatestNotifier, FeedLatestState>(FeedLatestNotifier.new);

class FeedLatestNotifier extends BaseFeedNotifier {
  @override
  String get cacheKey => 'feed/latest';

  Future<bool> load({int? limit}) async {
    return await loadFromEndpoint(
      'feed/latest',
      queryParams: {
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
      },
    );
  }
}