import 'dart:math' show max;
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;

class BaseFeedState {
  final List<FeedItem>? items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final String? nextCursor;
  final Set<String> notInterestedItems;
  final Map<String, FeedbackCategory> notInterestedReasons;

  bool get isEmpty => items?.isEmpty ?? true;
  bool get isGetting => isEmpty && isLoading;
  bool get isNone => isEmpty && !isLoading;
  bool get isAvailable => !isEmpty && !isLoading;
  int get total => items?.length ?? 0;

  const BaseFeedState({
    this.items,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.nextCursor,
    this.notInterestedItems = const {},
    this.notInterestedReasons = const {},
  });

  BaseFeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    String? nextCursor,
    Set<String>? notInterestedItems,
    Map<String, FeedbackCategory>? notInterestedReasons,
  }) {
    return BaseFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      notInterestedItems: notInterestedItems ?? this.notInterestedItems,
      notInterestedReasons: notInterestedReasons ?? this.notInterestedReasons,
    );
  }

  /// Get a specific feed item by ID, returns null if not found
  FeedItem? getItem(String feedId) {
    return items?.firstWhereOrNull((item) => item.id == feedId);
  }

  bool isNotInterested(String id) {
    return notInterestedItems.contains(id);
  }
}

abstract class BaseFeedNotifier extends Notifier<BaseFeedState> {
  /// Generate cursor from feed item in format: publishedAt|id
  String? generateCursor(FeedItem? item) {
    if (item == null || item.publishedAt == null) return null;
    return '${item.publishedAt!.toIso8601String()}|${item.id}';
  }
  
  /// Load more items using cursor pagination
  Future<bool> loadMore({int? limit}) async {
    log('[BaseFeedNotifier] loadMore called. hasMore: ${state.hasMore}, isLoadingMore: ${state.isLoadingMore}, nextCursor: ${state.nextCursor}');
    if (!state.hasMore || state.isLoadingMore || state.nextCursor == null) {
      log('[BaseFeedNotifier] loadMore blocked - hasMore: ${state.hasMore}, isLoadingMore: ${state.isLoadingMore}, nextCursor: ${state.nextCursor}');
      return false;
    }
    
    // Additional safeguard: prevent too many items (indicates stuck cursor)
    if (state.items != null && state.items!.length > 200) {
      log('[BaseFeedNotifier] WARNING: Too many items (${state.items!.length}), stopping pagination to prevent infinite loop');
      return false;
    }
    
    return await loadFromEndpoint(
      endpoint,
      queryParams: {
        'cursor': state.nextCursor!,
        'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
      },
      isLoadMore: true,
    );
  }
  
  /// Reset pagination state by clearing nextCursor and resetting hasMore
  Future<void> resetPagination() async {
    state = state.copyWith(
      nextCursor: null,
      hasMore: true,
    );
  }
  
  /// Get the endpoint for this feed type - must be implemented by subclasses
  String get endpoint;
  
  @override
  BaseFeedState build() {
    // Feed cache data is now handled by SecureFeedCache, initialized with empty state
    return const BaseFeedState();
  }

  Future<void> setValue(List<FeedItem>? value, {bool skipCache = false}) async {
    state = state.copyWith(items: value);
    
    // Update cache when called from UI actions (unlike/unsave)
    // This ensures cache stays in sync with user interactions
    if (value != null && !skipCache) {
      final cache = ref.read(feedCacheProvider);
      await cache.setFeedItems(endpoint, value);
    }
  }

  Future<void> clear() async {
    state = const BaseFeedState();
    
    // Clear the cache for this endpoint from secure storage
    final cache = ref.read(feedCacheProvider);
    await cache.invalidateAllCacheForEndpoint(endpoint);
  }

  /// Mark a specific feed item as not interested (soft removal)
  Future<void> markAsNotInterested(String feedId, {FeedbackCategory? reason}) async {
    final updatedNotInterestedItems = Set<String>.from(state.notInterestedItems)..add(feedId);
    final updatedNotInterestedReasons = Map<String, FeedbackCategory>.from(state.notInterestedReasons);
  
    if (reason != null) {
      updatedNotInterestedReasons[feedId] = reason;
    }
  
    state = state.copyWith(
      notInterestedItems: updatedNotInterestedItems,
      notInterestedReasons: updatedNotInterestedReasons,
    );
  
    // Invalidate cache since we marked an item as not interested
    final cache = ref.read(feedCacheProvider);
    await cache.invalidateAllCacheForEndpoint(endpoint);
  }

