import 'dart:math' show max;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/models/feed_update_result.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/secure_feed_cache.dart';

/// Utility functions for feed state management
class FeedStateService {

  /// Mark feed as not interested across all feed types
  static Future<void> markAsNotInterestedEverywhere(
    WidgetRef ref,
    FeedItem feedItem, {
    FeedbackCategory? reason,
  }) async {
    try {
      // Update all feed types to mark item as not interested
      for (final feedType in FeedType.values) {
        // Skip notInterested feed type to avoid circular dependency
        if (feedType == FeedType.notInterested) continue;
        
        final notifier = feedType.getNotifier(ref);
        await notifier.markAsNotInterested(feedItem.id, reason: reason);
      }

      // Prepend feed item to the not interested feed
      try {
        final notInterestedNotifier = ref.read(feedNotInterestedProvider.notifier);
        await notInterestedNotifier.prependItem(feedItem);
      } catch (_) {}
    } catch (e) {
      log('[FeedStateService] Error marking as not interested: $e');
    }
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

  /// Updates collection feed caches by adding or removing items from lists.
  /// 
  /// This method is specifically designed for collection feeds like 'feed/liked' and 'feed/saved'
  /// where items are added to the beginning of the list when active (liked/saved) or removed
  /// when inactive (unliked/unsaved). It is NOT intended for updating existing items in-place
  /// (like digest feed items).
  /// 
  /// **Parameters:**
  /// - [cache]: The cache instance to update
  /// - [endpoint]: The collection endpoint (e.g., 'feed/liked', 'feed/saved')
  /// - [feedItem]: The feed item to add or remove
  /// - [isActive]: If true, item is added to list; if false, item is removed from list
  /// - [queryParams]: Optional query parameters for cache key generation
  /// 
  /// **Behavior:**
  /// - When [isActive] is true: Prepends item to list (avoiding duplicates)
  /// - When [isActive] is false: Removes item from list
  /// - Updates cache with modified list and appropriate expiration
  static Future<void> updateCollectionFeedCache(
    SecureFeedCache cache,
    String endpoint,
    FeedItem feedItem,
    bool isActive, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final currentItems = await cache.getFeedItems(endpoint, queryParams: queryParams) ?? <FeedItem>[];
      final List<FeedItem> updatedItems;
      
      if (isActive) {
        // Add item to feed (avoid duplicates, prepend for most recent first)
        updatedItems = [feedItem.copyWith(createdAt: DateTime.now().toUtc()), ...currentItems.where((item) => item.id != feedItem.id)];
      } else {
        // Remove the item from feed
        updatedItems = currentItems
            .where((item) => item.id != feedItem.id)
            .toList();
      }
      
      // Update cache with the modified list
      await cache.setFeedItems(endpoint, updatedItems, queryParams: queryParams);
      
      final querySuffix = queryParams != null ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
      log('[FeedStateService] 🍪 Updated cache for $endpoint$querySuffix: ${isActive ? 'added' : 'removed'} item ${feedItem.id}');
      log('[FeedStateService] 🍪 Cache key would be: cache:$endpoint${querySuffix.isEmpty ? '' : ':${querySuffix.substring(1)}'}');
      log('[FeedStateService] 🍪 Updated items count: ${updatedItems.length}');
    } catch (e) {
      log('[FeedStateService] ❌ Failed to update cache for $endpoint${queryParams != null ? ' with query $queryParams' : ''}: $e');
      // Invalidate cache on error
      if (queryParams != null) {
        await cache.invalidateCache(endpoint, queryParams: queryParams);
      } else {
        await cache.invalidateAllCacheForEndpoint(endpoint);
      }
    }
  }

