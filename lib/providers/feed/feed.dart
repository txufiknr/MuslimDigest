import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show DAILY_READ_TARGET;
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/services/api.dart';

typedef FeedState = BaseFeedState;

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed';

  Future<bool> load({int? timeoutMs, bool forceRefresh = false}) async {
    final options = timeoutMs == null ? null : ApiOptions(timeout: Duration(milliseconds: timeoutMs));
    
    final queryParams = <String, String>{
      'limit': DAILY_READ_TARGET.toString(),
    };
    
    return await loadFromEndpoint(
      endpoint,
      queryParams: queryParams,
      options: options,
      forceRefresh: forceRefresh,
    );
  }
}