import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedLikedState = BaseFeedState;

final feedLikedProvider = NotifierProvider<FeedLikedNotifier, FeedLikedState>(FeedLikedNotifier.new);

class FeedLikedNotifier extends BaseFeedNotifier {
  @override
  String get cacheKey => 'feed/liked';

  Future<bool> load() async {
    return await loadFromEndpoint('feed/liked');
  }
}
