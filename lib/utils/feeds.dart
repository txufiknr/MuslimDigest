import 'dart:convert';

import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/variables/app.dart';

Future<void> setFeedItems(List<FeedItem> feedItems) async {
  await prefs.setString('feed_items', jsonEncode(feedItems.map((item) => item.toJson()).toList()));
}