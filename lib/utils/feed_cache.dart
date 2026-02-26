import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/utils/repository.dart';

/// Cache entry with expiration metadata
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
  
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'etag': etag,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return CacheEntry<T>(
      data: fromJson(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt: DateTime.parse(json['expiresAt']),
      etag: json['etag'],
    );
  }
}

/// Feed cache configuration
class FeedCacheConfig {
  final Duration defaultTtl;
  final Duration shortTtl;
  final Duration longTtl;
  final int maxCacheSize;

  const FeedCacheConfig({
    this.defaultTtl = const Duration(minutes: 5),
    this.shortTtl = const Duration(minutes: 2),
    this.longTtl = const Duration(minutes: 15),
    this.maxCacheSize = 100,
  });
}

/// Feed cache utility for managing cached feed data with expiration
class FeedCache {
  FeedCache(this._repository, this._config);

  final PreferencesRepository _repository;
  final FeedCacheConfig _config;

  /// Generate cache key for endpoint with parameters
  String _generateCacheKey(String endpoint, Map<String, String>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return 'cache:$endpoint';
    }
    
    final sortedParams = Map.fromEntries(
      queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    final paramString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return 'cache:$endpoint:$paramString';
  }

  /// Determine TTL based on endpoint and parameters
  Duration _getTtlForEndpoint(String endpoint, Map<String, String>? queryParams) {
    // Shorter TTL for real-time feeds
    if (endpoint == 'feed') {
      return _config.shortTtl;
    }
    
    // Longer TTL for static content
    if (endpoint.contains('trending') || endpoint.contains('saved')) {
      return _config.longTtl;
    }
    
    return _config.defaultTtl;
  }

  /// Get cached feed items if valid
  Future<List<FeedItem>?> getCachedFeed(String endpoint, {Map<String, String>? queryParams}) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams);
    final cacheJson = _repository.getJson(cacheKey);
    
    if (cacheJson == null) return null;

    try {
      final cacheEntry = CacheEntry<List<dynamic>>.fromJson(
        cacheJson,
        (data) => List<dynamic>.from(data),
      );

      if (cacheEntry.isExpired) {
        await _repository.remove(cacheKey);
        return null;
      }

      // Convert cached data back to FeedItem objects
      final feedItems = cacheEntry.data
          .map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
          .toList();

      return feedItems;
    } catch (e) {
      // Remove corrupted cache entry
      await _repository.remove(cacheKey);
      return null;
    }
  }

  /// Cache feed items with expiration
  Future<void> setCachedFeed(
    String endpoint,
    List<FeedItem> items, {
    Map<String, String>? queryParams,
    String? etag,
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams);
    final ttl = _getTtlForEndpoint(endpoint, queryParams);
    
    final cacheEntry = CacheEntry<List<dynamic>>(
      data: items.map((item) => item.toJson()).toList(),
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(ttl),
      etag: etag,
    );

    await _repository.setJson(cacheKey, cacheEntry.toJson());
  }

  /// Invalidate cache for specific endpoint
  Future<void> invalidateCache(String endpoint, {Map<String, String>? queryParams}) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams);
    await _repository.remove(cacheKey);
  }

  /// Invalidate all cache entries for an endpoint (all parameter combinations)
  Future<void> invalidateAllCacheForEndpoint(String endpoint) async {
    // This is a simplified approach - in production you might want to track cache keys
    // For now, we'll clear common cache key patterns
    final keys = [
      'cache:$endpoint',
      'cache:$endpoint:',
    ];
    
    for (final key in keys) {
      await _repository.remove(key);
    }
  }

  /// Clear all feed cache
  Future<void> clearAllCache() async {
    // Remove all cache entries with 'cache:' prefix
    // Note: This is a simplified approach - SharedPreferences doesn't support prefix deletion
    // In production, you might want to maintain a registry of cache keys
    final commonEndpoints = ['feed', 'feed/trending', 'feed/latest', 'feed/liked', 'feed/saved'];
    
    for (final endpoint in commonEndpoints) {
      await invalidateAllCacheForEndpoint(endpoint);
    }
  }

  /// Check if cache is stale and needs refresh
  Future<bool> isCacheStale(String endpoint, {Map<String, String>? queryParams}) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams);
    final cacheJson = _repository.getJson(cacheKey);
    
    if (cacheJson == null) return true;

    try {
      final cacheEntry = CacheEntry<List<dynamic>>.fromJson(
        cacheJson,
        (data) => List<dynamic>.from(data),
      );

      return cacheEntry.isExpired;
    } catch (e) {
      return true;
    }
  }

  /// Get cache metadata for debugging
  Future<Map<String, dynamic>?> getCacheMetadata(String endpoint, {Map<String, String>? queryParams}) async {
    final cacheKey = _generateCacheKey(endpoint, queryParams);
    final cacheJson = _repository.getJson(cacheKey);
    
    if (cacheJson == null) return null;

    try {
      final cacheEntry = CacheEntry<List<dynamic>>.fromJson(
        cacheJson,
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
}

// Provider for feed cache
final feedCacheProvider = Provider<FeedCache>((ref) {
  final repository = ref.watch(preferencesRepositoryProvider);
  const config = FeedCacheConfig(
    defaultTtl: Duration(minutes: 5),
    shortTtl: Duration(minutes: 2),
    longTtl: Duration(minutes: 15),
    maxCacheSize: 100,
  );
  
  return FeedCache(repository, config);
});
