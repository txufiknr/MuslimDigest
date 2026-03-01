import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed/feed_liked.dart';
import 'package:muslimdigest/providers/feed/feed_latest.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/providers/feed/feed_trending.dart';
import 'package:muslimdigest/utils/extensions.dart';

enum FeedbackCategory {
  suggestion,
  inappropriate_content,
  fake_news,
  bug_report,
  other;

  String get label {
    return name.unslug().toCapitalized();
  }

  IconData get icon {
    switch (this) {
      case suggestion: return CupertinoIcons.lightbulb;
      case inappropriate_content: return CupertinoIcons.exclamationmark_triangle;
      case fake_news: return CupertinoIcons.exclamationmark_shield;
      case bug_report: return CupertinoIcons.bandage;
      case other: return CupertinoIcons.question_circle;
    }
  }

  bool get shouldHideFeed {
    return [inappropriate_content, fake_news, bug_report].contains(this);
  }
}

enum FeedType {
  digest,
  trending,
  latest,
  saved,
  liked;

  static FeedType fromString(String name) {
    return FeedType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => digest,
    );
  }

  bool get isHomeFeed => [digest, latest].contains(this);

  String get label {
    switch (this) {
      case digest: return 'My Digest';
      case latest: return 'My Feed';
      default: return name.toCapitalized();
    }
  }

  String get endpoint {
    switch (this) {
      case digest: return 'feed';
      default: return 'feed/$name';
    }
  }

  IconData get icon {
    switch (this) {
      case latest: return CupertinoIcons.antenna_radiowaves_left_right;
      case trending: return CupertinoIcons.bubble_left_bubble_right;
      default: return CupertinoIcons.square_on_square;
    }
  }

  BaseFeedNotifier getNotifier(WidgetRef ref) {
    switch (this) {
      case trending: return ref.read(feedTrendingProvider.notifier);
      case latest: return ref.read(feedLatestProvider.notifier);
      case liked: return ref.read(feedLikedProvider.notifier);
      case saved: return ref.read(feedSavedProvider.notifier);
      case digest: return ref.read(feedProvider.notifier);
    }
  }

  BaseFeedNotifier getNotifierWithRef(Ref ref) {
    switch (this) {
      case trending: return ref.read(feedTrendingProvider.notifier);
      case latest: return ref.read(feedLatestProvider.notifier);
      case liked: return ref.read(feedLikedProvider.notifier);
      case saved: return ref.read(feedSavedProvider.notifier);
      case digest: return ref.read(feedProvider.notifier);
    }
  }
  
  List<FeedItem> readItems(WidgetRef ref) {
    return read(ref).items ?? [];
  }

  List<FeedItem> watchItems(WidgetRef ref) {
    return watch(ref).items ?? [];
  }

  FeedItem? readItem(WidgetRef ref, String feedId) {
    return readItems(ref).firstWhereOrNull((item) => item.id == feedId);
  }

  FeedItem? watchItem(WidgetRef ref, String feedId) {
    return watchItems(ref).firstWhereOrNull((item) => item.id == feedId);
  }

  Future<bool> load(WidgetRef ref, {String? topic, int? timeoutMs, int? limit}) {
    switch (this) {
      case digest: return ref.read(feedProvider.notifier).load(timeoutMs: timeoutMs);
      case latest: return ref.read(feedLatestProvider.notifier).load(topic: topic, limit: limit);
      case trending: return ref.read(feedTrendingProvider.notifier).load(limit: limit);
      case liked: return ref.read(feedLikedProvider.notifier).load(limit: limit);
      case saved: return ref.read(feedSavedProvider.notifier).load(limit: limit);
    }
  }

  Future<bool> loadWithRef(Ref ref, {String? topic, int? timeoutMs, int? limit}) {
    switch (this) {
      case digest: return ref.read(feedProvider.notifier).load(timeoutMs: timeoutMs);
      case latest: return ref.read(feedLatestProvider.notifier).load(topic: topic, limit: limit);
      case trending: return ref.read(feedTrendingProvider.notifier).load(limit: limit);
      case liked: return ref.read(feedLikedProvider.notifier).load(limit: limit);
      case saved: return ref.read(feedSavedProvider.notifier).load(limit: limit);
    }
  }

  /// Watch the provider state for real-time updates
  BaseFeedState watch(WidgetRef ref) {
    switch (this) {
      case digest: return ref.watch(feedProvider);
      case latest: return ref.watch(feedLatestProvider);
      case trending: return ref.watch(feedTrendingProvider);
      case liked: return ref.watch(feedLikedProvider);
      case saved: return ref.watch(feedSavedProvider);
    }
  }

  /// Read the provider state
  BaseFeedState read(WidgetRef ref) {
    switch (this) {
      case digest: return ref.read(feedProvider);
      case latest: return ref.read(feedLatestProvider);
      case trending: return ref.read(feedTrendingProvider);
      case liked: return ref.read(feedLikedProvider);
      case saved: return ref.read(feedSavedProvider);
    }
  }

  /// Read the provider state (Ref version)
  BaseFeedState readWithRef(Ref ref) {
    switch (this) {
      case digest: return ref.read(feedProvider);
      case latest: return ref.read(feedLatestProvider);
      case trending: return ref.read(feedTrendingProvider);
      case liked: return ref.read(feedLikedProvider);
      case saved: return ref.read(feedSavedProvider);
    }
  }
}

enum SwipeDirection {
  left, right;

  static const SwipeDirection defaultDirection = left;

  static SwipeDirection fromString(String name) {
    return values.firstWhere((e) => e.name == name);
  }
}