import 'dart:developer' show log;
import 'dart:math' show max;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/services/collection_service.dart';
import 'package:muslimdigest/services/dio.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/widgets/collections/collection_selection_sheet.dart';

/// Base interface for feed action strategies
abstract class FeedActionStrategy {
  /// Execute the action for the given feed item
  Future<void> execute(WidgetRef ref, FeedItem feed);
  
  /// Execute long press action for the given feed item
  Future<void> executeLongPress(WidgetRef ref, FeedItem feed, BuildContext context);
  
  /// Get the label for the action button
  String get actionLabel;
  
  /// Get the icon for the action button
  IconData get actionIcon;
  
  /// Get the tooltip text for the action button
  String get actionTooltip;
  
  /// Update UI state immediately (optimistic update)
  Future<void> updateUI(WidgetRef ref, FeedItem feed);
  
  /// Make API call (fire-and-forget)
  void makeAPICall(FeedItem feed);
}

/// Base class with common functionality
abstract class BaseFeedActionStrategy implements FeedActionStrategy {
  @override
  Future<void> execute(WidgetRef ref, FeedItem feed) async {
    // Update UI immediately (optimistic update)
    await updateUI(ref, feed);
    
    // Fire-and-forget API call
    makeAPICall(feed);
  }
  
  @override
  Future<void> executeLongPress(WidgetRef ref, FeedItem feed, BuildContext context) async {
    // Default implementation - do nothing for most strategies
    // Only specific strategies (like UnsaveFeedStrategy) will override this
  }
  
  /// Remove feed item from current provider state
  Future<void> removeFromCurrentFeed(WidgetRef ref, FeedItem feed, FeedType feedType) async {
    // This would need access to the specific provider
    // Implementation depends on how providers are accessed in feed_list_base.dart
  }
}

/// Strategy for unliking a feed item
class UnlikeFeedStrategy extends BaseFeedActionStrategy {
  @override
  String get actionLabel => 'Unlike';
  
  @override
  IconData get actionIcon => CupertinoIcons.heart_fill;
  
  @override
  String get actionTooltip => 'Remove from liked feeds';
  
  @override
  Future<void> updateUI(WidgetRef ref, FeedItem feed) async {
    // Update like status across all feed types immediately, but skip liked feed to avoid circular dependency
    // The liked feed list will be handled by _removeFromCurrentFeed in feed_list_base.dart
    await FeedStateService.updateLikeStatusEverywhere(
      ref, 
      feed, 
      false, 
      likeCount: max(0, feed.likeCount - 1),
      skipFeedType: FeedType.liked,
    );
    
    // Note: totalLiked count is already updated by FeedStateService.updateLikeStatusEverywhere
    // No need for manual update here to avoid double-counting
  }
  
  @override
  void makeAPICall(FeedItem feed) {
    fireAndForget(() => ApiService.post('feed/like', {'clusterId': feed.id, 'value': false}));
  }
}

/// Strategy for unsaving a feed item
class UnsaveFeedStrategy extends BaseFeedActionStrategy {
  String? _cachedCollection; // Cache the collection to avoid re-fetching
  
  @override
  String get actionLabel => 'Unsave';
  
  @override
  IconData get actionIcon => CupertinoIcons.bookmark_fill;
  
  @override
  String get actionTooltip => 'Remove from saved feeds';
  
