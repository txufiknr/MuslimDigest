import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/services/dio.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/feed.dart';

/// Base interface for feed action strategies
abstract class FeedActionStrategy {
  /// Execute the action for the given feed item
  Future<void> execute(WidgetRef ref, FeedItem feed);
  
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
    // Update user liked count immediately
    final currentUser = ref.read(userProvider);
    final newLikedCount = (currentUser.totalLiked - 1).clamp(0, double.infinity).toInt();
    await ref.read(userProvider.notifier).setValue(
      currentUser.copyWith(totalLiked: newLikedCount)
    );
    
    // Update like status across all feed types immediately
    await FeedStateService.updateLikeStatusEverywhere(
      ref, 
      feed.id, 
      false, 
      likeCount: (feed.likeCount - 1).clamp(0, double.infinity).toInt(),
    );
  }
  
  @override
  void makeAPICall(FeedItem feed) {
    fireAndForget(() => ApiService.post('feed/like', {'clusterId': feed.id, 'value': false}));
  }
}

/// Strategy for unsaving a feed item
class UnsaveFeedStrategy extends BaseFeedActionStrategy {
  @override
  String get actionLabel => 'Unsave';
  
  @override
  IconData get actionIcon => CupertinoIcons.bookmark_fill;
  
  @override
  String get actionTooltip => 'Remove from saved feeds';
  
  @override
  Future<void> updateUI(WidgetRef ref, FeedItem feed) async {
    // Update save status across all feed types immediately
    await FeedStateService.updateSaveStatusEverywhere(ref, feed, false);
    
    // Update user saved count immediately
    final currentUser = ref.read(userProvider);
    final newSavedCount = (currentUser.totalSaved - 1).clamp(0, double.infinity).toInt();
    await ref.read(userProvider.notifier).setValue(
      currentUser.copyWith(totalSaved: newSavedCount)
    );
  }
  
  @override
  void makeAPICall(FeedItem feed) {
    fireAndForget(() => ApiService.post('feed/save', {'clusterId': feed.id, 'value': false}));
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
    // This will be implemented in the feed_list_base.dart context
    // since it needs access to the specific provider
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
