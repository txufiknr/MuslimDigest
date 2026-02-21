import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedSavedState = BaseFeedState;

final feedSavedProvider = NotifierProvider<FeedSavedNotifier, FeedSavedState>(FeedSavedNotifier.new);

class FeedSavedNotifier extends BaseFeedNotifier {
  @override
  String get cacheKey => 'feed/saved';

  Future<bool> load() async {
    return await loadFromEndpoint('feed/saved');
  }
}
