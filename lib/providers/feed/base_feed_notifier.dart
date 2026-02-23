import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;

class BaseFeedState {
  final List<FeedItem>? items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final String? nextCursor;

  bool get isEmpty => items?.isEmpty ?? true;
  bool get isGetting => isEmpty && isLoading;
  bool get isNone => isEmpty && !isLoading;
  bool get isLoadingMoreData => isLoadingMore;
  int get total => items?.length ?? 0;

  const BaseFeedState({
    this.items,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.nextCursor,
  });

  BaseFeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    String? nextCursor,
  }) {
    return BaseFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }

  /// Get a specific feed item by ID, returns null if not found
  FeedItem? getItem(String feedId) {
    return items?.firstWhereOrNull((item) => item.id == feedId);
  }
}

abstract class BaseFeedNotifier extends Notifier<BaseFeedState> {
  String get cacheKey;
  
  /// Generate cursor from feed item in format: publishedAt|id
  String? generateCursor(FeedItem? item) {
    if (item == null || item.publishedAt == null) return null;
    return '${item.publishedAt!.toIso8601String()}|${item.id}';
  }
  
  /// Load more items using cursor pagination
  Future<bool> loadMore({int? limit}) async {
    if (!state.hasMore || state.isLoadingMore || state.nextCursor == null) {
      return false;
    }
    
    return await loadFromEndpoint(
      'feed/latest',
      queryParams: {
        'cursor': state.nextCursor!,
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
      },
      isLoadMore: true,
    );
  }
  
  @override
  BaseFeedState build() {
    final jsonString = ref.watch(preferencesRepositoryProvider).getString(cacheKey);
    if (jsonString == null) return const BaseFeedState();
    final feedItems = List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
    return BaseFeedState(items: feedItems);
  }

  Future<void> setValue(List<FeedItem>? value) async {
    state = state.copyWith(items: value);
    final feedItemsString = value == null ? null : jsonEncode(value.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(cacheKey, feedItemsString);
  }

  Future<void> clear() async {
    state = const BaseFeedState();
    await ref.read(preferencesRepositoryProvider).remove(cacheKey);
  }

  Future<void> update(String feedId, {bool? isLiked, bool? isSaved}) async {
    final currentItem = state.items?.firstWhere((item) => item.id == feedId);
    if (currentItem == null) return;

    // Fire and forget API calls
    if (isLiked != null && isLiked != currentItem.isLiked) {
      fireAndForget(() => like(feedId, isLiked));
    }
    if (isSaved != null && isSaved != currentItem.isSaved) {
      fireAndForget(() => save(feedId, isSaved));
    }

    final updatedItems = state.items?.map((item) {
      if (item.id == feedId) {
        return item.copyWith(
          isLiked: isLiked ?? item.isLiked,
          isSaved: isSaved ?? item.isSaved,
        );
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
    
    // Update cached data
    final feedItemsString = updatedItems == null ? null : jsonEncode(updatedItems.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(cacheKey, feedItemsString);
  }

  Future<bool> loadFromEndpoint(String endpoint, {Map<String, String>? queryParams, ApiOptions? options, bool isLoadMore = false}) async {
    state = state.copyWith(
      isLoading: !isLoadMore, 
      isLoadingMore: isLoadMore, 
      error: null
    );
    
    try {
      final response = await ApiService.get(endpoint, queryParams: queryParams, options: options);

      if (response.successful) {
        final feedItems = List<FeedItem>.from(
          response.data.map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
        );
        
        final List<FeedItem> updatedItems;
        if (isLoadMore && state.items != null) {
          // Append new items to existing ones
          updatedItems = [...state.items!, ...feedItems];
        } else {
          // Replace all items for initial load
          updatedItems = feedItems;
        }
        
        // Extract pagination info from response
        final hasMore = response.result?['hasMore'] ?? true;
        final nextCursor = response.result?['nextCursor'];
        
        await setValue(updatedItems);
        
        // Update pagination state
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );

        // Log last ingestion date for daily digest feed
        if (endpoint == 'feed') {
          final lastIngestDate = response.result?['lastIngestDate'] as String?;
          if (lastIngestDate != null) {
            // await ref.read(preferencesRepositoryProvider).setString('ingest_last_date', lastIngestDate);
            await ref.read(ingestLastDateProvider.notifier).setValue(DateTime.parse(lastIngestDate));
          }
        }

        return true;
      } else {
        state = state.copyWith(
          isLoading: false, 
          isLoadingMore: false, 
          error: response.error
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        isLoadingMore: false, 
        error: e.toString()
      );
      return false;
    }
  }
}