  /// Mark all feed items from the same source as not interested
  Future<void> markAllFromSourceAsNotInterested(String sourceId, {FeedbackCategory? reason}) async {
    if (state.items == null) return;
    
    // Find all feed items from the same source
    final itemsFromSource = state.items!.where((item) => item.source.id == sourceId).toList();
    if (itemsFromSource.isEmpty) return;
    
    // Mark all items from this source as not interested
    final updatedNotInterestedItems = Set<String>.from(state.notInterestedItems);
    final updatedNotInterestedReasons = Map<String, FeedbackCategory>.from(state.notInterestedReasons);
    
    for (final item in itemsFromSource) {
      updatedNotInterestedItems.add(item.id);
      if (reason != null) {
        updatedNotInterestedReasons[item.id] = reason;
      }
    }
    
    state = state.copyWith(
      notInterestedItems: updatedNotInterestedItems,
      notInterestedReasons: updatedNotInterestedReasons,
    );
    
    // Invalidate cache since we marked items as not interested
    final cache = ref.read(feedCacheProvider);
    await cache.invalidateAllCacheForEndpoint(endpoint);
  }

  /// Unmark a feed item as not interested (undo)
  Future<void> unmarkAsNotInterested(String feedId) async {
    final updatedNotInterestedItems = Set<String>.from(state.notInterestedItems)..remove(feedId);
    final updatedNotInterestedReasons = Map<String, FeedbackCategory>.from(state.notInterestedReasons)..remove(feedId);
  
    state = state.copyWith(
      notInterestedItems: updatedNotInterestedItems,
      notInterestedReasons: updatedNotInterestedReasons,
    );
  
    // Invalidate cache since we unmarked an item as not interested
    final cache = ref.read(feedCacheProvider);
    await cache.invalidateAllCacheForEndpoint(endpoint);
  }

  /// Get the reason for a feed item being marked as not interested
  FeedbackCategory? getNotInterestedReason(String feedId) {
    return state.notInterestedReasons[feedId];
  }

