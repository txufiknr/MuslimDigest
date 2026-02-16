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
  
  List<FeedItem> getItems(WidgetRef ref) {
    switch (this) {
      case FeedType.digest: return ref.read(feedProvider).items ?? [];
      case FeedType.latest: return ref.read(feedLatestProvider).items ?? [];
      case FeedType.trending: return ref.read(feedTrendingProvider).items ?? [];
      case FeedType.liked: return ref.read(feedLikedProvider).items ?? [];
      case FeedType.saved: return ref.read(feedSavedProvider).items ?? [];
    }
  }

  FeedItem? getItem(WidgetRef ref, String feedId) {
    return getItems(ref).firstWhereOrNull((item) => item.id == feedId);
  }
  
  bool isLoading(WidgetRef ref) {
    switch (this) {
      case FeedType.digest: return ref.read(feedProvider).isLoading;
      case FeedType.latest: return ref.read(feedLatestProvider).isLoading;
      case FeedType.trending: return ref.read(feedTrendingProvider).isLoading;
      case FeedType.liked: return ref.read(feedLikedProvider).isLoading;
      case FeedType.saved: return ref.read(feedSavedProvider).isLoading;
    }
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
  BaseFeedState watchState(WidgetRef ref) {
    switch (this) {
      case FeedType.digest: return ref.watch(feedProvider);
      case FeedType.latest: return ref.watch(feedLatestProvider);
      case FeedType.trending: return ref.watch(feedTrendingProvider);
      case FeedType.liked: return ref.watch(feedLikedProvider);
      case FeedType.saved: return ref.watch(feedSavedProvider);
    }
  }
}