import 'dart:math' show max;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/utils/secure_feed_cache.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/feed.dart';

/// Utility functions for feed state management
class FeedStateService {

  /// Mark feed as not interested across all feed types
  static Future<void> markNotInterestedEverywhere(
    WidgetRef ref,
    FeedItem feedItem, {
    FeedbackCategory? reason,
  }) async {
    final feedId = feedItem.id;
    
    for (final feedType in FeedType.values) {
      // Skip notInterested feed type to avoid circular dependency
      if (feedType == FeedType.notInterested) continue;

      // Mark feed item as not interested
      try {
        final notifier = feedType.getNotifier(ref);
        await notifier.markAsNotInterested(feedId, reason: reason);
      } catch (_) {}
    }

    // Prepend feed item to the not interested feed
    try {
      final notInterestedNotifier = ref.read(feedNotInterestedProvider.notifier);
      await notInterestedNotifier.prependItem(feedItem);
    } catch (_) {}
  }

  /// Unmark feed as not interested across all feed types
  static Future<void> unmarkNotInterestedEverywhere(
    WidgetRef ref,
    String feedId,
  ) async {
    try {
      for (final feedType in FeedType.values) {
        // Skip notInterested feed type to avoid circular dependency
        if (feedType == FeedType.notInterested) continue;
        
        final notifier = feedType.getNotifier(ref);
        await notifier.unmarkAsNotInterested(feedId);
      }

      // Remove feed item from the not interested feed
      final notInterestedNotifier = ref.read(feedNotInterestedProvider.notifier);
      await notInterestedNotifier.removeItem(feedId);

      // Decrement user's not interested count
      final userNotifier = ref.read(userProvider.notifier);
      await userNotifier.decrementNotInterested();
    } catch (e) {
      // Silently ignore errors related to unmounted widgets
      if (!e.toString().contains('unmounted')) {
        rethrow;
      }
    }
  }

  
  /// Check if feed should be hidden (SSOT logic)
  static bool shouldHideFeed(
    WidgetRef ref,
    FeedItem? feedItem,
  ) {
    if (feedItem == null) return false;
    
    final feedId = feedItem.id;
    final preferences = ref.watch(preferencesProvider);
    final isSourceAvoided = preferences.avoidedSources.contains(feedItem.source);

    // Check any feed type for not interested status
    final isNotInterested = FeedType.values.any((feedType) {
      return feedType.watch(ref).isNotInterested(feedId);
    });
    
    return isNotInterested || isSourceAvoided;
  }

  /// Get not interested reason from any feed type
  static FeedbackCategory? getNotInterestedReason(WidgetRef ref, String feedId) {
    for (final feedType in FeedType.values) {
      final reason = feedType.getNotifier(ref).getNotInterestedReason(feedId);
      if (reason != null) return reason;
    }
    return null;
  }

  /// Get all not interested feeds from all feed types
  static Map<String, FeedbackCategory?> getAllNotInterestedFeeds(WidgetRef ref) {
    final allNotInterestedItems = <String, FeedbackCategory?>{};
    
    for (final feedType in FeedType.values) {
      final BaseFeedNotifier notifier = feedType.getNotifier(ref);
      final state = feedType.read(ref);
      
      if (state.items != null) {
        for (final item in state.items!) {
          if (state.isNotInterested(item.id)) {
            final reason = notifier.getNotInterestedReason(item.id);
            allNotInterestedItems[item.id] = reason;
          }
        }
      }
    }
    
    return allNotInterestedItems;
  }

