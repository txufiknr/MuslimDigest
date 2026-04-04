import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/utils/feed_logger.dart';
import 'package:muslimdigest/variables/feed.dart';

/// Result of applying feed updates across all feed types
/// 
/// This class provides detailed information about the success/failure
/// of feed update operations, allowing callers to handle partial failures.
class ApplyResult {
  /// Number of feed types successfully updated
  final int successCount;
  
  /// Number of feed types that failed to update
  final int errorCount;
  
  /// List of error messages for failed updates
  final List<String> errors;
  
  /// Total number of feed types attempted
  final int totalFeedTypes;
  
  /// Whether all updates were successful
  bool get isCompleteSuccess => errorCount == 0;
  
  /// Whether any updates were successful
  bool get hasPartialSuccess => successCount > 0;
  
  /// Success rate as a percentage (0.0 to 1.0)
  double get successRate => totalFeedTypes > 0 ? successCount / totalFeedTypes : 0.0;

  const ApplyResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.totalFeedTypes,
  });

  @override
  String toString() {
    return 'ApplyResult{'
        'successCount: $successCount, '
        'errorCount: $errorCount, '
        'totalFeedTypes: $totalFeedTypes, '
        'isCompleteSuccess: $isCompleteSuccess, '
        'successRate: ${(successRate * 100).toStringAsFixed(1)}%'
        '}';
  }
}

/// Result of a feed update operation that provides all necessary data
/// for the current feed to update its state and cache without circular dependencies.
/// 
/// This class encapsulates the return-based architecture approach where
/// FeedStateService returns data instead of directly updating providers.
class FeedUpdateResult {
  /// The feed item with updated properties
  final FeedItem updatedItem;
  
  /// Updated user statistics (if applicable)
  final UserUpdateResult? userUpdate;
  
  /// Whether the current feed cache needs updating
  final bool needsCacheUpdate;
  
  /// The updated like count (if this was a like operation)
  final int? updatedLikeCount;
  
  /// The collection name (if this was a save operation)
  final String? collectionName;
  
  /// Whether this was a like operation
  final bool isLikeOperation;
  
  /// Whether this was a save operation
  final bool isSaveOperation;

  const FeedUpdateResult({
    required this.updatedItem,
    this.userUpdate,
    this.needsCacheUpdate = true,
    this.updatedLikeCount,
    this.collectionName,
    this.isLikeOperation = false,
    this.isSaveOperation = false,
  });

  /// Create a result for a like operation
  factory FeedUpdateResult.like({
    required FeedItem updatedItem,
    required int likeCount,
    UserUpdateResult? userUpdate,
  }) {
    return FeedUpdateResult(
      updatedItem: updatedItem,
      userUpdate: userUpdate,
      updatedLikeCount: likeCount,
      isLikeOperation: true,
    );
  }

  /// Factory method for save operations
  factory FeedUpdateResult.save({
    required FeedItem updatedItem,
    String? collectionName,
    UserUpdateResult? userUpdate,
  }) {
    return FeedUpdateResult(
      updatedItem: updatedItem,
      userUpdate: userUpdate,
      collectionName: collectionName,
      isSaveOperation: true,
    );
  }

