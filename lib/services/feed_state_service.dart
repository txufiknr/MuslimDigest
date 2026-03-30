import 'dart:math' show max;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/utils/secure_feed_cache.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/variables/feed.dart';

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

  /// Update like status across all feed types
  static Future<void> updateLikeStatusEverywhere(
    dynamic ref,
    FeedItem feedItem,
    bool isLiked, {
    int? likeCount,
    FeedType? skipFeedType,
    bool updateCache = true,
  }) async {
    await _updateStatusEverywhereImpl(
      ref: ref,
      feedItem: feedItem,
      isLiked: isLiked,
      likeCount: likeCount,
      skipFeedType: skipFeedType,
      updateCache: updateCache,
    );
  }

  /// Update cache for a specific endpoint with optional query parameters
  static Future<void> _updateFeedItemsCache(
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

  /// Updates the save status of a feed item across all feed types and caches.
  /// 
  /// This method ensures that when an item is saved or unsaved, the change
  /// is reflected everywhere the item appears - in all feed lists and cache entries.
  /// 
  /// Parameters:
  /// - [ref] - The Ref or WidgetRef for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [isSaved] - The new save status (true = saved, false = unsaved)
  /// - [skipFeedType] - Optional feed type to skip (prevents circular updates)
  /// - [specificCollection] - Optional collection name for targeted cache updates
  /// - [updateCache] - Whether to update cache (default: true)
  static Future<void> updateSaveStatusEverywhere(
    dynamic ref,
    FeedItem feedItem,
    bool isSaved, {
    FeedType? skipFeedType,
    String? specificCollection,
    bool updateCache = true,
  }) async {
    await _updateStatusEverywhereImpl(
      ref: ref,
      feedItem: feedItem,
      isSaved: isSaved,
      skipFeedType: skipFeedType,
      specificCollection: specificCollection,
      updateCache: updateCache,
    );
  }

  /// Updates the save status and collection name of a feed item across all feed types and caches.
  /// 
  /// This method ensures that when an item's collection is changed, the change
  /// is reflected everywhere the item appears - in all feed lists and cache entries.
  /// 
  /// Parameters:
  /// - [ref] - The Ref or WidgetRef for accessing providers and state
  /// - [feedItem] - The feed item to update
  /// - [collectionName] - The new collection name (null if unsaved)
  /// - [skipFeedType] - Optional feed type to skip (prevents circular updates)
  /// - [updateCache] - Whether to update cache (default: true)
  static Future<void> updateCollectionNameEverywhere(
    dynamic ref,
    FeedItem feedItem,
    String? collectionName, {
    FeedType? skipFeedType,
    bool updateCache = true,
  }) async {
    await _updateStatusEverywhereImpl(
      ref: ref,
      feedItem: feedItem,
      isSaved: collectionName != null,
      collectionName: collectionName,
      skipFeedType: skipFeedType,
      updateCache: updateCache,
    );
  }

  /// Common implementation for updating save status across all feed types.
  /// 
  /// This private method contains the shared logic to avoid code duplication
  /// between the WidgetRef and Ref versions of public methods.
  /// Also updates user state to maintain consistency.
  static Future<void> _updateStatusEverywhereImpl({
    required dynamic ref,
    required FeedItem feedItem,
    bool? isSaved,
    bool? isLiked,
    int? likeCount,
    String? collectionName,
    FeedType? skipFeedType,
    String? specificCollection,
    bool updateCache = true,
  }) async {

    getNotifier(feedType, ref) {
      return ref is Ref ? feedType.getNotifierWithRef(ref) : feedType.getNotifier(ref);
    }
    readState(feedType, ref) {
      return ref is Ref ? feedType.readWithRef(ref) : feedType.read(ref);
    }

    // Update user state first to maintain consistency
    final User? currentUser = ref.read(userProvider);
    if (currentUser == null) {
      log('[FeedStateService] ❌ User not available, skipping user state update');
      return;
    }
    
    final newTotalSaved = isSaved == true ? currentUser.totalSaved + 1 : isSaved == false ? currentUser.totalSaved - 1 : currentUser.totalSaved;
    final newTotalLiked = isLiked == true ? currentUser.totalLiked + 1 : isLiked == false ? currentUser.totalLiked - 1 : currentUser.totalLiked;
    await ref.read(userProvider.notifier).setValue(currentUser.copyWith(
      totalSaved: max(0, newTotalSaved),
      totalLiked: max(0, newTotalLiked),
    ));
    if (isSaved != null) {
      log('[FeedStateService] 💾 Updated user totalSaved: $newTotalSaved (save: $isSaved)');
    }
    if (isLiked != null) {
      log('[FeedStateService] ❤️ Updated user totalLiked: $newTotalLiked (like: $isLiked)');
      // Calculate like count once to ensure consistency across all feed types
      likeCount ??= isLiked ? feedItem.likeCount + 1 : max(0, feedItem.likeCount - 1);
      log('[FeedStateService] ❤️ Calculated likeCount for ${feedItem.id}: $likeCount');
    }

    // Update the item in all feed types
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = getNotifier(feedType, ref);
      final currentState = readState(feedType, ref);
      final List<FeedItem> matchedItems = currentState.items?.where((item) => item.id == feedItem.id).toList() ?? <FeedItem>[];
      final FeedItem? currentItem = matchedItems.isEmpty ? null : matchedItems.first;
      
      // Check if item needs updating (saved status, liked status, or collection name changed)
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
      if (isSaved != null) {
        await _updateFeedItemsCache(cache, 'feed/saved', feedItem, isSaved, queryParams: queryParams);
        // log('[FeedStateService] 💾 Updated saved feeds cache: ${isSaved ? 'added' : 'removed'} item ${feedItem.id} ${specificCollection != null ? 'to/from "$specificCollection"' : '(all)'}');
      }
      if (isLiked != null) {
        await _updateFeedItemsCache(cache, 'feed/liked', feedItem, isLiked);
        // log('[FeedStateService] ❤️ Updated liked feeds cache: ${isLiked ? 'added' : 'removed'} item ${feedItem.id}');
      }
    } else {
      log('[FeedStateService] ⏸️ Skipping cache update for item ${feedItem.id} (updateCache=false)');
    }

    // if (isSaved != null && specificCollection != null) {
    //   // Also update the general "All Saved" cache
    //   await _updateStatusEverywhereImpl(
    //     ref: ref,
    //     feedItem: feedItem,
    //     isSaved: isSaved,
    //     isLiked: null,
    //     skipFeedType: skipFeedType,
    //     updateCache: updateCache,
    //   );
    // }
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
