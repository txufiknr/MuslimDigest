import 'dart:convert';
import 'dart:developer' show log;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:muslimdigest/services/dio.dart';
import 'package:muslimdigest/utils/offline_queue/conflict_detection_engine.dart';
import 'package:muslimdigest/utils/offline_queue/circuit_breaker.dart';
import 'package:muslimdigest/utils/offline_queue/secure_storage.dart';
import 'package:muslimdigest/config/offline_queue.dart' as config;

/// Represents a queued API request for offline processing
class QueuedRequest {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final DateTime? nextRetryAt;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.endpoint,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.nextRetryAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'endpoint': endpoint,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'nextRetryAt': nextRetryAt?.toIso8601String(),
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    id: json['id'],
    method: json['method'],
    endpoint: json['endpoint'],
    data: Map<String, dynamic>.from(json['data']),
    timestamp: DateTime.parse(json['timestamp']),
    retryCount: json['retryCount'] ?? 0,
    nextRetryAt: json['nextRetryAt'] != null 
        ? DateTime.parse(json['nextRetryAt']) 
        : null,
  );

  QueuedRequest copyWith({
    String? id,
    String? method,
    String? endpoint,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    DateTime? nextRetryAt,
  }) {
    return QueuedRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }
}

/// Service for managing offline API requests queue
class OfflineQueueService {
  static const String _queueKey = config.OfflineQueueConfig.storageKey;
  static const int _maxRetries = config.OfflineQueueConfig.maxRetries;
  static const int _initialRetryDelay = config.OfflineQueueConfig.initialRetryDelayMs;
    
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  /// Check if device is currently online
  static Future<bool> isOnline() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return connectivityResults.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      log('[OfflineQueue] Error checking connectivity: $e');
      return false;
    }
  }

  /// Add a request to the offline queue with advanced idempotency protection
  static Future<void> queueRequest({
    required String method,
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final queue = await _getQueue();
      
      // Use advanced conflict detection engine
      final dedupedQueue = ConflictDetectionEngine.removeConflictingRequests(
        queue, method, endpoint, data
      );
      
      final request = QueuedRequest(
        id: const Uuid().v4(),
        method: method.toUpperCase(),
        endpoint: endpoint,
        data: data,
        timestamp: DateTime.now(),
      );

      dedupedQueue.add(request);
      await _saveQueue(dedupedQueue);
      
      log('[OfflineQueue] Queued ${request.method} ${request.endpoint} (ID: ${request.id})');
      if (queue.length != dedupedQueue.length) {
        log('[OfflineQueue] Removed ${queue.length - dedupedQueue.length} conflicting requests');
        
        // Log conflict statistics for debugging
        final conflictStats = ConflictDetectionEngine.getConflictStats(queue);
        log('[OfflineQueue] Conflict stats: $conflictStats');
      }
    } catch (e) {
      log('[OfflineQueue] Error queuing request: $e');
    }
  }

  /// Process all pending requests in the queue
  static Future<int> processQueue({
    required Future<ApiResponse> Function(String method, String endpoint, Map<String, dynamic> data) executeRequest,
  }) async {
    if (!await isOnline()) {
      log('[OfflineQueue] Device offline, skipping queue processing');
      return 0;
    }

    try {
      final queue = await _getQueue();
      
      if (queue.isEmpty) {
        return 0;
      }

      int processedCount = 0;
      final failedRequests = <QueuedRequest>[];
      final now = DateTime.now();

      for (final request in queue) {
        // Check if request is ready for retry
        if (request.nextRetryAt != null && request.nextRetryAt!.isAfter(now)) {
          failedRequests.add(request);
          continue;
        }

        // Check circuit breaker before attempting request
        if (!CircuitBreakerManager.canExecute(request.endpoint)) {
          log('[OfflineQueue] ⚡ Circuit breaker OPEN for ${request.endpoint}, skipping request');
          // Remove the request since circuit breaker is blocking it
          continue;
        }

        try {
          log('[OfflineQueue] Processing ${request.method} ${request.endpoint} (Attempt ${request.retryCount + 1})');
          
          final response = await executeRequest(request.method, request.endpoint, request.data);
          
          if (response.success) {
            processedCount++;
            CircuitBreakerManager.recordSuccess(request.endpoint);
            log('[OfflineQueue] ✅ Successfully processed ${request.method} ${request.endpoint}');
          } else {
            // Request failed, check circuit breaker
            CircuitBreakerManager.recordFailure(request.endpoint);
            
            if (!CircuitBreakerManager.canExecute(request.endpoint)) {
              log('[OfflineQueue] ⚡ Circuit breaker TRIPPED for ${request.endpoint}, removing remaining requests');
              // Remove all other requests for this endpoint due to circuit breaker
              failedRequests.removeWhere((req) => req.endpoint == request.endpoint);
              continue;
            }
            
            // Request failed, calculate next retry time
            final updatedRequest = _calculateNextRetry(request);
            if (updatedRequest.retryCount < _maxRetries) {
              failedRequests.add(updatedRequest);
              log('[OfflineQueue] ⚠️ Request failed, will retry at ${updatedRequest.nextRetryAt}');
            } else {
              log('[OfflineQueue] ❌ Max retries exceeded for ${request.method} ${request.endpoint}');
            }
          }
        } catch (e) {
          // Exception occurred, check circuit breaker
          CircuitBreakerManager.recordFailure(request.endpoint);
          
          if (!CircuitBreakerManager.canExecute(request.endpoint)) {
            log('[OfflineQueue] ⚡ Circuit breaker TRIPPED for ${request.endpoint} due to exception, removing remaining requests');
            // Remove all other requests for this endpoint due to circuit breaker
            failedRequests.removeWhere((req) => req.endpoint == request.endpoint);
            continue;
          }
          
          // Exception occurred, calculate next retry time
          final updatedRequest = _calculateNextRetry(request);
          if (updatedRequest.retryCount < _maxRetries) {
            failedRequests.add(updatedRequest);
            log('[OfflineQueue] ⚠️ Exception occurred, will retry at ${updatedRequest.nextRetryAt}: $e');
          } else {
            log('[OfflineQueue] ❌ Max retries exceeded for ${request.method} ${request.endpoint}: $e');
          }
        }
      }

      // Save remaining failed requests
      await _saveQueue(failedRequests);
      
      log('[OfflineQueue] Processed $processedCount requests, ${failedRequests.length} remaining');
      return processedCount;
    } catch (e) {
      log('[OfflineQueue] Error processing queue: $e');
      return 0;
    }
  }

  /// Calculate next retry time using exponential backoff
  static QueuedRequest _calculateNextRetry(QueuedRequest request) {
    final nextRetryCount = request.retryCount + 1;
    final delayMs = _initialRetryDelay * (1 << (nextRetryCount - 1)); // 2^(n-1)
    final nextRetryAt = DateTime.now().add(Duration(milliseconds: delayMs));
    
    return request.copyWith(
      retryCount: nextRetryCount,
      nextRetryAt: nextRetryAt,
    );
  }

  /// Get all queued requests
  static Future<List<QueuedRequest>> _getQueue() async {
    try {
      final queueJson = await OfflineQueueSecureStorage.readQueueData(_queueKey) ?? [];
      
      final validRequests = <QueuedRequest>[];
      for (final json in queueJson) {
        try {
          // Validate JSON format and content
          if (json.isEmpty || json.length > 10000) { // Reasonable size limit
            log('[OfflineQueue] ⚠️ Skipping invalid queue entry: invalid size');
            continue;
          }
          
          final decoded = jsonDecode(json) as Map<String, dynamic>;
          final request = QueuedRequest.fromJson(decoded);
          
          // Validate request data
          if (_isValidRequest(request)) {
            validRequests.add(request);
          } else {
            log('[OfflineQueue] ⚠️ Skipping invalid request: ${request.endpoint}');
          }
        } catch (e) {
          log('[OfflineQueue] ⚠️ Failed to parse queue entry: $e');
          // Continue with other entries instead of failing completely
        }
      }
      
      return validRequests;
    } catch (e) {
      log('[OfflineQueue] Error getting queue: $e');
      return [];
    }
  }
  
  /// Validate queued request data
  static bool _isValidRequest(QueuedRequest request) {
    // Check required fields
    if (request.id.isEmpty || request.method.isEmpty || request.endpoint.isEmpty) {
      return false;
    }
    
    // Validate HTTP method
    const validMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
    if (!validMethods.contains(request.method.toUpperCase())) {
      return false;
    }
    
    // Validate endpoint format (basic path validation)
    if (request.endpoint.contains('..') || request.endpoint.startsWith('/') || request.endpoint.contains('\x00')) {
      return false;
    }
    
    // Validate data size
    if (request.data.length > 1000000) { // 1MB limit
      return false;
    }
    
    // Validate data keys (prevent injection)
    for (final key in request.data.keys) {
      if (key.contains('\x00') || key.contains('\n') || key.contains('\r')) {
        return false;
      }
    }
    
    return true;
  }

  /// Save queue to secure storage
  static Future<void> _saveQueue(List<QueuedRequest> queue) async {
    try {
      final queueJson = queue.map((req) => jsonEncode(req.toJson())).toList();
      final success = await OfflineQueueSecureStorage.writeQueueData(_queueKey, queueJson);
      if (!success) {
        log('[OfflineQueue] Failed to save queue to secure storage');
      }
    } catch (e) {
      log('[OfflineQueue] Error saving queue: $e');
    }
  }

  /// Clear all queued requests
  static Future<void> clearQueue() async {
    try {
      final success = await OfflineQueueSecureStorage.removeQueueData(_queueKey);
      if (success) {
        log('[OfflineQueue] Queue cleared');
      } else {
        log('[OfflineQueue] Failed to clear queue');
      }
    } catch (e) {
      log('[OfflineQueue] Error clearing queue: $e');
    }
  }

  /// Get queue statistics including circuit breaker and storage information
  static Future<Map<String, dynamic>> getQueueStats() async {
    try {
      final queue = await _getQueue();
      final now = DateTime.now();
      
      final readyToRetry = queue.where((req) => 
        req.nextRetryAt == null || req.nextRetryAt!.isBefore(now)
      ).length;
      
      final waitingForRetry = queue.where((req) => 
        req.nextRetryAt != null && req.nextRetryAt!.isAfter(now)
      ).length;

      // Count collection operations by feed for debugging
      final collectionOps = <String, int>{};
      for (final req in queue) {
        if (req.endpoint == 'feed/save' && req.data.containsKey('clusterId')) {
          final feedId = req.data['clusterId'] as String;
          collectionOps[feedId] = (collectionOps[feedId] ?? 0) + 1;
        }
      }

      // Get circuit breaker statistics
      final circuitBreakerStats = CircuitBreakerManager.getAllStats();
      final openCircuits = CircuitBreakerManager.getOpenCircuits();

      // Get secure storage statistics
      final storageStats = await OfflineQueueSecureStorage.getStorageStats();

      return {
        'total': queue.length,
        'readyToRetry': readyToRetry,
        'waitingForRetry': waitingForRetry,
        'collectionOperations': collectionOps,
        'circuitBreakers': {
          'totalBreakers': circuitBreakerStats['totalBreakers'],
          'openCircuits': openCircuits,
          'openCircuitsCount': openCircuits.length,
          'details': circuitBreakerStats['breakers'],
        },
        'storage': storageStats,
      };
    } catch (e) {
      log('[OfflineQueue] Error getting queue stats: $e');
      return {
        'total': 0, 
        'readyToRetry': 0, 
        'waitingForRetry': 0, 
        'collectionOperations': <String, int>{},
        'circuitBreakers': {
          'totalBreakers': 0,
          'openCircuits': <String>[],
          'openCircuitsCount': 0,
          'details': <String, dynamic>{},
        },
        'storage': {
          'migrationComplete': false,
          'hasSecureData': false,
          'hasSharedData': false,
          'error': e.toString(),
        },
      };
    }
  }

  /// Get all queued requests for a specific feed (for debugging)
  static Future<List<QueuedRequest>> getQueuedRequestsForFeed(String feedId) async {
    try {
      final queue = await _getQueue();
      
      return queue.where((request) => 
        request.endpoint == 'feed/save' && 
        request.data.containsKey('clusterId') && 
        request.data['clusterId'] == feedId
      ).toList();
    } catch (e) {
      log('[OfflineQueue] Error getting queued requests for feed $feedId: $e');
      return [];
    }
  }

  /// Clear all queued requests for a specific feed
  static Future<void> clearRequestsForFeed(String feedId) async {
    try {
      final queue = await _getQueue();
      final filteredQueue = queue.where((request) => 
        !(request.endpoint == 'feed/save' && 
          request.data.containsKey('clusterId') && 
          request.data['clusterId'] == feedId)
      ).toList();
      
      await _saveQueue(filteredQueue);
      log('[OfflineQueue] Cleared ${queue.length - filteredQueue.length} requests for feed $feedId');
    } catch (e) {
      log('[OfflineQueue] Error clearing requests for feed $feedId: $e');
    }
  }

  /// Get the current queue (for testing purposes only)
  static Future<List<QueuedRequest>> getQueue() async {
    return await _getQueue();
  }

  /// Reset circuit breaker for specific endpoint
  static void resetCircuitBreaker(String endpoint) {
    CircuitBreakerManager.resetBreaker(endpoint);
    log('[OfflineQueue] Reset circuit breaker for $endpoint');
  }

  /// Reset all circuit breakers
  static void resetAllCircuitBreakers() {
    CircuitBreakerManager.resetAll();
    log('[OfflineQueue] Reset all circuit breakers');
  }

  /// Get circuit breaker statistics
  static Map<String, dynamic> getCircuitBreakerStats() {
    return CircuitBreakerManager.getAllStats();
  }

  /// Configure circuit breaker settings
  static void configureCircuitBreaker({
    int? failureThreshold,
    Duration? recoveryTimeout,
    int? halfOpenMaxCalls,
    Duration? resetTimeout,
  }) {
    final breakerConfig = CircuitBreakerConfig(
      failureThreshold: failureThreshold ?? config.CircuitBreakerConfig.failureThreshold,
      recoveryTimeout: recoveryTimeout ?? config.CircuitBreakerConfig.recoveryTimeout,
      halfOpenMaxCalls: halfOpenMaxCalls ?? config.CircuitBreakerConfig.halfOpenMaxCalls,
      resetTimeout: resetTimeout ?? config.CircuitBreakerConfig.resetTimeout,
    );
    
    CircuitBreakerManager.setGlobalConfig(breakerConfig);
    log('[OfflineQueue] Circuit breaker configuration updated');
  }

  /// Clean up old circuit breakers
  static void cleanupCircuitBreakers({Duration maxAge = config.CircuitBreakerConfig.cleanupMaxAge}) {
    CircuitBreakerManager.cleanup(maxAge: maxAge);
    log('[OfflineQueue] Cleaned up old circuit breakers');
  }

  /// Force migration from shared_preferences to secure storage
  static Future<void> forceMigrationToSecureStorage() async {
    try {
      log('[OfflineQueue] Forcing migration to secure storage...');
      await OfflineQueueSecureStorage.forceMigration(_queueKey);
      log('[OfflineQueue] Migration to secure storage completed');
    } catch (e) {
      log('[OfflineQueue] Migration to secure storage failed: $e');
      rethrow;
    }
  }

  /// Check if migration to secure storage is complete
  static Future<bool> isSecureStorageMigrationComplete() async {
    try {
      return await OfflineQueueSecureStorage.isMigrationComplete();
    } catch (e) {
      log('[OfflineQueue] Error checking migration status: $e');
      return false;
    }
  }
}