  /// Apply this result to all feed types that contain the updated item
  /// Updates both provider state and cache in one go - DRY solution!
  /// 
  /// This eliminates boilerplate code across the codebase by centralizing
  /// the logic for applying update results to all feed types.
  /// 
  /// **Parameters:**
  /// - [ref] - The Ref or WidgetRef for accessing providers and cache
  /// - [feedId] - The ID of the feed item that was updated
  /// 
  /// **Returns:** Future with error count and success status
  Future<ApplyResult> applyToAllFeeds(dynamic ref, String feedId) async {
    final List<String> errors = [];
    final List<FeedType> successfulFeedTypes = [];
    int successCount = 0;
    
    for (final feedType in FeedType.values) {
      try {
        final notifier = feedType.getNotifier(ref);
        final currentState = feedType.read(ref);
        final List<FeedItem> matchedItems = currentState.items?.where((item) => item.id == feedId).toList() ?? <FeedItem>[];
        
        if (matchedItems.isNotEmpty) {
          // Update state
          final updatedItems = currentState.items?.map((item) {
            if (item.id == feedId) {
              return updatedItem;
            }
            return item;
          }).toList() ?? <FeedItem>[];
          
          await notifier.setValue(updatedItems);
          
          // Update cache with proper error handling
          try {
            final cache = ref.read(feedCacheProvider);
            final queryParams = _getQueryParamsForFeedType(feedType);
            await cache.setFeedItems(feedType.endpoint, updatedItems, queryParams: queryParams);
            
            successfulFeedTypes.add(feedType);
            successCount++;
            FeedLogger.logSuccess('feed update', feedId, details: {'feedType': feedType.name});
          } catch (cacheError) {
            // If cache update fails, invalidate cache to prevent inconsistency
            try {
              final cache = ref.read(feedCacheProvider);
              await cache.invalidateAllCacheForEndpoint(feedType.endpoint);
              FeedLogger.logCacheError('update', feedType.endpoint, cacheError, fallbackAction: 'invalidated cache');
            } catch (invalidateError) {
              FeedLogger.logCacheError('invalidate', feedType.endpoint, invalidateError);
            }
            
            errors.add('[FeedUpdateResult] Cache update failed for $feedType: $cacheError');
            FeedLogger.logError('cache update', feedId, cacheError, context: 'feedType: $feedType');
          }
        }
      } catch (e) {
        final error = '[FeedUpdateResult] ❌ Failed to update $feedType feed for item $feedId: $e';
        errors.add(error);
        FeedLogger.logError('state update', feedId, e, context: 'feedType: $feedType');
        
        // If state update fails, invalidate cache to prevent inconsistency
        try {
          final cache = ref.read(feedCacheProvider);
          await cache.invalidateAllCacheForEndpoint(feedType.endpoint);
          FeedLogger.logWarning('cache invalidated due to state update failure', context: 'feedType: $feedType');
        } catch (invalidateError) {
          FeedLogger.logCacheError('invalidate', feedType.endpoint, invalidateError);
        }
      }
    }
    
    // If we had any failures, consider partial rollback
    if (errors.isNotEmpty && successfulFeedTypes.isNotEmpty) {
      FeedLogger.logPartialFailure(
        'feed update', 
        successCount, 
        FeedType.values.length, 
        errors,
        successfulFeedTypes: successfulFeedTypes.map((type) => type.name).toList(),
      );
      
      // Optionally implement rollback logic here if needed
      // For now, we've invalidated caches to prevent inconsistency
    }
    
    final result = ApplyResult(
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      totalFeedTypes: FeedType.values.length,
    );
    
    if (errors.isNotEmpty) {
      FeedLogger.logWarning('feed update completed with errors', context: '${errors.length} errors out of ${FeedType.values.length} feed types');
    } else {
      FeedLogger.logSuccess('feed update', feedId, details: {'totalFeedTypes': FeedType.values.length, 'successCount': successCount});
    }
    
    return result;
  }

  /// Get the appropriate query parameters for a specific feed type
  /// 
  /// This ensures cache keys match the exact same parameters used when loading the feed
  Map<String, String>? _getQueryParamsForFeedType(FeedType feedType) {
    switch (feedType) {
      case FeedType.saved:
        // For saved feeds, use collection name if available
        return collectionName != null ? {'collection': collectionName!} : null;
      case FeedType.digest:
        // Digest feed uses limit=30 for cache key (based on existing implementation)
        return {'limit': DAILY_READ_TARGET.toString()};
      case FeedType.latest:
        // Latest feed might have topic parameters, but we don't track them here
        // This is a limitation - latest feed cache updates won't work with topic filters
        return null;
      case FeedType.trending:
      case FeedType.liked:
      case FeedType.history:
      case FeedType.notInterested:
        // These feeds don't use query parameters for caching
        return null;
    }
  }

  @override
  String toString() {
    return 'FeedUpdateResult{'
        'updatedItem: ${updatedItem.id}, '
        'needsCacheUpdate: $needsCacheUpdate, '
        'isLikeOperation: $isLikeOperation, '
        'isSaveOperation: $isSaveOperation, '
        'updatedLikeCount: $updatedLikeCount, '
        'collectionName: $collectionName'
        '}';
  }
}

/// Result of user statistics update
class UserUpdateResult {
  /// Updated total saved count
  final int totalSaved;
  
  /// Updated total liked count
  final int totalLiked;
  
  /// Whether user stats actually changed
  final bool hasChanges;

  const UserUpdateResult({
    required this.totalSaved,
    required this.totalLiked,
    required this.hasChanges,
  });

  @override
  String toString() {
    return 'UserUpdateResult{totalSaved: $totalSaved, totalLiked: $totalLiked, hasChanges: $hasChanges}';
  }
}