  @override
  Future<void> executeLongPress(WidgetRef ref, FeedItem feed, BuildContext context) async {
    // Get current collection for this feed
    final currentCollection = await CollectionService.getFeedCollection(ref, feed);
    if (!context.mounted) return;

    // Show collection selection sheet to change collection
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionSelectionSheet(
        feedItem: feed,
        isSaved: feed.isSaved,
        currentCollection: currentCollection,
        onCollectionSelected: (newCollection) {
          _updateFeedCollection(ref, feed, newCollection, context);
        },
        onUnsave: () {
          _unsaveFeed(ref, feed, context);
        },
      ),
    );
  }
  
  void _unsaveFeed(WidgetRef ref, FeedItem feed, BuildContext context) async {
    try {
      // Execute normal unsave action
      await updateUI(ref, feed);
      makeAPICall(feed);
      
      // Update collection name to null across all feed types
      await FeedStateService.updateCollectionNameEverywhere(
        ref, 
        feed, 
        null, // Set collectionName to null when un-saving
        skipFeedType: FeedType.saved, // Skip saved feed to avoid circular dependency
        updateCache: true,
      );
      
      if (context.mounted) {
        showSnackBarSuccess(context, 'Removed from saved feeds');
      }
      log('[UnsaveFeedStrategy] ✅ Unsaved feed "${feed.id}"');
    } catch (e) {
      log('[UnsaveFeedStrategy] ❌ Unsave failed: $e');
      if (context.mounted) {
        showSnackBarError(context, 'Failed to unsave feed');
      }
    }
  }
  
  void _updateFeedCollection(WidgetRef ref, FeedItem feed, String collection, BuildContext context) async {
    try {
      fireAndForget(() => updateCollection(feed.id, collection));
      
      // Update collection name across all feed types using new method
      await FeedStateService.updateCollectionNameEverywhere(
        ref, 
        feed, 
        collection,
        skipFeedType: FeedType.saved, // Skip saved feed to avoid circular dependency
        updateCache: true,
      );

      if (context.mounted) {
        showSnackBarSuccess(context, 'Moved to "$collection"');
      }
      log('[UnsaveFeedStrategy] ✅ Moved to collection "$collection"');
    } catch (e) {
      log('[UnsaveFeedStrategy] ❌ Move to collection failed: $e');
      if (context.mounted) {
        showSnackBarError(context, 'Failed to move to collection');
      }
    }
  }
  
  @override
  Future<void> updateUI(WidgetRef ref, FeedItem feed) async {
    // Cache the collection for later use in makeAPICall
    _cachedCollection = await CollectionService.getFeedCollection(ref, feed);
    
    // Update save status across all feed types immediately, but skip saved feed to avoid circular dependency
    // The saved feed list will be handled by _removeFromCurrentFeed in feed_list_base.dart
    await FeedStateService.updateSaveStatusEverywhere(
      ref, 
      feed, 
      false, 
      skipFeedType: FeedType.saved,
    );
    
    // Remove from all collections using centralized service
    await CollectionService.removeFromAllCollections(ref, feed);
    
    // Note: totalSaved count is already updated by FeedStateService.updateSaveStatusEverywhere
    // No need for manual update here to avoid double-counting
  }
  
  @override
  void makeAPICall(FeedItem feed) {
    fireAndForget(() => ApiService.post('feed/save', {
      'clusterId': feed.id, 
      'value': false,
      if (_cachedCollection != null) 'collection': _cachedCollection,
    }));
  }
}

/// Strategy for deleting feed from history
class DeleteHistoryStrategy extends BaseFeedActionStrategy {
  @override
  String get actionLabel => 'Delete';
  
  @override
  IconData get actionIcon => CupertinoIcons.delete;
  
  @override
  String get actionTooltip => 'Remove from history';
  
  @override
  Future<void> updateUI(WidgetRef ref, FeedItem feed) async {
    // History items are typically only in the history feed, so no cross-feed updates needed
    // The current provider state will be handled by _removeFromCurrentFeed in feed_list_base.dart
    // This is intentional - history deletion is a simple removal operation
  }
  
  @override
  void makeAPICall(FeedItem feed) {
    fireAndForget(() => deleteHistory(feed.id));
  }
}

/// Strategy for unmarking feed as not interested
class UnmarkNotInterestedStrategy extends BaseFeedActionStrategy {
  @override
  String get actionLabel => 'Undo';
  
  @override
  IconData get actionIcon => CupertinoIcons.refresh;
  
  @override
  String get actionTooltip => 'Undo not interested';
  
  @override
  Future<void> updateUI(WidgetRef ref, FeedItem feed) async {
    // Unmark feed as not interested across all feed types
    // Note: The not interested feed list doesn't remove items, so no circular dependency issue
    await FeedStateService.unmarkNotInterestedEverywhere(ref, feed.id);
  }
  
  @override
  void makeAPICall(FeedItem feed) {
    fireAndForget(() => unmarkNotInterested(feed.id));
  }
}

/// Factory for getting the appropriate strategy for each feed type
class FeedActionStrategyFactory {
  static final Map<FeedType, FeedActionStrategy> _strategies = {
    FeedType.liked: UnlikeFeedStrategy(),
    FeedType.saved: UnsaveFeedStrategy(),
    FeedType.history: DeleteHistoryStrategy(),
    FeedType.notInterested: UnmarkNotInterestedStrategy(),
  };
  
  static FeedActionStrategy? getStrategy(FeedType feedType) {
    return _strategies[feedType];
  }
  
  static bool hasAction(FeedType feedType) {
    return _strategies.containsKey(feedType);
  }
  
  static List<FeedType> get supportedFeedTypes => _strategies.keys.toList();
}
