import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show DAILY_READ_TARGET;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/services/api.dart';

typedef FeedState = BaseFeedState;

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends BaseFeedNotifier {
  @override
  String get cacheKey => 'feed';

  Future<bool> load({String? topic, int? timeoutMs}) async {
    final options = timeoutMs == null ? null : ApiOptions(timeout: Duration(milliseconds: timeoutMs));
    final topicValue = topic ?? ref.read(topicProvider);
    // final topicValue = topic ?? PrefData.currentTopic;
    
    final queryParams = <String, String>{
      'limit': DAILY_READ_TARGET.toString(),
    };
    if (topicValue != null) {
      queryParams['topic'] = topicValue;
    }
    
    return await loadFromEndpoint(
      'feed',
      queryParams: queryParams,
      options: options,
    );
  }
}