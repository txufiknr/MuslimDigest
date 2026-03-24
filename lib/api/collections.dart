import 'dart:developer' show log;

import 'package:muslimdigest/services/dio.dart';

/// Collection API service for managing feed collections
class CollectionApi {
  /// Save a feed to a specific collection (or uncategorized)
  /// 
  /// POST /api/feed/save
  /// Body: { "clusterId": "abc", "collection": "Collection Name" }
  /// If collection is null or empty, saves as uncategorized
  static Future<bool> saveToCollection(String clusterId, String? collection) async {
    try {
      final response = await ApiService.post('feed/save', {
        'clusterId': clusterId,
        if (collection != null && collection.isNotEmpty) 'collection': collection,
      });
      
      log('[CollectionApi] Save to collection result: ${response.successful}');
      return response.successful;
    } catch (e) {
      log('[CollectionApi] Error saving to collection: $e');
      return false;
    }
  }

  /// Update the collection for an already saved feed
  /// 
  /// PUT /api/feed/save
  /// Body: { "clusterId": "abc", "collection": "Collection Name" }
  /// If collection is null, moves to uncategorized
  static Future<bool> updateCollection(String clusterId, String? collection) async {
    try {
      final response = await ApiService.put('feed/save', {
        'clusterId': clusterId,
        if (collection != null && collection.isNotEmpty) 'collection': collection,
      });
      
      log('[CollectionApi] Update collection result: ${response.successful}');
      return response.successful;
    } catch (e) {
      log('[CollectionApi] Error updating collection: $e');
      return false;
    }
  }

  /// Get user's saved feeds, optionally filtered by collection
  /// 
  /// GET /api/feed/saved?collection=Collection%20Name
  /// GET /api/feed/saved?collection= (for uncategorized)
  /// GET /api/feed/saved (for all)
  static Future<ApiResponse> getSavedFeeds({String? collection}) async {
    try {
      final queryParams = <String, String>{};
      if (collection != null) {
        queryParams['collection'] = collection;
      }
      
      final response = await ApiService.get('feed/saved', queryParams: queryParams);
      
      log('[CollectionApi] Get saved feeds result: ${response.successful}');
      return response;
    } catch (e) {
      log('[CollectionApi] Error getting saved feeds: $e');
      return ApiResponse(success: false, statusCode: 500, error: e.toString());
    }
  }

  /// Remove a feed from saved items or uncategorize it
  /// 
  /// DELETE /api/feed/saved?clusterId=abc&action=remove (complete removal)
  /// DELETE /api/feed/saved?clusterId=abc&action=uncategorize (uncategorize)
  static Future<bool> removeSavedFeed(String clusterId, {String action = 'remove'}) async {
    try {
      final response = await ApiService.delete('feed/saved?clusterId=$clusterId&action=$action');
      
      log('[CollectionApi] Remove saved feed result: ${response.successful}');
      return response.successful;
    } catch (e) {
      log('[CollectionApi] Error removing saved feed: $e');
      return false;
    }
  }

  /// Get user's collections from saved favorites
  /// 
  /// GET /api/feed/collections
  /// Returns array of collection names from user_favorites table
  static Future<List<String>> getCollections() async {
    try {
      final response = await ApiService.get('feed/collections');
      
      if (response.success && response.data != null) {
        log('[CollectionApi] response.data = ${response.data}');
        return List<String>.from(response.data['items']);
      }
      
      log('[CollectionApi] No collections found or API error');
      return [];
    } catch (e) {
      log('[CollectionApi] Error getting collections: $e');
      // [log] [CollectionApi] Error getting collections: type '_Map<String, dynamic>' is not a subtype of type 'Iterable<dynamic>'
      return [];
    }
  }
}
