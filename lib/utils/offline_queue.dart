import 'dart:convert';
import 'dart:developer' show log;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:uuid/uuid.dart';
import 'package:muslimdigest/services/api.dart';

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
  static const String _queueKey = 'offline_api_queue';
  static const int _maxRetries = 5;
  static const int _initialRetryDelay = 5000; // 5 seconds
    
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

  /// Add a request to the offline queue
  static Future<void> queueRequest({
    required String method,
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final queue = await _getQueue();
      
      final request = QueuedRequest(
        id: const Uuid().v4(),
        method: method.toUpperCase(),
        endpoint: endpoint,
        data: data,
        timestamp: DateTime.now(),
      );

      queue.add(request);
      await _saveQueue(queue);
      
      log('[OfflineQueue] Queued ${request.method} ${request.endpoint} (ID: ${request.id})');
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

        try {
          log('[OfflineQueue] Processing ${request.method} ${request.endpoint} (Attempt ${request.retryCount + 1})');
          
          final response = await executeRequest(request.method, request.endpoint, request.data);
          
          if (response.success) {
            processedCount++;
            log('[OfflineQueue] ✅ Successfully processed ${request.method} ${request.endpoint}');
          } else {
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
      final queueJson = prefs.getStringList(_queueKey) ?? [];
      
      return queueJson
          .map((json) => QueuedRequest.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      log('[OfflineQueue] Error getting queue: $e');
      return [];
    }
  }

  /// Save queue to SharedPreferences
  static Future<void> _saveQueue(List<QueuedRequest> queue) async {
    try {
      final queueJson = queue.map((req) => jsonEncode(req.toJson())).toList();
      await prefs.setStringList(_queueKey, queueJson);
    } catch (e) {
      log('[OfflineQueue] Error saving queue: $e');
    }
  }

  /// Clear all queued requests
  static Future<void> clearQueue() async {
    try {
      await prefs.remove(_queueKey);
      log('[OfflineQueue] Queue cleared');
    } catch (e) {
      log('[OfflineQueue] Error clearing queue: $e');
    }
  }

  /// Get queue statistics
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

      return {
        'total': queue.length,
        'readyToRetry': readyToRetry,
        'waitingForRetry': waitingForRetry,
      };
    } catch (e) {
      log('[OfflineQueue] Error getting queue stats: $e');
      return {'total': 0, 'readyToRetry': 0, 'waitingForRetry': 0};
    }
  }
}

