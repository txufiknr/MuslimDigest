import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:muslimdigest/models/feed.dart';

/// Secure feed cache implementation using FlutterSecureStorage
class SecureFeedCache {
  final FlutterSecureStorage _storage;
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const Duration _digestCacheDuration = Duration(hours: 36);

  SecureFeedCache(this._storage);

  /// Generate cache key for endpoint with optional query parameters
  String _generateCacheKey(String endpoint, {Map<String, String>? queryParams}) {
    if (queryParams == null || queryParams.isEmpty) {
      return 'cache:$endpoint';
    }
    
    // Sort parameters for consistent keys
    final sortedParams = Map.fromEntries(
      queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return 'cache:$endpoint:$queryString';
  }

  /// Get cached feed items
  Future<List<FeedItem>?> getFeedItems(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams: queryParams);
    log('[SecureFeedCache] Getting cache for key: $cacheKey');
    final cacheJson = await _storage.read(key: cacheKey);
    
    if (cacheJson == null) {
      log('[SecureFeedCache] Cache miss for key: $cacheKey');
      return null;
    }

    try {
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      log('[SecureFeedCache] Cache data structure: ${cacheData.keys}');
      
      final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);
      
      if (DateTime.now().isAfter(expiresAt)) {
        log('[SecureFeedCache] Cache expired for key: $cacheKey');
        await _storage.delete(key: cacheKey);
        return null;
      }

      final itemsData = cacheData['data'] as List<dynamic>;
      log('[SecureFeedCache] Cache hit for key: $cacheKey, items: ${itemsData.length}');
      // log('[SecureFeedCache] Sample cache data: ${itemsData.take(1).toList()}');
      
      // Convert List<dynamic> to List<FeedItem>
      final feedItems = itemsData
          .map((item) {
            // log('[SecureFeedCache] Parsing item: $item');
            return FeedItem.fromJson(item as Map<String, dynamic>);
          })
          .toList();
      
      return feedItems;
    } catch (e, stackTrace) {
      log('[SecureFeedCache] Parse error for key: $cacheKey, invalidating cache. Error: $e');
      log('[SecureFeedCache] Stack trace: $stackTrace');
      log('[SecureFeedCache] Cache content was: $cacheJson');
      // If there's a parse error, delete the cache and return null
      await _storage.delete(key: cacheKey);
      return null;
    }
  }

  /// Cache feed items with metadata
  Future<void> setFeedItems(
    String endpoint,
    List<FeedItem> items, {
    Map<String, String>? queryParams,
    Duration? expiration,
    String? etag,
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams: queryParams);
    final now = DateTime.now();
    
    // Use 36-hour cache for digest feed (endpoint: 'feed'), otherwise use default or provided expiration
    final cacheDuration = expiration ?? (endpoint == 'feed' ? _digestCacheDuration : _defaultCacheDuration);
    final expiresAt = now.add(cacheDuration);

    log('[SecureFeedCache] Setting cache for key: $cacheKey, items: ${items.length}, expires: $expiresAt');

    // Convert FeedItems to List<dynamic> for JSON serialization
    final itemsData = items.map((item) => item.toJson()).toList();
    // log('[SecureFeedCache] Sample item being cached: ${itemsData.take(1).toList()}');

    final cacheData = {
      'data': itemsData,
      'timestamp': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'etag': etag,
    };

    log('[SecureFeedCache] Cache data structure being saved: ${cacheData.keys}');

    try {
      await _storage.write(
        key: cacheKey,
        value: jsonEncode(cacheData),
      );
      log('[SecureFeedCache] Cache set successfully for key: $cacheKey');
    } catch (e) {
      // If writing fails, we'll just continue without caching
      log('[SecureFeedCache] Failed to write to secure storage for key: $cacheKey, error: $e');
    }
  }

  /// Check if cache is stale (expired or doesn't exist)
  Future<bool> isCacheStale(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams: queryParams);
    final cacheJson = await _storage.read(key: cacheKey);
    
    if (cacheJson == null) return true;

    try {
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
      return true;
    }
  }

  /// Get cache metadata for debugging
  Future<Map<String, dynamic>?> getCacheMetadata(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams: queryParams);
    final cacheJson = await _storage.read(key: cacheKey);
    
    if (cacheJson == null) return null;

    try {
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      final itemsData = cacheData['data'] as List<dynamic>;
      final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);

      return {
        'timestamp': timestamp.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isExpired': DateTime.now().isAfter(expiresAt),
        'etag': cacheData['etag'],
        'itemCount': itemsData.length,
      };
    } catch (e) {
      return null;
    }
  }

  /// Invalidate cache for specific endpoint
  Future<void> invalidateCache(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams: queryParams);
    await _storage.delete(key: cacheKey);
  }

  /// Invalidate all cache for a specific endpoint (all query parameters)
  Future<void> invalidateAllCacheForEndpoint(String endpoint) async {
    // Get all keys that start with 'cache:$endpoint'
    final allKeys = await _storage.readAll();
    final keysToDelete = allKeys.keys
        .where((key) => key.startsWith('cache:$endpoint'))
        .toList();

    for (final key in keysToDelete) {
      await _storage.delete(key: key);
    }
  }

  /// Clear all feed cache
  Future<void> clearAllCache() async {
    final allKeys = await _storage.readAll();
    final cacheKeys = allKeys.keys
        .where((key) => key.startsWith('cache:'))
        .toList();

    for (final key in cacheKeys) {
      await _storage.delete(key: key);
    }
  }

  /// Get cache size estimate (in bytes)
  Future<int> getCacheSize() async {
    final allKeys = await _storage.readAll();
    final cacheKeys = allKeys.keys
        .where((key) => key.startsWith('cache:'))
        .toList();

    int totalSize = 0;
    for (final key in cacheKeys) {
      final value = allKeys[key];
      if (value != null) {
        totalSize += key.length + value.length;
      }
    }

    return totalSize;
  }

  /// Get all cache keys for debugging
  Future<List<String>> getAllCacheKeys() async {
    final allKeys = await _storage.readAll();
    return allKeys.keys
        .where((key) => key.startsWith('cache:'))
        .toList();
  }
}
