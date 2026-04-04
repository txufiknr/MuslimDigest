import 'dart:developer' show log;

/// Centralized logging utility for feed operations
/// 
/// This class provides consistent logging patterns across all feed-related operations,
/// ensuring proper error tracking, debugging information, and operational visibility.
class FeedLogger {
  /// Log successful feed operations
  static void logSuccess(String operation, String feedId, {Map<String, dynamic>? details}) {
    final detailsStr = details != null ? ' | Details: $details' : '';
    log('[FeedLogger] ✅ $operation completed for feed $feedId$detailsStr');
  }
  
  /// Log feed operation failures with context
  static void logError(String operation, String feedId, dynamic error, {String? context}) {
    final contextStr = context != null ? ' | Context: $context' : '';
    log('[FeedLogger] ❌ $operation failed for feed $feedId: $error$contextStr');
  }
  
  /// Log cache operations
  static void logCache(String operation, String endpoint, {Map<String, String>? queryParams, int? itemCount}) {
    final queryStr = queryParams != null ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
    final countStr = itemCount != null ? ' | Items: $itemCount' : '';
    final cacheKey = queryParams != null ? 'cache:$endpoint:${queryParams.entries.map((e) => '${e.key}=${e.value}').join(':')}' : 'cache:$endpoint';
    log('[FeedLogger] 🍪 Cache $operation: $endpoint$queryStr$countStr | CacheKey: $cacheKey');
  }
  
  /// Log cache errors with fallback actions
  static void logCacheError(String operation, String endpoint, dynamic error, {String? fallbackAction, Map<String, String>? queryParams}) {
    final fallbackStr = fallbackAction != null ? ' | Fallback: $fallbackAction' : '';
    final queryStr = queryParams != null ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
    final cacheKey = queryParams != null ? 'cache:$endpoint:${queryParams.entries.map((e) => '${e.key}=${e.value}').join(':')}' : 'cache:$endpoint';
    log('[FeedLogger] ❌ Cache $operation failed for $endpoint$queryStr | Error: $error | CacheKey: $cacheKey$fallbackStr');
  }
  
  /// Log partial failures with success rates
  static void logPartialFailure(String operation, int successCount, int totalCount, List<String> errors, {List<String>? successfulFeedTypes}) {
    final successRate = (successCount / totalCount * 100).toStringAsFixed(1);
    final successTypesStr = successfulFeedTypes != null ? ' | Successful: ${successfulFeedTypes.join(', ')}' : '';
    final errorTypesStr = errors.length > 3 ? ' | First 3 errors: ${errors.take(3).join('; ')}...' : ' | Errors: ${errors.join('; ')}';
    log('[FeedLogger] ⚠️ $operation partial failure: $successCount/$totalCount successful ($successRate%)$successTypesStr$errorTypesStr');
  }
  
  /// Log user state updates
  static void logUserUpdate(String operation, Map<String, dynamic> oldState, Map<String, dynamic> newState) {
    log('[FeedLogger] 👤 User $operation: $oldState → $newState');
  }
  
  /// Log API calls
  static void logApiCall(String method, String endpoint, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' | Data: $data' : '';
    log('[FeedLogger] 🌐 API $method $endpoint$dataStr');
  }
  
  /// Log provider state updates
  static void logProviderUpdate(String providerType, String operation, {int? itemCount, String? feedId}) {
    final countStr = itemCount != null ? ' | Items: $itemCount' : '';
    final feedStr = feedId != null ? ' | Feed: $feedId' : '';
    log('[FeedLogger] 🔄 Provider $providerType $operation$countStr$feedStr');
  }
  
  /// Log collection operations
  static void logCollection(String operation, String feedId, String? collectionName) {
    final collectionStr = collectionName != null ? ' | Collection: $collectionName' : '';
    log('[FeedLogger] 📁 Collection $operation for feed $feedId$collectionStr');
  }
  
  /// Log performance metrics
  static void logPerformance(String operation, Duration duration, {int? itemCount}) {
    final countStr = itemCount != null ? ' | Items: $itemCount' : '';
    log('[FeedLogger] ⏱️ $operation took ${duration.inMilliseconds}ms$countStr');
  }
  
  /// Log warnings
  static void logWarning(String message, {String? context}) {
    final contextStr = context != null ? ' | Context: $context' : '';
    log('[FeedLogger] ⚠️ $message$contextStr');
  }
  
  /// Log debug information
  static void logDebug(String message, {Map<String, dynamic>? details}) {
    final detailsStr = details != null ? ' | Details: $details' : '';
    log('[FeedLogger] 🔍 DEBUG: $message$detailsStr');
  }
}
