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
}