  /// Update like status across all feed types
  static Future<void> updateLikeStatusEverywhere(
    WidgetRef ref,
    String feedId,
    bool isLiked, {
    int? likeCount,
    FeedType? skipFeedType,
  }) async {
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = feedType.getNotifier(ref);
      final currentState = feedType.read(ref);
      final currentItem = currentState.items?.firstWhereOrNull((item) => item.id == feedId);
      if (currentItem != null && currentItem.isLiked != isLiked) {
        // Update the item in this feed type
        final updatedItems = currentState.items?.map((item) {
          if (item.id == feedId) {
            return item.copyWith(
              isLiked: isLiked,
              likeCount: likeCount ?? (isLiked ? item.likeCount + 1 : max(0, item.likeCount - 1)),
            );
          }
          return item;
        }).toList();
        
        await notifier.setValue(updatedItems);
      }
    }
  }

  /// Updates the like status of a feed item across all feed types.
  /// 
  /// This method ensures that when an item is liked or unliked, the change
  /// is reflected everywhere the item appears - in all feed lists and caches.
  /// Also updates user state to maintain consistency.
  /// 
  /// Parameters:
  /// - [ref] - The Ref for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [isLiked] - The new like status (true = liked, false = unliked)
  /// - [skipFeedType] - Optional feed type to skip (prevents circular updates)
  /// - [likeCount] - Optional pre-calculated like count (ensures consistency across feed types)
  /// - [updateCache] - Whether to update cache (default: true)
  static Future<void> updateLikeStatusEverywhereWithRef(
    Ref ref,
    FeedItem feedItem,
    bool isLiked, {
    FeedType? skipFeedType,
    int? likeCount,
    bool updateCache = true,
  }) async {
    // Update user state first to maintain consistency
    final currentUser = ref.read(userProvider);
    final newTotalLiked = isLiked ? currentUser.totalLiked + 1 : currentUser.totalLiked - 1;
    await ref.read(userProvider.notifier).setValue(currentUser.copyWith(
      totalLiked: max(0, newTotalLiked),
    ));
    log('[FeedStateService] ❤️ Updated user totalLiked: $newTotalLiked (like: $isLiked)');
    
    // Calculate like count once to ensure consistency across all feed types
    final calculatedLikeCount = likeCount ?? (isLiked ? feedItem.likeCount + 1 : max(0, feedItem.likeCount - 1));
    log('[FeedStateService] ❤️ Calculated likeCount for ${feedItem.id}: $calculatedLikeCount ${likeCount != null ? '(provided)' : '(calculated)'}');
    
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = feedType.getNotifierWithRef(ref);
      final currentState = feedType.readWithRef(ref);
      final currentItem = currentState.items?.firstWhereOrNull((item) => item.id == feedItem.id);
      if (currentItem != null && currentItem.isLiked != isLiked) {
        // Update the item in this feed type with pre-calculated like count
        final updatedItems = currentState.items?.map((item) {
          if (item.id == feedItem.id) {
            return item.copyWith(
              isLiked: isLiked,
              likeCount: calculatedLikeCount,
            );
          }
          return item;
        }).toList();
        
        await notifier.setValue(updatedItems);
      }
    }
    
    // Update cache for liked feeds if requested
    if (updateCache) {
      final cache = ref.read(feedCacheProvider);
      await _updateLikedFeedsCache(cache, feedItem.copyWith(isLiked: isLiked, likeCount: calculatedLikeCount), isLiked);
      
      log('[FeedStateService] ❤️ Updated liked feeds cache: ${isLiked ? 'added' : 'removed'} item ${feedItem.id}');
    } else {
      log('[FeedStateService] ⏸️ Skipping cache update for liked item ${feedItem.id} (updateCache=false)');
    }
  }

  /// Update cache for liked feeds
  static Future<void> _updateLikedFeedsCache(
    SecureFeedCache cache,
    FeedItem updatedItem,
    bool isActive,
  ) async {
    try {
      final currentItems = await cache.getFeedItems('feed/liked') ?? <FeedItem>[];
      
      final List<FeedItem> updatedItems;
      
      if (isActive) {
        // Add item to feed (avoid duplicates)
        updatedItems = [
          updatedItem,
          ...currentItems.where((item) => item.id != updatedItem.id),
        ];
      } else {
        // Remove the item from feed
        updatedItems = currentItems
            .where((item) => item.id != updatedItem.id)
            .toList();
      }
      
      // Update the cache with the modified list
      await cache.setFeedItems('feed/liked', updatedItems);
      
      log('[FeedStateService] ❤️ Updated feed/liked cache: ${isActive ? 'added' : 'removed'} item ${updatedItem.id}');
    } catch (e) {
      log('[FeedStateService] 💔 Failed to update feed/liked cache: $e');
      // Fallback to full invalidation on error
      await cache.invalidateAllCacheForEndpoint('feed/liked');
    }
  }

  /// Updates the save status of a feed item across all feed types and caches.
  /// 
  /// This method ensures that when an item is saved or unsaved, the change
  /// is reflected everywhere the item appears - in all feed lists and cache entries.
  /// 
  /// Parameters:
  /// - [ref] - The WidgetRef for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [isSaved] - The new save status (true = saved, false = unsaved)
  /// - [skipFeedType] - Optional feed type to skip (prevents circular updates)
  /// - [specificCollection] - Optional collection name for targeted cache updates
  /// - [updateCache] - Whether to update cache (default: true)
  static Future<void> updateSaveStatusEverywhere(
    WidgetRef ref,
    FeedItem feedItem,
    bool isSaved, {
    FeedType? skipFeedType,
    String? specificCollection,
    bool updateCache = true,
  }) async {
    await _updateSaveStatusEverywhereImpl(
      ref: ref,
      feedItem: feedItem,
      isSaved: isSaved,
      skipFeedType: skipFeedType,
      specificCollection: specificCollection,
      updateCache: updateCache,
      getNotifier: (feedType, ref) => feedType.getNotifier(ref),
      readState: (feedType, ref) => feedType.read(ref),
    );
  }

  /// Updates the save status of a feed item across all feed types and caches.
  /// 
  /// This is the Ref version that works with any Ref type (not just WidgetRef).
  /// See [updateSaveStatusEverywhere] for full documentation.
  /// 
  /// Parameters:
  /// - [ref] - The Ref for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [isSaved] - The new save status (true = saved, false = unsaved)
  /// - [skipFeedType] - Optional feed type to skip (prevents circular updates)
  /// - [specificCollection] - Optional collection name for targeted cache updates
  /// - [updateCache] - Whether to update cache (default: true)
  static Future<void> updateSaveStatusEverywhereWithRef(
    Ref ref,
    FeedItem feedItem,
    bool isSaved, {
    FeedType? skipFeedType,
    String? specificCollection,
    bool updateCache = true,
  }) async {
    await _updateSaveStatusEverywhereImpl(
      ref: ref,
      feedItem: feedItem,
      isSaved: isSaved,
      skipFeedType: skipFeedType,
      specificCollection: specificCollection,
      updateCache: updateCache,
      getNotifier: (feedType, ref) => feedType.getNotifierWithRef(ref),
      readState: (feedType, ref) => feedType.readWithRef(ref),
    );
  }

  /// Common implementation for updating save status across all feed types.
  /// 
  /// This private method contains the shared logic to avoid code duplication
  /// between the WidgetRef and Ref versions of public methods.
  /// Also updates user state to maintain consistency.
  static Future<void> _updateSaveStatusEverywhereImpl({
    required dynamic ref,
    required FeedItem feedItem,
    required bool isSaved,
    FeedType? skipFeedType,
    String? specificCollection,
    bool updateCache = true,
    required Function getNotifier,
    required Function readState,
  }) async {
    // Update user state first to maintain consistency
    final currentUser = ref.read(userProvider);
    final newTotalSaved = isSaved ? currentUser.totalSaved + 1 : currentUser.totalSaved - 1;
    await ref.read(userProvider.notifier).setValue(currentUser.copyWith(
      totalSaved: max(0, newTotalSaved),
    ));
    log('[FeedStateService] 💾 Updated user totalSaved: $newTotalSaved (save: $isSaved)');
    
    // Update the item in all feed types
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = getNotifier(feedType, ref);
      final currentState = readState(feedType, ref);
      final currentItem = currentState.items?.firstWhereOrNull((item) => item.id == feedItem.id);
      if (currentItem != null && currentItem.isSaved != isSaved) {
        // Update the item in this feed type
        final updatedItems = currentState.items?.map((item) {
          if (item.id == feedItem.id) {
            return item.copyWith(isSaved: isSaved);
          }
          return item;
        }).toList();
        
        await notifier.setValue(updatedItems);
      }
    }
    
    // Update cache for saved feeds if requested
    if (updateCache) {
      final cache = ref.read(feedCacheProvider);
      
      // Determine which cache to update
      final queryParams = specificCollection != null 
          ? {'collection': specificCollection}
          : null;
      
      // Update the appropriate cache (single operation)
      await _updateCacheForQueryWithRef(cache, 'feed/saved', queryParams, feedItem, isSaved);
      
      log('[FeedStateService] 💾 Updated saved feeds cache: ${isSaved ? 'added' : 'removed'} item ${feedItem.id} ${specificCollection != null ? 'to/from "$specificCollection"' : '(all)'}');
    } else {
      log('[FeedStateService] ⏸️ Skipping cache update for saved item ${feedItem.id} (updateCache=false)');
    }
  }

  /// Update cache for a specific query parameter combination
  static Future<void> _updateCacheForQueryWithRef(
    SecureFeedCache cache,
    String endpoint,
    Map<String, String>? queryParams,
    FeedItem feedItem,
    bool isActive,
  ) async {
    try {
      final currentItems = await cache.getFeedItems(endpoint, queryParams: queryParams) ?? <FeedItem>[];
      
      final List<FeedItem> updatedItems;
      
      if (isActive) {
        // Add item to feed (avoid duplicates, prepend for most recent first)
        updatedItems = [feedItem, ...currentItems.where((item) => item.id != feedItem.id)];
      } else {
        // Remove the item from feed
        updatedItems = currentItems
            .where((item) => item.id != feedItem.id)
            .toList();
      }
      
      // Update cache with the modified list
      await cache.setFeedItems(endpoint, updatedItems, queryParams: queryParams);
      
      final querySuffix = queryParams != null ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
      log('[FeedStateService] 💾 Updated cache for $endpoint$querySuffix: ${isActive ? 'added' : 'removed'} item ${feedItem.id}');
    } catch (e) {
      log('[FeedStateService] ❌ Failed to update cache for query $queryParams: $e');
      // Invalidate this specific cache on error
      await cache.invalidateCache(endpoint, queryParams: queryParams);
    }
  }

  /// Safe API execution with consistent error handling
  static Future<T?> safeApiCall<T>(
    BuildContext context,
    Future<T> Function() apiCall,
    String successMessage, {
    String? errorMessage,
  }) async {
    try {
      final result = await apiCall();
      if (context.mounted) {
        showSnackBarSuccess(context, successMessage);
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        showSnackBarError(context, errorMessage ?? "Operation failed: $e");
      }
      return null;
    }
  }
}
