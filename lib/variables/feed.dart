// import 'dart:convert';

// import 'package:muslimdigest/models/feed.dart';
// import 'package:muslimdigest/variables/app.dart';

// String? get currentTopic => prefs.getString('topic');

/// Gets feed items from local storage.
// List<FeedItem> _getFeedItems(String storageKey) {
//   final jsonString = prefs.getString(storageKey);
//   if (jsonString == null) return [];
//   return List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
// }

// List<FeedItem> get feedDigest => _getFeedItems('feed');

// List<FeedItem> get feedLatest => _getFeedItems('feed/latest');

// List<FeedItem> get feedTrending => _getFeedItems('feed/trending');