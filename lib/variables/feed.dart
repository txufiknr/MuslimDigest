import 'dart:convert';

import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/variables/app.dart';

List<FeedItem> get feedItems {
  final jsonString = prefs.getString('feed_items');
  if (jsonString == null) return [];
  try {
    return List<FeedItem>.from(jsonDecode(jsonString).map(FeedItem.fromJson));
  } catch (_) {
    return [];
  }
}