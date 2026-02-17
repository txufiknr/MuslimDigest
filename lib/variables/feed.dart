import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed.dart';
import 'package:muslimdigest/providers/feed_liked.dart';
import 'package:muslimdigest/providers/feed_latest.dart';
import 'package:muslimdigest/providers/feed_saved.dart';
import 'package:muslimdigest/providers/feed_trending.dart';
import 'package:muslimdigest/utils/extensions.dart';

enum FeedType {
  digest,
  trending,
  latest,
  saved,
  liked;

  BaseFeedNotifier getNotifier(WidgetRef ref) {
    switch (this) {
      case FeedType.trending: return ref.read(feedTrendingProvider.notifier);
      case FeedType.latest: return ref.read(feedLatestProvider.notifier);
      case FeedType.liked: return ref.read(feedLikedProvider.notifier);
      case FeedType.saved: return ref.read(feedSavedProvider.notifier);
      case FeedType.digest: return ref.read(feedProvider.notifier);
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
      case FeedType.digest: return ref.read(feedProvider.notifier).load(topic: topic, timeoutMs: timeoutMs);
      case FeedType.latest: return ref.read(feedLatestProvider.notifier).load(limit: limit);
      case FeedType.trending: return ref.read(feedTrendingProvider.notifier).load(limit: limit);
      case FeedType.liked: return ref.read(feedLikedProvider.notifier).load();
      case FeedType.saved: return ref.read(feedSavedProvider.notifier).load();
    }
  }

  /// Watch the provider state for real-time updates
  BaseFeedState watch(WidgetRef ref) {
    switch (this) {
      case FeedType.digest: return ref.watch(feedProvider);
      case FeedType.latest: return ref.watch(feedLatestProvider);
      case FeedType.trending: return ref.watch(feedTrendingProvider);
      case FeedType.liked: return ref.watch(feedLikedProvider);
      case FeedType.saved: return ref.watch(feedSavedProvider);
    }
  }

  /// Read the provider state
  BaseFeedState read(WidgetRef ref) {
    switch (this) {
      case FeedType.digest: return ref.read(feedProvider);
      case FeedType.latest: return ref.read(feedLatestProvider);
      case FeedType.trending: return ref.read(feedTrendingProvider);
      case FeedType.liked: return ref.read(feedLikedProvider);
      case FeedType.saved: return ref.read(feedSavedProvider);
    }
  }
}