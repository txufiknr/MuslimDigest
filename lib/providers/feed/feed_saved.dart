import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedSavedState = BaseFeedState;

final feedSavedProvider = NotifierProvider<FeedSavedNotifier, FeedSavedState>(FeedSavedNotifier.new);

class FeedSavedNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/saved';

  Future<bool> load({int? limit, bool forceRefresh = false, String? requestId, Map<String, String>? queryParams}) async {
    // Don't add limit to queryParams to maintain cache key consistency
    // The limit is handled internally by loadFromEndpoint
    return await loadFromEndpoint(endpoint, queryParams: queryParams, forceRefresh: forceRefresh, requestId: requestId);
  }
}
