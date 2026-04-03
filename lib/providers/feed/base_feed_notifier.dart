import 'dart:math' show max;
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/services/dio.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/services/collection_service.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/utils/functions.dart';
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
    return items?.where((item) => item.id == feedId).firstOrNull;
  }

  bool isNotInterested(String feedId) {
    return notInterestedItems.contains(feedId);
  }
}

abstract class BaseFeedNotifier extends Notifier<BaseFeedState> {
  /// Load more items using cursor pagination
  Future<bool> loadMore({int? limit}) async {
    log('[BaseFeedNotifier] 🔍 loadMore called. hasMore: ${state.hasMore}, isLoadingMore: ${state.isLoadingMore}, nextCursor: ${state.nextCursor}');
    if (!state.hasMore || state.isLoadingMore || state.nextCursor == null) {
      log('[BaseFeedNotifier] ❓ loadMore blocked - hasMore: ${state.hasMore}, isLoadingMore: ${state.isLoadingMore}, nextCursor: ${state.nextCursor}');
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
  void resetPagination() {
    state = state.copyWith(
      nextCursor: null,
      hasMore: true,
    );
  }
  
  /// Get endpoint for this feed type - must be implemented by subclasses
  String get endpoint;

  /// Get current [FeedType] based on the endpoint
  FeedType get _currentFeedType => FeedType.fromEndpoint(endpoint);
  
  /// Track current queryParams for caching
  Map<String, String>? _currentQueryParams;
  
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
      log('[BaseFeedNotifier] 🔄 Updating cache for endpoint: $endpoint with queryParams: $_currentQueryParams');
      await cache.setFeedItems(endpoint, value, queryParams: _currentQueryParams);
    }
  }