  /// Updates collection name across all feed types and returns result for current feed
  /// 
  /// **Parameters:**
  /// - [ref] - The Ref or WidgetRef for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [collectionName] - The new collection name
  /// 
  /// **Returns:** FeedUpdateResult with updated item and user stats
  static Future<FeedUpdateResult> updateCollectionNameEverywhereSafe({
    required dynamic ref,
    required FeedItem feedItem,
    required String? collectionName,
  }) async {
    // Update user stats first for save operations
    final userUpdate = await _updateUserStatsSafely(
      ref, 
      isSaved: collectionName != null, 
    );
    
    // Update all OTHER feed types (no circular dependency)
    await _updateOtherFeedTypesSafely(
      ref, 
      feedItem, 
      isSaved: collectionName != null, 
      collectionName: collectionName
    );
    
    // Update collection caches
    await _updateCollectionCachesSafely(ref, feedItem, isSaved: collectionName != null, collectionName: collectionName);
    
    // Create updated feed item
    final updatedItem = feedItem.copyWith(
      isSaved: collectionName != null,
      collectionName: collectionName,
    );
    
    log('[FeedStateService] 🔄 Safe collection update completed for ${feedItem.id}: collectionName=$collectionName');
    
    return FeedUpdateResult.save(
      updatedItem: updatedItem,
      collectionName: collectionName,
      userUpdate: userUpdate,
    );
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

  // ============================================================================
  // RETURN-BASED ARCHITECTURE METHODS (CIRCULAR DEPENDENCY FREE)
  // ============================================================================

  /// Updates like status across all feed types and returns result for current feed
  /// 
  /// **Parameters:**
  /// - [ref] - The Ref or WidgetRef for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [isLiked] - The new like status (true = liked, false = unliked)
  /// - [likeCount] - Optional pre-calculated like count
  /// 
  /// **Returns:** FeedUpdateResult with updated item and user stats
  static Future<FeedUpdateResult> updateLikeStatusEverywhereSafe({
    required dynamic ref,
    required FeedItem feedItem,
    required bool isLiked,
    int? likeCount,
  }) async {
    // Calculate like count if not provided
    likeCount ??= isLiked ? feedItem.likeCount + 1 : max(0, feedItem.likeCount - 1);
    
    // Update user stats first
    final userUpdate = await _updateUserStatsSafely(ref, isLiked: isLiked, likeCount: likeCount);
    
    // Update all OTHER feed types (no circular dependency)
    await _updateOtherFeedTypesSafely(
      ref, 
      feedItem, 
      isLiked: isLiked, 
      likeCount: likeCount
    );
    
    // Update collection caches
    await _updateCollectionCachesSafely(ref, feedItem, isLiked: isLiked);
    
    // Create updated feed item
    final updatedItem = feedItem.copyWith(
      isLiked: isLiked,
      likeCount: likeCount,
    );
    
    log('[FeedStateService] 🔄 Safe like update completed for ${feedItem.id}: isLiked=$isLiked, likeCount=$likeCount');
    
    return FeedUpdateResult.like(
      updatedItem: updatedItem,
      likeCount: likeCount,
      userUpdate: userUpdate,
    );
  }

  /// Updates save status across all feed types and returns result for current feed
  /// 
  /// **Parameters:**
  /// - [ref] - The Ref or WidgetRef for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [isSaved] - The new save status (true = saved, false = unsaved)
  /// - [collectionName] - Optional collection name for saved items
  /// 
  /// **Returns:** FeedUpdateResult with updated item and user stats
  static Future<FeedUpdateResult> updateSaveStatusEverywhereSafe({
    required dynamic ref,
    required FeedItem feedItem,
    required bool isSaved,
    String? collectionName,
  }) async {
    // Update user stats first
    final userUpdate = await _updateUserStatsSafely(ref, isSaved: isSaved);
    
    // Update all OTHER feed types (no circular dependency)
    await _updateOtherFeedTypesSafely(
      ref, 
      feedItem, 
      isSaved: isSaved, 
      collectionName: collectionName
    );
    
    // Update collection caches
    await _updateCollectionCachesSafely(ref, feedItem, isSaved: isSaved, collectionName: collectionName);
    
    // Create updated feed item
    final updatedItem = feedItem.copyWith(
      isSaved: isSaved,
      collectionName: collectionName,
    );
    
    log('[FeedStateService] 🔄 Safe save update completed for ${feedItem.id}: isSaved=$isSaved, collectionName=$collectionName');
    
    return FeedUpdateResult.save(
      updatedItem: updatedItem,
      collectionName: collectionName,
      userUpdate: userUpdate,
    );
  }

  /// Safely update user statistics without circular dependencies
  static Future<UserUpdateResult?> _updateUserStatsSafely(
    dynamic ref, {
    bool? isSaved,
    bool? isLiked,
    int? likeCount,
  }) async {
    final User? currentUser = ref.read(userProvider);
    if (currentUser == null) {
      log('[FeedStateService] ❌ User not available, skipping user state update');
      return null;
    }
    
    final newTotalSaved = isSaved == true ? currentUser.totalSaved + 1 : 
                         isSaved == false ? currentUser.totalSaved - 1 : 
                         currentUser.totalSaved;
    final newTotalLiked = isLiked == true ? currentUser.totalLiked + 1 : 
                         isLiked == false ? currentUser.totalLiked - 1 : 
                         currentUser.totalLiked;
    
    final hasChanges = newTotalSaved != currentUser.totalSaved || newTotalLiked != currentUser.totalLiked;
    
    if (hasChanges) {
      await ref.read(userProvider.notifier).setValue(currentUser.copyWith(
        totalSaved: max(0, newTotalSaved),
        totalLiked: max(0, newTotalLiked),
      ));
      
      if (isSaved != null) {
        log('[FeedStateService] 💾 Updated user totalSaved: $newTotalSaved (save: $isSaved)');
      }
      if (isLiked != null) {
        log('[FeedStateService] ❤️ Updated user totalLiked: $newTotalLiked (like: $isLiked)');
      }
    }
    
    return UserUpdateResult(
      totalSaved: max(0, newTotalSaved),
      totalLiked: max(0, newTotalLiked),
      hasChanges: hasChanges,
    );
  }

  /// Update all feed types except the current one (no circular dependency)
  static Future<void> _updateOtherFeedTypesSafely(
    dynamic ref,
    FeedItem feedItem, {
    bool? isSaved,
    bool? isLiked,
    int? likeCount,
    String? collectionName,
  }) async {
    
    getNotifier(feedType, ref) {
      return ref is Ref ? feedType.getNotifierWithRef(ref) : feedType.getNotifier(ref);
    }
    
    readState(feedType, ref) {
      return ref is Ref ? feedType.readWithRef(ref) : feedType.read(ref);
    }

    for (final feedType in FeedType.values) {
      // NOTE: We don't need skipFeedType anymore because this method
      // only updates OTHER feed types, never the current one
      
      final notifier = getNotifier(feedType, ref);
      final currentState = readState(feedType, ref);
      final List<FeedItem> matchedItems = currentState.items?.where((item) => item.id == feedItem.id).toList() ?? <FeedItem>[];
      final FeedItem? currentItem = matchedItems.isEmpty ? null : matchedItems.first;
      
      // Check if item needs updating
      if (currentItem != null && (currentItem.isSaved != isSaved || currentItem.isLiked != isLiked || currentItem.collectionName != collectionName)) {
        // Update the item in this feed type
        final List<FeedItem>? updatedItems = currentState.items?.map<FeedItem>((FeedItem item) {
          if (item.id == feedItem.id) {
            return item.copyWith(
              isSaved: isSaved ?? item.isSaved,
              isLiked: isLiked ?? item.isLiked,
              likeCount: likeCount ?? item.likeCount,
              collectionName: collectionName ?? item.collectionName,
            );
          }
          return item;
        }).toList();
        
        await notifier.setValue(updatedItems);
        log('[FeedStateService] 🔄 Updated $feedType feed for item ${feedItem.id}');
      }
    }
  }

  /// Update collection caches safely
  static Future<void> _updateCollectionCachesSafely(
    dynamic ref,
    FeedItem feedItem, {
    bool? isSaved,
    bool? isLiked,
    String? collectionName,
  }) async {
    final cache = ref.read(feedCacheProvider);
    
    if (isSaved != null) {
      final queryParams = collectionName != null ? {'collection': collectionName} : null;
      await updateCollectionFeedCache(cache, 'feed/saved', feedItem, isSaved, queryParams: queryParams);
      log('[FeedStateService] 💾 Updated saved feeds cache: ${isSaved ? 'added' : 'removed'} item ${feedItem.id} ${collectionName != null ? 'to/from "$collectionName"' : '(all)'}');
    }
    
    if (isLiked != null) {
      await updateCollectionFeedCache(cache, 'feed/liked', feedItem, isLiked);
      log('[FeedStateService] ❤️ Updated liked feeds cache: ${isLiked ? 'added' : 'removed'} item ${feedItem.id}');
    }
  }
}
