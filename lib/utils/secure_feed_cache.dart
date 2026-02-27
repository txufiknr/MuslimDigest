import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:muslimdigest/models/feed.dart';

/// Cache entry with metadata
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final DateTime expiresAt;
  final String? etag;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiresAt,
    this.etag,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return CacheEntry<T>(
      data: fromJson(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt: DateTime.parse(json['expiresAt']),
      etag: json['etag'],
    );
  }

  Map<String, dynamic> toJson(dynamic Function(T) toJson) {
    return {
      'data': toJson(data),
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'etag': etag,
    };
  }
}

/// Secure feed cache implementation using FlutterSecureStorage
class SecureFeedCache {
  final FlutterSecureStorage _storage;
  static const Duration _defaultCacheDuration = Duration(hours: 1);

  SecureFeedCache(this._storage);

  /// Generate cache key for endpoint with optional query parameters
  String _generateCacheKey(String endpoint, {Map<String, String>? queryParams}) {
    if (queryParams == null || queryParams.isEmpty) {
      return 'cache:$endpoint';
    }
    
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
    final cacheJson = await _storage.read(key: cacheKey);
    
    if (cacheJson == null) return null;

    try {
      final cacheEntry = CacheEntry<List<dynamic>>.fromJson(
        jsonDecode(cacheJson),
        (data) => List<dynamic>.from(data),
      );

      if (cacheEntry.isExpired) {
        await _storage.delete(key: cacheKey);
        return null;
      }

      // Convert List<dynamic> to List<FeedItem>
      final feedItems = cacheEntry.data
          .map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return feedItems;
    } catch (e) {
      // If there's an error reading the cache, delete it and return null
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
    final expiresAt = now.add(expiration ?? _defaultCacheDuration);

    // Convert FeedItems to List<dynamic> for JSON serialization
    final itemsData = items.map((item) => item.toJson()).toList();

    final cacheEntry = CacheEntry<List<dynamic>>(
      data: itemsData,
      timestamp: now,
      expiresAt: expiresAt,
      etag: etag,
    );

    try {
      await _storage.write(
        key: cacheKey,
        value: jsonEncode(cacheEntry.toJson((data) => data)),
      );
    } catch (e) {
      // If writing fails, we'll just continue without caching
      log('[SecureFeedCache] Failed to write to secure storage: $e');
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
      final cacheEntry = CacheEntry<List<dynamic>>.fromJson(
        jsonDecode(cacheJson),
        (data) => List<dynamic>.from(data),
      );

      return cacheEntry.isExpired;
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
      final cacheEntry = CacheEntry<List<dynamic>>.fromJson(
        jsonDecode(cacheJson),
        (data) => List<dynamic>.from(data),
      );

      return {
        'timestamp': cacheEntry.timestamp.toIso8601String(),
        'expiresAt': cacheEntry.expiresAt.toIso8601String(),
        'isExpired': cacheEntry.isExpired,
        'etag': cacheEntry.etag,
        'itemCount': cacheEntry.data.length,
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
