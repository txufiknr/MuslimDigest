import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/topic.dart';

typedef FeedLatestState = BaseFeedState;

final feedLatestProvider = NotifierProvider<FeedLatestNotifier, FeedLatestState>(FeedLatestNotifier.new);

class FeedLatestNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/latest';

  Future<bool> load({String? topic, int? limit, bool forceRefresh = false}) async {
    final topicValue = topic ?? ref.read(topicProvider);
    
    // Build query parameters, excluding null values for consistent cache keys
    final queryParams = <String, String>{
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    };
    
    // Only add topic if it's not null to ensure consistent cache keys
    if (topicValue != null) {
      queryParams['topic'] = topicValue;
    }
    
    return await loadFromEndpoint(endpoint, queryParams: queryParams, forceRefresh: forceRefresh);
  }
}