  Future<void> clear() async {
    state = const BaseFeedState();
    
    // Reset tracked queryParams when clearing
    _currentQueryParams = null;
    
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

  /// Updates the like/save status of a feed item across all feed types
  /// 
  /// This method has circular dependency issues and manual cache management.
  /// Migrate to updateSafe() for cleaner, dependency-free operation.
  /// 
  /// Parameters:
  /// - [feedId] - The ID of the feed item to update
  /// - [isLiked] - Optional new like status
  /// - [isSaved] - Optional new save status
  Future<void> updateSafe(String feedId, {bool? isLiked, bool? isSaved}) async {
    final currentItem = state.items?.firstWhere((item) => item.id == feedId);
    if (currentItem == null) return;

    final shouldHandleLike = isLiked != null && isLiked != currentItem.isLiked;
    final shouldHandleSave = isSaved != null && isSaved != currentItem.isSaved;

    // Handle like operation with new safe approach
    if (shouldHandleLike) {
      // Calculate like count once to ensure consistency
      final calculatedLikeCount = isLiked ? currentItem.likeCount + 1 : max(0, currentItem.likeCount - 1);
      
      // Use the new return-based method - no circular dependencies!
      final result = await FeedStateService.updateLikeStatusEverywhereSafe(
        ref: ref,
        feedItem: currentItem,
        isLiked: isLiked,
        likeCount: calculatedLikeCount,
      );
      
      // Apply returned result to all feed types and cache - DRY!
      await result.applyToAllFeeds(ref, feedId);
      
      log('[BaseFeedNotifier] ✅ Safe like update completed: item $feedId, isLiked=$isLiked, likeCount=$result.updatedLikeCount');
    }
    
    // Handle save operation with new safe approach
    if (shouldHandleSave) {
      // For save operations, determine which collection the feed belongs to
      if (!isSaved) {
        final currentCollection = await CollectionService.getFeedCollection(ref, currentItem);
        fireAndForget(() async {
          await save(feedId, isSaved, collection: currentCollection);
        });
      } else {
        fireAndForget(() => save(feedId, isSaved));
      }
      
      // Use the new return-based method - no circular dependencies!
      // For save operations, we need to handle collection name properly
      final collectionName = isSaved ? await CollectionService.getFeedCollection(ref, currentItem) : null;
      final result = await FeedStateService.updateSaveStatusEverywhereSafe(
        ref: ref,
        feedItem: currentItem,
        isSaved: isSaved,
        collectionName: collectionName,
      );
      
      // Apply returned result to all feed types and cache - DRY!
      final applyResult = await result.applyToAllFeeds(ref, feedId);
      
      if (!applyResult.isCompleteSuccess) {
        log('[BaseFeedNotifier] ⚠️ Partial failure: ${(applyResult.successRate * 100).toStringAsFixed(1)}% success');
      }
      
      log('[BaseFeedNotifier] ✅ Safe save update completed: item $feedId, isSaved=$isSaved, collectionName=$result.collectionName');
      
      // Handle collection cleanup for unsave operations
      if (!isSaved) {
        Future.microtask(() async {
          await CollectionService.removeFromAllCollections(ref, currentItem);
        });
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
    bool forceRefresh = false,
    String? requestId,
  }) async {
    final cache = ref.read(feedCacheProvider);

    log('[BaseFeedNotifier] loadFromEndpoint called: endpoint=$endpoint, forceRefresh=$forceRefresh, isLoadMore=$isLoadMore');
    log('[BaseFeedNotifier] queryParams: $queryParams');

    // Track current queryParams for caching
    _currentQueryParams = queryParams;

    if (forceRefresh) resetPagination();
    
    // Try to load from cache first (unless force refresh or load more)
    if (!forceRefresh && !isLoadMore) {
      log('[BaseFeedNotifier] Checking cache for endpoint: $endpoint with queryParams: $queryParams');
      final cachedItems = await cache.getFeedItems(endpoint, queryParams: queryParams);
      if (cachedItems != null) {
        log('[BaseFeedNotifier] Cache hit! Found ${cachedItems.length} items for endpoint: $endpoint, queryParams: $queryParams');
        await setValue(cachedItems);

        // If we have a full page of items, assume there might be more data
        final hasMore = cachedItems.length % CURSOR_PAGINATION_LIMIT == 0;

        // Set pagination state for cached data
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasMore: hasMore,
        );
        return true;
      } else {
        log('[BaseFeedNotifier] 🍪 Cache miss, proceeding to API call for endpoint: $endpoint, queryParams: $queryParams');
      }
    } else {
      log('[BaseFeedNotifier] ⏩ Skipping cache check (forceRefresh=$forceRefresh, isLoadMore=$isLoadMore)');
    }

    state = state.copyWith(
      isLoading: !isLoadMore, 
      isLoadingMore: isLoadMore, 
      error: null
    );
    
    try {
      log('[BaseFeedNotifier] 🌐 Making API call to: $endpoint');
      
      // Add limit parameter for API calls (but not for cache keys)
      final apiQueryParams = <String, String>{
        'limit': CURSOR_PAGINATION_LIMIT.toString(),
        ...?queryParams,
      };
      
      final response = await ApiService.get(
        endpoint,
        queryParams: apiQueryParams,
        options: options,
        requestId: requestId,
      );

      if (response.successful) {
        final feedItems = List<FeedItem>.from(
          response.data.map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
        );
        
        log('[BaseFeedNotifier] 🔥 API response: received ${feedItems.length} items, isLoadMore: $isLoadMore');
        log('[BaseFeedNotifier] 🔥 API response items: ${feedItems.map((item) => item.id).toList()}');
        log('[BaseFeedNotifier] 📊 Current state items: ${state.items?.length ?? 0}');
        log('[BaseFeedNotifier] 👀 Response items count: ${response.result?['items']?.length}');
        // if (response.result?['items']?.isNotEmpty == true) {
        //   log('[BaseFeedNotifier] 👀 First result: ${response.result?['items'].first}');
        // } else {
        //   log('[BaseFeedNotifier] 👀 No result');
        // }
        // log('[BaseFeedNotifier] Response result: ${response.result}');
        
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
            log('[BaseFeedNotifier] ⏩ Same cursor detected, skipping duplicate items');
            return false;
          }
          
          // Append new items to existing ones
          updatedItems = [...state.items!, ...feedItems];
          log('[BaseFeedNotifier] 🧩 Appended items: ${state.items!.length} + ${feedItems.length} = ${updatedItems.length}');
        } else {
          // Replace all items for initial load
          updatedItems = feedItems;
          log('[BaseFeedNotifier] 🧩 Replaced items: ${updatedItems.length}');
        }
        
        await setValue(updatedItems, skipCache: isLoadMore);

        // Check current page index
        final feedType = _currentFeedType;
        final currentReadCountStates = ref.read(readCountStatesProvider);
        final currentTopic = ref.read(topicProvider);
        final readCountStateKey = currentTopic ?? feedType.name;
        final currentPageIndex = currentReadCountStates[readCountStateKey] ?? 0;
        if (currentPageIndex > max(0, updatedItems.length - 1)) {
          log('[BaseFeedNotifier] 👀 page index overflow for $endpoint: removing key');
          ref.read(readCountStatesProvider.notifier).setValue({
            ...currentReadCountStates..remove(readCountStateKey)
          });
        }
        
        // Cache the response (only for initial loads, not load more)
        if (!isLoadMore) {
          log('[BaseFeedNotifier] 🍪 Caching ${updatedItems.length} items for endpoint: $endpoint');
          await cache.setFeedItems(endpoint, updatedItems, queryParams: queryParams);
        } else {
          log('[BaseFeedNotifier] ⏩ Skipping cache for loadMore operation');
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
            log('[BaseFeedNotifier] [digest] 🌟 Last ingest date: $lastIngestDate');
            await Future.wait([
              ref.read(ingestLastDateProvider.notifier).setValue(DateTime.parse(lastIngestDate)),
              ref.read(preferencesRepositoryProvider).remove('read_count_states'),
              prefs.setString('ingest_last_fetch', DateTime.now().toUtc().toIso8601String())
            ]);
            log('[BaseFeedNotifier] [digest] 🌟 Ingest last date updated: ${ref.read(ingestLastDateProvider)}');
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
