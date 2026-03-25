import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';

typedef FeedNotInterestedState = BaseFeedState;

final feedNotInterestedProvider = NotifierProvider<FeedNotInterestedNotifier, FeedNotInterestedState>(FeedNotInterestedNotifier.new);

class FeedNotInterestedNotifier extends BaseFeedNotifier {
  @override
  String get endpoint => 'feed/not_interested';

  Future<bool> load({int? limit, bool forceRefresh = false, String? requestId}) async {
    // Don't add limit to queryParams to maintain cache key consistency
    // The limit is handled internally by loadFromEndpoint
    return await loadFromEndpoint(endpoint, queryParams: null, forceRefresh: forceRefresh, requestId: requestId);
  }

  /// Prepend a feed item to the top of the not interested list
  Future<void> prependItem(FeedItem item) async {
    final currentItems = state.items ?? [];
    final updatedItems = [item, ...currentItems.where((existing) => existing.id != item.id)];
    await setValue(updatedItems);
  }

  /// Remove a feed item from the not interested list
  Future<void> removeItem(String feedId) async {
    final currentItems = state.items ?? [];
    final updatedItems = currentItems.where((item) => item.id != feedId).toList();
    await setValue(updatedItems);
  }
}
