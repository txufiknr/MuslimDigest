import 'dart:convert';
import 'dart:developer' show log;

import 'package:muslimdigest/config/feeds.dart' show DAILY_READ_TARGET;
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';

Future<bool> loadFeeds({String? topic, int? timeoutMs}) async {
  final options = timeoutMs == null ? null : ApiOptions(timeout:  Duration(milliseconds: timeoutMs));
  final response = await ApiService.get('feed', queryParams: <String, String>{
    'topic': ?(topic ?? currentTopic),
    'limit': DAILY_READ_TARGET.toString(),
  }, options: options);

  if (response.success && response.data != null) {
    final feedItems = List<FeedItem>.from(response.data.map((item) => FeedItem.fromJson(item as Map<String, dynamic>)));
    log('[loadFeeds] ${feedItems.length} feed items obtained successfully');

    // Cache feed items locally
    await setFeedItems(feedItems);
    return true;
  }

  log('[loadFeeds] Failed to fetch feed items: ${response.error}');
  return false;
}

Future<void> setFeedItems(List<FeedItem> feedItems) async {
  final feedItemsString = jsonEncode(feedItems.map((item) => item.toJson()).toList());
  await prefs.setString('feed_items', feedItemsString);
  log('[setFeedItems] ${feedItems.length} feed items stored successfully!');
}