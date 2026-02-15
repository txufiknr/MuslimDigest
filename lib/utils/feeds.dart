import 'dart:convert';
import 'dart:developer' show log;

import 'package:muslimdigest/config/feeds.dart' show DAILY_READ_TARGET, CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';

/// Loads feed items from the API and caches them locally.
Future<bool> _loadFeedItems(String endpoint, {
  Map<String, String>? queryParams,
  ApiOptions? options,
}) async {
  final response = await ApiService.get(endpoint, queryParams: queryParams, options: options);

  if (response.successful) {
    final feedItems = List<FeedItem>.from(response.data.map((item) => FeedItem.fromJson(item as Map<String, dynamic>)));
    log('[_loadFeedItems] ${feedItems.length} feed items obtained successfully');

    // Cache feed items locally
    await _setFeedItems(feedItems, endpoint);
    return true;
  }

  log('[_loadFeedItems] Failed to fetch feed items: ${response.error}');
  return false;
}

Future<bool> loadFeeds({String? topic, int? timeoutMs}) async {
  final options = timeoutMs == null ? null : ApiOptions(timeout: Duration(milliseconds: timeoutMs));
  return _loadFeedItems(
    'feed',
    queryParams: {
      'topic': ?(topic ?? currentTopic),
      'limit': DAILY_READ_TARGET.toString(),
    },
    options: options,
  );
}

Future<bool> loadTrendingFeeds({int? limit}) async {
  return _loadFeedItems(
    'feed/trending',
    queryParams: {
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    },
  );
}

Future<bool> loadLatestFeeds({int? limit}) async {
  return _loadFeedItems(
    'feed/latest',
    queryParams: {
      'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
    },
  );
}

Future<void> _setFeedItems(List<FeedItem> feedItems, String storageKey) async {
  final feedItemsString = jsonEncode(feedItems.map((item) => item.toJson()).toList());
  await prefs.setString(storageKey, feedItemsString);
  log('[_setFeedItems] ${feedItems.length} ${storageKey.unslug()} stored successfully!');
}