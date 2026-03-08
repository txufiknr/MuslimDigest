import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_not_interested.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
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

  /// Update like status across all feed types (Ref version)
  static Future<void> updateLikeStatusEverywhereWithRef(
    Ref ref,
    String feedId,
    bool isLiked, {
    int? likeCount,
    FeedType? skipFeedType,
  }) async {
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = feedType.getNotifierWithRef(ref);
      final currentState = feedType.readWithRef(ref);
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

  /// Update save status across all feed types
  static Future<void> updateSaveStatusEverywhere(
    WidgetRef ref,
    String feedId,
    bool isSaved, {
    FeedType? skipFeedType,
  }) async {
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = feedType.getNotifier(ref);
      final currentState = feedType.read(ref);
      final currentItem = currentState.items?.firstWhereOrNull((item) => item.id == feedId);
      if (currentItem != null && currentItem.isSaved != isSaved) {
        // Update the item in this feed type
        final updatedItems = currentState.items?.map((item) {
          if (item.id == feedId) {
            return item.copyWith(isSaved: isSaved);
          }
          return item;
        }).toList();
        
        await notifier.setValue(updatedItems);
      }
    }
  }

  /// Update save status across all feed types (Ref version)
  static Future<void> updateSaveStatusEverywhereWithRef(
    Ref ref,
    String feedId,
    bool isSaved, {
    FeedType? skipFeedType,
  }) async {
    for (final feedType in FeedType.values) {
      // Skip the specified feed type to avoid circular dependency
      if (skipFeedType != null && feedType == skipFeedType) continue;
      
      final notifier = feedType.getNotifierWithRef(ref);
      final currentState = feedType.readWithRef(ref);
      final currentItem = currentState.items?.firstWhereOrNull((item) => item.id == feedId);
      if (currentItem != null && currentItem.isSaved != isSaved) {
        // Update the item in this feed type
        final updatedItems = currentState.items?.map((item) {
          if (item.id == feedId) {
            return item.copyWith(isSaved: isSaved);
          }
          return item;
        }).toList();
        
        await notifier.setValue(updatedItems);
      }
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
