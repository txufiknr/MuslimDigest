import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedTrendingState = BaseFeedState;

final feedTrendingProvider = NotifierProvider<FeedTrendingNotifier, FeedTrendingState>(FeedTrendingNotifier.new);

class FeedTrendingNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/trending';

  Future<bool> load({int? limit, bool forceRefresh = false, String? requestId}) async {
    // Don't add limit to queryParams to maintain cache key consistency
    // The limit is handled internally by loadFromEndpoint
    return await loadFromEndpoint(endpoint, queryParams: null, forceRefresh: forceRefresh, requestId: requestId);
  }
}
