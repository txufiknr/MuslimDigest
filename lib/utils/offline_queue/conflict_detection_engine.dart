import 'dart:convert';
import 'dart:developer' show log;
import 'package:muslimdigest/utils/offline_queue/offline_queue.dart';
import 'package:muslimdigest/utils/offline_queue/deduplication_config.dart';

/// Advanced conflict detection engine for offline queue deduplication
class ConflictDetectionEngine {
  
  /// Detect and remove conflicting requests from the queue
  /// Returns the filtered queue with conflicts removed
  static List<QueuedRequest> removeConflictingRequests(
    List<QueuedRequest> queue,
    String method,
    String endpoint,
    Map<String, dynamic> data,
  ) {
    final config = DeduplicationConfig.getConfig(endpoint);
    
    switch (config.strategy) {
      case DeduplicationStrategy.none:
        return queue; // No deduplication
        
      case DeduplicationStrategy.exact:
        return _removeExactMatches(queue, method, endpoint, data, config);
        
      case DeduplicationStrategy.resourceBased:
        return _removeResourceConflicts(queue, method, endpoint, data, config);
        
      case DeduplicationStrategy.lastWriteWins:
        return _removeLastWriteWinsConflicts(queue, method, endpoint, data, config);
        
      case DeduplicationStrategy.custom:
        return _removeCustomConflicts(queue, method, endpoint, data, config);
    }
  }
  
  /// Remove exact matches (same endpoint + identical data)
  static List<QueuedRequest> _removeExactMatches(
    List<QueuedRequest> queue,
    String method,
    String endpoint,
    Map<String, dynamic> data,
    EndpointDeduplicationConfig config,
  ) {
    final normalizedData = _normalizeData(data);
    final dataHash = _hashData(normalizedData);
    
    return queue.where((request) {
      // Check if same endpoint
      if (request.endpoint != endpoint) return true;
      
      // Check method compatibility
      if (!config.allowDifferentMethods && request.method != method) return true;
      
      // Check if data is identical
      final requestData = _normalizeData(request.data);
      final requestDataHash = _hashData(requestData);
      
      if (requestDataHash == dataHash) {
        log('[ConflictDetection] Removing exact match: ${request.method} ${request.endpoint}');
        return false; // Remove this request
      }
      
      return true; // Keep this request
    }).toList();
  }
  
  /// Remove resource-based conflicts (same resource identifier)
  static List<QueuedRequest> _removeResourceConflicts(
    List<QueuedRequest> queue,
    String method,
    String endpoint,
    Map<String, dynamic> data,
    EndpointDeduplicationConfig config,
  ) {
    final resourceId = _extractResourceId(data, config.resourceFields);
    if (resourceId == null) return queue; // Can't identify resource, keep all
    
    return queue.where((request) {
      // Check if same endpoint
      if (request.endpoint != endpoint) return true;
      
      // Check method compatibility
      if (!config.allowDifferentMethods && request.method != method) return true;
      
      // Check if same resource
      final requestId = _extractResourceId(request.data, config.resourceFields);
      if (requestId == resourceId) {
        log('[ConflictDetection] Removing resource conflict: ${request.method} ${request.endpoint} for resource $resourceId');
        return false; // Remove this request
      }
      
      return true; // Keep this request
    }).toList();
  }
  
  /// Remove last-write-wins conflicts (same entity, keep newest)
  static List<QueuedRequest> _removeLastWriteWinsConflicts(
    List<QueuedRequest> queue,
    String method,
    String endpoint,
    Map<String, dynamic> data,
    EndpointDeduplicationConfig config,
  ) {
    final resourceId = _extractResourceId(data, config.resourceFields);
    if (resourceId == null) return queue; // Can't identify resource, keep all
    
    // Find all requests for the same resource
    final conflictingRequests = queue.where((request) {
      if (request.endpoint != endpoint) return false;
      if (!config.allowDifferentMethods && request.method != method) return false;
      
      final requestId = _extractResourceId(request.data, config.resourceFields);
      return requestId == resourceId;
    }).toList();
    
    // If no conflicts, return original queue
    if (conflictingRequests.length <= 1) return queue;
    
    // Sort by timestamp (newest first)
    conflictingRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Keep only the newest request
    final newestRequest = conflictingRequests.first;
    final removedCount = conflictingRequests.length - 1;
    
    log('[ConflictDetection] Last-write-wins: keeping newest ${newestRequest.method} ${newestRequest.endpoint}, removed $removedCount older requests');
    
    return queue.where((request) {
      // Keep if not in conflict list or if it's the newest request
      return !conflictingRequests.contains(request) || request.id == newestRequest.id;
    }).toList();
  }
  
  /// Remove custom conflicts (extensible for future needs)
  static List<QueuedRequest> _removeCustomConflicts(
    List<QueuedRequest> queue,
    String method,
    String endpoint,
    Map<String, dynamic> data,
    EndpointDeduplicationConfig config,
  ) {
    // For now, fall back to resource-based
    // This can be extended with custom logic based on customLogicKey
    log('[ConflictDetection] Using fallback resource-based deduplication for $endpoint');
    return _removeResourceConflicts(queue, method, endpoint, data, config);
  }
  
  /// Extract resource identifier from request data
  static String? _extractResourceId(Map<String, dynamic> data, List<String> resourceFields) {
    if (resourceFields.isEmpty) return null;
    
    // Build composite key from all resource fields
    final resourceParts = <String>[];
    for (final field in resourceFields) {
      final value = data[field];
      if (value != null) {
        resourceParts.add(value.toString());
      } else {
        // If any required field is missing, we can't identify the resource
        return null;
      }
    }
    
    return resourceParts.join(':');
  }
  
  /// Normalize request data for comparison (handles ordering, etc.)
  static Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};
    
    // Sort keys and convert all values to strings for consistent comparison
    final sortedKeys = data.keys.toList()..sort();
    for (final key in sortedKeys) {
      normalized[key] = data[key].toString();
    }
    
    return normalized;
  }
  
  /// Generate hash of normalized data for efficient comparison
  static String _hashData(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return jsonString.hashCode.toString();
  }
  
  /// Get conflict statistics for debugging
  static Map<String, dynamic> getConflictStats(List<QueuedRequest> queue) {
    final endpointConflicts = <String, int>{};
    final resourceConflicts = <String, Map<String, int>>{};
    
    for (final request in queue) {
      final endpoint = request.endpoint;
      endpointConflicts[endpoint] = (endpointConflicts[endpoint] ?? 0) + 1;
      
      final config = DeduplicationConfig.getConfig(endpoint);
      if (config.resourceFields.isNotEmpty) {
        final resourceId = _extractResourceId(request.data, config.resourceFields);
        if (resourceId != null) {
          resourceConflicts.putIfAbsent(endpoint, () => <String, int>{});
          resourceConflicts[endpoint]![resourceId] = 
              (resourceConflicts[endpoint]![resourceId] ?? 0) + 1;
        }
      }
    }
    
    return {
      'totalRequests': queue.length,
      'endpointConflicts': endpointConflicts,
      'resourceConflicts': resourceConflicts,
    };
  }
}
