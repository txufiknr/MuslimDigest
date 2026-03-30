import 'dart:developer' show log;

import 'package:muslimdigest/api/collections.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/utils/secure_feed_cache.dart';

/// Centralized service for managing feed collections
/// Provides consistent collection operations across the app
class CollectionService {
  
  /// Get the collection name that a feed item belongs to
  /// Returns null if feed is not in any collection
  static Future<String?> getFeedCollection(dynamic ref, FeedItem feed) async {
    try {
      // Early return if collectionName is already available from backend
      if (feed.collectionName != null) {
        return feed.collectionName;
      }
      
      // Fallback to searching through collections if not available
      final collections = await CollectionApi.getCollections();
      
      for (final collection in collections) {
        final SecureFeedCache cache = ref.read(feedCacheProvider);
        final collectionItems = await cache.getFeedItems('feed/saved', queryParams: {'collection': collection});
        
        if (collectionItems != null && collectionItems.any((item) => item.id == feed.id)) {
          return collection;
        }
      }
      
      return null;
    } catch (e) {
      log('[CollectionService] ❌ Error getting feed collection: $e');
      return null;
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
      await FeedStateService.updateSaveStatusEverywhere(
        ref,
        feed,
        true,
        specificCollection: collection,
        updateCache: true,
      );
      log('[CollectionService] ✅ Added feed ${feed.id} to collection "$collection"');
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
