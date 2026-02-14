import 'dart:convert';

import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/variables/app.dart';

String? get currentTopic => prefs.getString('topic');

List<FeedItem> get feedItems {
  final jsonString = prefs.getString('feed_items');
  if (jsonString == null) return [];
  return List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
}