import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/topic.dart';

typedef FeedLatestState = BaseFeedState;

final feedLatestProvider = NotifierProvider<FeedLatestNotifier, FeedLatestState>(FeedLatestNotifier.new);

class FeedLatestNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/latest';

  Future<bool> load({String? topic, int? limit, bool forceRefresh = false, String? requestId}) async {
    final topicValue = topic ?? ref.read(topicProvider);
    
    // Don't add limit to queryParams to maintain cache key consistency
    // The limit is handled internally by loadFromEndpoint
    // Only add topic if it's not null to ensure consistent cache keys
    final queryParams = topicValue != null ? {'topic': topicValue} : null;
    
    return await loadFromEndpoint(endpoint, queryParams: queryParams, forceRefresh: forceRefresh, requestId: requestId);
  }
}