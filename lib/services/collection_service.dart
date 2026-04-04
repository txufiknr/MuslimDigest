import 'dart:developer' show log;
import 'dart:async' show Completer;

import 'package:muslimdigest/api/collections.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/utils/secure_feed_cache.dart';

/// Centralized service for managing feed collections
/// Provides consistent collection operations across the app
class CollectionService {
  
  /// Cache for collection membership to avoid repeated lookups
  static final Map<String, String?> _collectionMembershipCache = {};
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Synchronization lock for cache operations
  static Completer<void>? _cacheLock;
  
  /// Acquire cache lock for thread-safe operations
  static Future<void> _acquireCacheLock() async {
    while (_cacheLock != null && !_cacheLock!.isCompleted) {
      await _cacheLock!.future;
    }
    _cacheLock = Completer<void>();
  }
  
  /// Release cache lock
  static void _releaseCacheLock() {
    _cacheLock?.complete();
    _cacheLock = null;
  }
  
  /// Get the collection name that a feed item belongs to
  /// Returns null if feed is not in any collection
  static Future<String?> getFeedCollection(dynamic ref, FeedItem feed) async {
    try {
      // Early return if collectionName is already available from backend
      if (feed.collectionName != null) {
        // Validate collection name format
        if (feed.collectionName!.trim().isEmpty) {
          log('[CollectionService] ⚠️ Invalid collection name: empty or whitespace, treating as null');
          return null;
        }
        return feed.collectionName;
      }
      
      // Check cache first
      await _acquireCacheLock();
      try {
        if (_isCacheValid()) {
          final cachedResult = _collectionMembershipCache[feed.id];
          if (cachedResult != null || _collectionMembershipCache.containsKey(feed.id)) {
            return cachedResult;
          }
        }
      } finally {
        _releaseCacheLock();
      }
      
      // Fallback to searching through collections if not available
      final collections = await CollectionApi.getCollections();
      final cache = ref.read(feedCacheProvider);
      
      // Create parallel cache lookups for better performance
      final List<Future<Map<String, String?>>> collectionChecks = [];
      
      for (final collection in collections) {
        collectionChecks.add(_checkCollectionMembership(cache, collection, feed.id));
      }
      
      // Execute all checks in parallel
      final results = await Future.wait(collectionChecks);
      
      // Find the first collection that contains the feed
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result[feed.id] != null) {
          final foundCollection = collections[i];
          
          // Update cache with thread safety
          await _acquireCacheLock();
          try {
            _collectionMembershipCache[feed.id] = foundCollection;
            _cacheTimestamp = DateTime.now();
          } finally {
            _releaseCacheLock();
          }
          
          return foundCollection;
        }
      }
      
      // Update cache with null result (thread-safe)
      await _acquireCacheLock();
      try {
        _collectionMembershipCache[feed.id] = null;
        _cacheTimestamp = DateTime.now();
      } finally {
        _releaseCacheLock();
      }
      
      return null;
    } catch (e) {
      log('[CollectionService] ❌ Error getting feed collection: $e');
      return null;
    }
  }
  
  /// Check if a specific collection contains the feed item
  static Future<Map<String, String?>> _checkCollectionMembership(
    SecureFeedCache cache, 
    String collection, 
    String feedId
  ) async {
    try {
      final collectionItems = await cache.getFeedItems('feed/saved', queryParams: {'collection': collection});
      
      if (collectionItems != null && collectionItems.any((item) => item.id == feedId)) {
        return {feedId: collection};
      }
      
      return {feedId: null};
    } catch (e) {
      log('[CollectionService] ❌ Error checking collection $collection: $e');
      return {feedId: null};
    }
  }
  
  /// Check if the cache is still valid
  static bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry;
  }
  
  /// Clear the collection membership cache
  static Future<void> clearCache() async {
    await _acquireCacheLock();
    try {
      _collectionMembershipCache.clear();
      _cacheTimestamp = null;
      log('[CollectionService] 🗑️ Collection membership cache cleared');
    } finally {
      _releaseCacheLock();
    }
  }

  /// Remove feed item from all collection-specific caches
  /// Used by both BaseFeedNotifier and strategies to avoid code duplication
  static Future<void> removeFromAllCollections(dynamic ref, FeedItem feed) async {
    try {
      // Get all collections
      final collections = await CollectionApi.getCollections();
      
      // Check each collection to see if this feed is in it
      for (final collection in collections) {
        final SecureFeedCache cache = ref.read(feedCacheProvider);
        final collectionItems = await cache.getFeedItems('feed/saved', queryParams: {'collection': collection});
        
        // If the feed is in this collection, remove it
        if (collectionItems != null && collectionItems.any((item) => item.id == feed.id)) {
          // Remove from collection cache directly to avoid circular dependency
          final updatedCollectionItems = collectionItems.where((item) => item.id != feed.id).toList();
          await cache.setFeedItems('feed/saved', updatedCollectionItems, queryParams: {'collection': collection});
          log('[CollectionService] ✨ Removed feed ${feed.id} from collection "$collection"');
        }
      }

      // ALSO remove from general "All Saved" cache
      final SecureFeedCache cache = ref.read(feedCacheProvider);
      final generalCacheItems = await cache.getFeedItems('feed/saved');
      if (generalCacheItems != null && generalCacheItems.any((item) => item.id == feed.id)) {
        final updatedGeneralItems = generalCacheItems.where((item) => item.id != feed.id).toList();
        await cache.setFeedItems('feed/saved', updatedGeneralItems);
      }
      log('[CollectionService] ✨ Removed feed ${feed.id} from saved feeds');
    } catch (e) {
      log('[CollectionService] ❌ Error removing from collections: $e');
    }
  }
  
  /// Add feed item to a specific collection
  static Future<void> addToCollection(dynamic ref, FeedItem feed, String collection) async {
    try {
      // Use the new safe method - no circular dependencies!
      final result = await FeedStateService.updateSaveStatusEverywhereSafe(
        ref: ref,
        feedItem: feed,
        isSaved: true,
        collectionName: collection,
      );
      
      // Apply returned result to update current feed states and cache - DRY!
      await result.applyToAllFeeds(ref, feed.id);
      
      log('[CollectionService] ✅ Added to collection "$collection": ${feed.id}');
    } catch (e) {
      log('[CollectionService] ❌ Error adding to collection: $e');
    }
  }
  
  /// Check if a feed item is in any collection
  static Future<bool> isInAnyCollection(dynamic ref, FeedItem feed) async {
    try {
      final collections = await CollectionApi.getCollections();
      
      for (final collection in collections) {
        final SecureFeedCache cache = ref.read(feedCacheProvider);
        final collectionItems = await cache.getFeedItems('feed/saved', queryParams: {'collection': collection});
        
        if (collectionItems != null && collectionItems.any((item) => item.id == feed.id)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      log('[CollectionService] ❌ Error checking collections: $e');
      return false;
    }
  }
  
  /// Get all collections that contain a specific feed item
  static Future<List<String>> getCollectionsContainingFeed(dynamic ref, FeedItem feed) async {
    try {
      final collections = await CollectionApi.getCollections();
      final containingCollections = <String>[];
      
      for (final collection in collections) {
        final SecureFeedCache cache = ref.read(feedCacheProvider);
        final collectionItems = await cache.getFeedItems('feed/saved', queryParams: {'collection': collection});
        
        if (collectionItems != null && collectionItems.any((item) => item.id == feed.id)) {
          containingCollections.add(collection);
        }
      }
      
      return containingCollections;
    } catch (e) {
      log('[CollectionService] ❌ Error getting collections containing feed: $e');
      return [];
    }
  }
}
