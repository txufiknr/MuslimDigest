import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedLikedState = BaseFeedState;

final feedLikedProvider = NotifierProvider<FeedLikedNotifier, FeedLikedState>(FeedLikedNotifier.new);

class FeedLikedNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/liked';

  Future<bool> load({int? limit, bool forceRefresh = false, String? requestId}) async {
    // Don't add limit to queryParams to maintain cache key consistency
    // The limit is handled internally by loadFromEndpoint
    return await loadFromEndpoint(endpoint, queryParams: null, forceRefresh: forceRefresh, requestId: requestId);
  }
}
