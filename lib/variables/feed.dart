import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed/feed_history.dart';
import 'package:muslimdigest/providers/feed/feed_liked.dart';
import 'package:muslimdigest/providers/feed/feed_latest.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/providers/feed/feed_trending.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/utils/extensions.dart';

enum FeedbackCategory {
  suggestion,
  inappropriate_content,
  fake_news,
  bug_report,
  other;

  static FeedbackCategory? fromString(String? value) {
    if (value == null) return null;
    return FeedbackCategory.values.firstWhereOrNull((e) => e.name == value);
  }

  String get label {
    return name.unslugTitleCase();
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

  Color get color {
    switch (this) {
      case FeedbackCategory.suggestion:
        return AppColors.mutedLight;
      case FeedbackCategory.inappropriate_content:
        return AppColors.error;
      case FeedbackCategory.fake_news:
        return AppColors.error;
      case FeedbackCategory.bug_report:
        return AppColors.warning;
      case FeedbackCategory.other:
        return AppColors.mutedLight;
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
  liked,
  history,
  notInterested;

  static FeedType fromString(String name) {
    return values.firstWhere(
      (type) => type.name == name,
      orElse: () => digest,
    );
  }

  static FeedType fromEndpoint(String endpoint) {
    return values.firstWhere(
      (type) => type.endpoint == endpoint,
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
      case notInterested: return 'feed/not_interested';
      default: return 'feed/$name';
    }
  }

  IconData get icon {
    switch (this) {
      case latest: return CupertinoIcons.antenna_radiowaves_left_right;
      case trending: return CupertinoIcons.bubble_left_bubble_right;
      case history: return CupertinoIcons.clock;
      case notInterested: return CupertinoIcons.hand_thumbsdown;
      default: return CupertinoIcons.square_on_square;
    }
  }

  BaseFeedNotifier getNotifier(WidgetRef ref) {
    switch (this) {
      case trending: return ref.read(feedTrendingProvider.notifier);
      case latest: return ref.read(feedLatestProvider.notifier);
      case liked: return ref.read(feedLikedProvider.notifier);
      case saved: return ref.read(feedSavedProvider.notifier);
      case history: return ref.read(feedHistoryProvider.notifier);
      case digest: return ref.read(feedProvider.notifier);
      case notInterested: return ref.read(feedNotInterestedProvider.notifier);
    }
  }

  BaseFeedNotifier getNotifierWithRef(Ref ref) {
    switch (this) {
      case trending: return ref.read(feedTrendingProvider.notifier);
      case latest: return ref.read(feedLatestProvider.notifier);
      case liked: return ref.read(feedLikedProvider.notifier);
      case saved: return ref.read(feedSavedProvider.notifier);
      case history: return ref.read(feedHistoryProvider.notifier);
      case digest: return ref.read(feedProvider.notifier);
      case notInterested: return ref.read(feedNotInterestedProvider.notifier);
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

  Future<bool> load(WidgetRef ref, {String? topic, int? timeoutMs, int? limit, bool forceRefresh = false}) {
    switch (this) {
      case digest: return ref.read(feedProvider.notifier).load(timeoutMs: timeoutMs, forceRefresh: forceRefresh);
      case latest: return ref.read(feedLatestProvider.notifier).load(topic: topic, limit: limit, forceRefresh: forceRefresh);
      case trending: return ref.read(feedTrendingProvider.notifier).load(limit: limit, forceRefresh: forceRefresh);
      case liked: return ref.read(feedLikedProvider.notifier).load(limit: limit, forceRefresh: forceRefresh);
      case saved: return ref.read(feedSavedProvider.notifier).load(limit: limit, forceRefresh: forceRefresh);
      case history: return ref.read(feedHistoryProvider.notifier).load(limit: limit, forceRefresh: forceRefresh);
      case notInterested: return ref.read(feedNotInterestedProvider.notifier).load(limit: limit, forceRefresh: forceRefresh);
    }
  }

  Future<bool> loadWithRef(Ref ref, {String? topic, int? timeoutMs, int? limit, bool force = false, String? requestId}) {
    switch (this) {
      case digest: return ref.read(feedProvider.notifier).load(timeoutMs: timeoutMs, forceRefresh: force, requestId: requestId);
      case latest: return ref.read(feedLatestProvider.notifier).load(topic: topic, limit: limit, forceRefresh: force, requestId: requestId);
      case trending: return ref.read(feedTrendingProvider.notifier).load(limit: limit, forceRefresh: force, requestId: requestId);
      case liked: return ref.read(feedLikedProvider.notifier).load(limit: limit, forceRefresh: force, requestId: requestId);
      case saved: return ref.read(feedSavedProvider.notifier).load(limit: limit, forceRefresh: force, requestId: requestId);
      case history: return ref.read(feedHistoryProvider.notifier).load(limit: limit, forceRefresh: force, requestId: requestId);
      case notInterested: return ref.read(feedNotInterestedProvider.notifier).load(limit: limit, forceRefresh: force, requestId: requestId);
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
      case history: return ref.watch(feedHistoryProvider);
      case notInterested: return ref.watch(feedNotInterestedProvider);
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
      case history: return ref.read(feedHistoryProvider);
      case notInterested: return ref.read(feedNotInterestedProvider);
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
      case history: return ref.read(feedHistoryProvider);
      case notInterested: return ref.read(feedNotInterestedProvider);
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