  Future<void> update(String feedId, {bool? isLiked, bool? isSaved}) async {
    final currentItem = state.items?.firstWhere((item) => item.id == feedId);
    if (currentItem == null) return;

    // Calculate new like count for feed item
    int? newLikeCount;

    // Calculate new like count for user
    final currentUser = ref.read(userProvider);
    int? newLikedCount;
    int? newSavedCount;

    // Track which operations actually changed state to avoid redundant cache invalidation
    final List<String> cachesToInvalidate = [];
    
    // Fire and forget API calls and track changes
    if (isLiked != null && isLiked != currentItem.isLiked) {
      newLikeCount = isLiked ? currentItem.likeCount + 1 : currentItem.likeCount - 1;
      newLikedCount = isLiked ? currentUser.likedCount + 1 : currentUser.likedCount - 1;
      fireAndForget(() => like(feedId, isLiked));
      
      cachesToInvalidate.add('feed/liked');
      if (endpoint == 'feed') {
        cachesToInvalidate.add(endpoint);
      }
    }
    if (isSaved != null && isSaved != currentItem.isSaved) {
      newSavedCount = isSaved ? currentUser.savedCount + 1 : currentUser.savedCount - 1;
      fireAndForget(() => save(feedId, isSaved));
      
      cachesToInvalidate.add('feed/saved');
      if (endpoint == 'feed') {
        cachesToInvalidate.add(endpoint);
      }
    }

    // Update feed item state
    final updatedItems = state.items?.map((item) {
      if (item.id == feedId) {
        return item.copyWith(
          isLiked: isLiked ?? item.isLiked,
          isSaved: isSaved ?? item.isSaved,
          likeCount: max(0, newLikeCount ?? item.likeCount),
        );
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);

    // Update user state and cache
    ref.read(userProvider.notifier).setValue(currentUser.copyWith(
      likedCount: max(0, newLikedCount ?? currentUser.likedCount),
      savedCount: max(0, newSavedCount ?? currentUser.savedCount),
    ));
    
    // Update cached data
    // final feedItemsString = updatedItems == null ? null : jsonEncode(updatedItems.map((item) => item.toJson()).toList());
    // await ref.read(preferencesRepositoryProvider).setString(endpoint, feedItemsString);

    // Feed cache data is now handled by SecureFeedCache, no need to save to SharedPreferences
    // The cache will be updated/invalidated below if needed
    
    // Invalidate caches only when actual changes occurred
    if (cachesToInvalidate.isNotEmpty) {
      final cache = ref.read(feedCacheProvider);
      // Use a Set to avoid duplicate invalidations
      final uniqueCaches = cachesToInvalidate.toSet();
      for (final cacheKey in uniqueCaches) {
        await cache.invalidateCache(cacheKey);
      }
    }
  }

  /// Loads feed items from a specified API endpoint with caching and pagination support.
  /// 
  /// This method handles fetching feed data from the server, managing cache storage,
  /// and supporting pagination for both initial loads and loading more items.
  /// 
  /// **Parameters:**
  /// - [endpoint]: The API endpoint to fetch feed items from (e.g., 'feed', 'daily-digest')
  /// - [queryParams]: Optional query parameters to include in the API request
  /// - [options]: Optional API configuration options for the request
  /// - [isLoadMore]: If true, appends new items to existing ones instead of replacing them
  /// - [forceRefresh]: If true, bypasses cache and forces a fresh API call
  /// 
  /// **Returns:** `Future<bool>` indicating whether the load operation was successful
  /// 
  /// **Behavior:**
  /// - For initial loads (`!isLoadMore && !forceRefresh`), attempts to load from cache first
  /// - Updates loading states appropriately for both initial loads and pagination
  /// - Handles pagination metadata (`hasMore`, `nextCursor`) from the API response
  /// - Caches successful responses for initial loads (not for load-more operations)
  /// - Special handling for 'feed' endpoint to track last ingestion date
  /// 
  /// **State Updates:**
  /// - Sets `isLoading`/`isLoadingMore` during the operation
  /// - Updates `hasMore` and `nextCursor` for pagination
  /// - Sets `error` state if the operation fails
  Future<bool> loadFromEndpoint(String endpoint, {
    Map<String, String>? queryParams,
    ApiOptions? options,
    bool isLoadMore = false,
    bool forceRefresh = false
  }) async {
    final cache = ref.read(feedCacheProvider);
    
    // Try to load from cache first (unless force refresh or load more)
    if (!forceRefresh && !isLoadMore) {
      final cachedItems = await cache.getFeedItems(endpoint, queryParams: queryParams);
      if (cachedItems != null) {
        await setValue(cachedItems);
        // Set pagination state for cached data
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasMore: true, // Assume more data available for cached content
        );
        return true;
      }
    }

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
        
        log('[BaseFeedNotifier] API response: received ${feedItems.length} items, isLoadMore: $isLoadMore');
        log('[BaseFeedNotifier] Current state items: ${state.items?.length ?? 0}');
        
        // Extract pagination info from response
        final hasMore = response.result?['hasMore'] ?? true;
        final nextCursor = response.result?['nextCursor'];
        
        // log('[BaseFeedNotifier] Full response result: ${response.result}');
        log('[BaseFeedNotifier] Pagination: hasMore: $hasMore, nextCursor: $nextCursor');
        log('[BaseFeedNotifier] Previous cursor: ${state.nextCursor}');
        
        final List<FeedItem> updatedItems;
        if (isLoadMore && state.items != null) {
          // Check if we're getting duplicate items (same cursor)
          if (nextCursor == state.nextCursor) {
            log('[BaseFeedNotifier] WARNING: Same cursor detected, skipping duplicate items');
            return false;
          }
          
          // Append new items to existing ones
          updatedItems = [...state.items!, ...feedItems];
          log('[BaseFeedNotifier] Appended items: ${state.items!.length} + ${feedItems.length} = ${updatedItems.length}');
        } else {
          // Replace all items for initial load
          updatedItems = feedItems;
          log('[BaseFeedNotifier] Replaced items: ${updatedItems.length}');
        }
        
        await setValue(updatedItems, skipCache: isLoadMore);
        
        // Cache the response (only for initial loads, not load more)
        if (!isLoadMore) {
          await cache.setFeedItems(endpoint, updatedItems, queryParams: queryParams);
        }
        
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
            await Future.wait([
              ref.read(ingestLastDateProvider.notifier).setValue(DateTime.parse(lastIngestDate)),
              ref.read(preferencesRepositoryProvider).remove('read_count_states'),
            ]);
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
