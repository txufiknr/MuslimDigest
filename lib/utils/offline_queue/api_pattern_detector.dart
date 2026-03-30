import 'dart:developer' show log;
import 'package:muslimdigest/utils/offline_queue/deduplication_config.dart';
import 'package:muslimdigest/config/offline_queue.dart' as config;
import 'package:muslimdigest/config/api.dart' as api;

/// API request pattern detection and caching system
/// 
/// This service automatically analyzes API requests to detect patterns
/// and suggest optimal deduplication strategies for the offline queue.
class ApiPatternDetector {
  static const int _maxPatternHistory = config.PatternDetectionConfig.maxHistory;
  static const Set<String> _knownEndpoints = api.ApiEndpoints.allEndpoints;
  
  static final List<ApiRequestPattern> _patternHistory = [];
  static final Map<String, EndpointAnalysis> _endpointAnalysis = {};
  
  /// Record an API request for pattern analysis
  static void recordRequest({
    required String method,
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, String>? queryParams,
    bool success = true,
    int? statusCode,
  }) {
    final pattern = ApiRequestPattern(
      method: method.toUpperCase(),
      endpoint: endpoint,
      data: data,
      queryParams: queryParams ?? {},
      timestamp: DateTime.now(),
      success: success,
      statusCode: statusCode,
    );
    
    // Add to history (maintain size limit)
    _patternHistory.add(pattern);
    if (_patternHistory.length > _maxPatternHistory) {
      _patternHistory.removeAt(0);
    }
    
    // Update endpoint analysis
    _updateEndpointAnalysis(endpoint, pattern);
    
    // Log pattern detection for debugging
    if (_patternHistory.length % 50 == 0) {
      _logPatternStats();
    }
  }
  
  /// Get deduplication strategy suggestion for an endpoint
  static DeduplicationStrategy suggestStrategy(String endpoint) {
    final analysis = _endpointAnalysis[endpoint];
    if (analysis == null) {
      // For unknown endpoints, analyze recent patterns
      return _analyzeUnknownEndpoint(endpoint);
    }
    
    // Based on analysis, suggest strategy
    if (analysis.isIdempotent && analysis.hasConsistentDataStructure) {
      if (analysis.uniqueResourceFields.isNotEmpty) {
        return DeduplicationStrategy.resourceBased;
      } else if (analysis.frequentExactDuplicates) {
        return DeduplicationStrategy.exact;
      }
    }
    
    if (analysis.isWriteOperation && analysis.lastWriteWinsMakesSense) {
      return DeduplicationStrategy.lastWriteWins;
    }
    
    return DeduplicationStrategy.none;
  }
  
  /// Get resource field suggestions for an endpoint
  static List<String> suggestResourceFields(String endpoint) {
    final analysis = _endpointAnalysis[endpoint];
    if (analysis == null) return [];
    
    return analysis.uniqueResourceFields;
  }
  
  /// Get conflict field suggestions for an endpoint
  static List<String> suggestConflictFields(String endpoint) {
    final analysis = _endpointAnalysis[endpoint];
    if (analysis == null) return [];
    
    return analysis.conflictFields;
  }
  
  /// Check if different methods should be allowed to conflict
  static bool suggestAllowDifferentMethods(String endpoint) {
    final analysis = _endpointAnalysis[endpoint];
    if (analysis == null) return false;
    
    return analysis.methodVariations > 1;
  }
  
  /// Generate automatic deduplication config for endpoint
  static EndpointDeduplicationConfig generateConfig(String endpoint) {
    final strategy = suggestStrategy(endpoint);
    final resourceFields = suggestResourceFields(endpoint);
    final conflictFields = suggestConflictFields(endpoint);
    final allowDifferentMethods = suggestAllowDifferentMethods(endpoint);
    
    return EndpointDeduplicationConfig(
      strategy: strategy,
      resourceFields: resourceFields,
      conflictFields: conflictFields,
      allowDifferentMethods: allowDifferentMethods,
    );
  }
  
  /// Update endpoint analysis with new pattern
  static void _updateEndpointAnalysis(String endpoint, ApiRequestPattern pattern) {
    final analysis = _endpointAnalysis.putIfAbsent(
      endpoint, 
      () => EndpointAnalysis(endpoint: endpoint)
    );
    
    analysis.addPattern(pattern);
  }
  
  /// Analyze unknown endpoint based on recent patterns
  static DeduplicationStrategy _analyzeUnknownEndpoint(String endpoint) {
    final recentPatterns = _patternHistory
        .where((p) => p.endpoint == endpoint)
        .take(20)
        .toList();
    
    if (recentPatterns.isEmpty) return DeduplicationStrategy.none;
    
    // Check for write operations with consistent resource IDs
    final writeOperations = recentPatterns.where((p) => 
      ['POST', 'PUT', 'DELETE'].contains(p.method)
    ).toList();
    
    if (writeOperations.isNotEmpty) {
      // Look for consistent field patterns
      final fieldFrequency = <String, int>{};
      for (final pattern in writeOperations) {
        for (final field in pattern.data.keys) {
          fieldFrequency[field] = (fieldFrequency[field] ?? 0) + 1;
        }
      }
      
      // If there's a consistent ID field, suggest resource-based
      final idFields = fieldFrequency.entries
          .where((e) => e.value >= writeOperations.length * 0.8)
          .map((e) => e.key)
          .where((key) => key.toLowerCase().contains('id'))
          .toList();
      
      if (idFields.isNotEmpty) {
        return DeduplicationStrategy.resourceBased;
      }
      
      // If exact duplicates are common, suggest exact match
      final exactDuplicates = _countExactDuplicates(writeOperations);
      if (exactDuplicates > writeOperations.length * 0.3) {
        return DeduplicationStrategy.exact;
      }
    }
    
    return DeduplicationStrategy.none;
  }
  
  /// Count exact duplicates in patterns
  static int _countExactDuplicates(List<ApiRequestPattern> patterns) {
    int duplicates = 0;
    final seen = <String>{};
    
    for (final pattern in patterns) {
      final signature = _getPatternSignature(pattern);
      if (seen.contains(signature)) {
        duplicates++;
      } else {
        seen.add(signature);
      }
    }
    
    return duplicates;
  }
  
  /// Generate unique signature for pattern comparison
  static String _getPatternSignature(ApiRequestPattern pattern) {
    final dataHash = _hashMap(pattern.data);
    final queryHash = _hashMap(pattern.queryParams);
    return '${pattern.method}:${pattern.endpoint}:$dataHash:$queryHash';
  }
  
  /// Simple hash function for maps
  static String _hashMap(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    final pairs = sortedKeys.map((key) => '$key=${map[key]}').join(',');
    return pairs.hashCode.toString();
  }
  
  /// Log pattern statistics for debugging
  static void _logPatternStats() {
    log('[ApiPatternDetector] Pattern Statistics:');
    log('  Total patterns recorded: ${_patternHistory.length}');
    log('  Endpoints analyzed: ${_endpointAnalysis.length}');
    
    for (final entry in _endpointAnalysis.entries) {
      final analysis = entry.value;
      log('  ${entry.key}: ${analysis.totalPatterns} patterns, '
          'strategy: ${suggestStrategy(entry.key)}');
    }
  }
  
  /// Get comprehensive analysis report
  static Map<String, dynamic> getAnalysisReport() {
    return {
      'totalPatterns': _patternHistory.length,
      'endpointsAnalyzed': _endpointAnalysis.length,
      'knownEndpoints': _knownEndpoints,
      'endpointAnalysis': _endpointAnalysis.map((k, v) => MapEntry(k, v.toJson())),
      'suggestedConfigs': _knownEndpoints.map((endpoint) {
        final config = generateConfig(endpoint);
        return MapEntry(endpoint, {
          'strategy': config.strategy.toString(),
          'resourceFields': config.resourceFields,
          'conflictFields': config.conflictFields,
          'allowDifferentMethods': config.allowDifferentMethods,
        });
      }),
    };
  }
}

/// Represents a single API request pattern
class ApiRequestPattern {
  final String method;
  final String endpoint;
  final Map<String, dynamic> data;
  final Map<String, String> queryParams;
  final DateTime timestamp;
  final bool success;
  final int? statusCode;
  
  ApiRequestPattern({
    required this.method,
    required this.endpoint,
    required this.data,
    required this.queryParams,
    required this.timestamp,
    required this.success,
    this.statusCode,
  });
  
  Map<String, dynamic> toJson() => {
    'method': method,
    'endpoint': endpoint,
    'data': data,
    'queryParams': queryParams,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'statusCode': statusCode,
  };
}

/// Analysis data for a specific endpoint
class EndpointAnalysis {
  final String endpoint;
  int totalPatterns = 0;
  int successCount = 0;
  int methodVariations = 0;
  final Set<String> methods = {};
  final Set<String> dataFields = {};
  final Map<String, int> fieldFrequency = {};
  bool isWriteOperation = false;
  bool isIdempotent = false;
  bool hasConsistentDataStructure = false;
  bool frequentExactDuplicates = false;
  bool lastWriteWinsMakesSense = false;
  List<String> uniqueResourceFields = [];
  List<String> conflictFields = [];
  
  EndpointAnalysis({required this.endpoint});
  
  void addPattern(ApiRequestPattern pattern) {
    totalPatterns++;
    
    if (pattern.success) successCount++;
    
    // Track method variations
    if (!methods.contains(pattern.method)) {
      methods.add(pattern.method);
      methodVariations++;
    }
    
    // Track data fields
    for (final field in pattern.data.keys) {
      dataFields.add(field);
      fieldFrequency[field] = (fieldFrequency[field] ?? 0) + 1;
    }
    
    // Analyze characteristics after enough data
    if (totalPatterns >= config.PatternDetectionConfig.analysisMinPatterns) {
      _analyzeCharacteristics();
    }
  }
  
  void _analyzeCharacteristics() {
    // Check if it's a write operation
    isWriteOperation = methods.any((m) => ['POST', 'PUT', 'DELETE'].contains(m));
    
    // Check for idempotency (high success rate)
    isIdempotent = successCount / totalPatterns > config.PatternDetectionConfig.analysisIdempotentThreshold;
    
    // Check for consistent data structure
    hasConsistentDataStructure = fieldFrequency.values.every((count) => 
      count / totalPatterns > config.PatternDetectionConfig.analysisConsistencyThreshold
    );
    
    // Identify potential resource fields
    uniqueResourceFields = fieldFrequency.entries
        .where((e) => e.key.toLowerCase().contains('id'))
        .where((e) => e.value / totalPatterns > config.PatternDetectionConfig.analysisConsistencyThreshold)
        .map((e) => e.key)
        .toList();
    
    // Set conflict fields (same as resource fields for now)
    conflictFields.addAll(uniqueResourceFields);
    
    // Check if last-write-wins makes sense
    lastWriteWinsMakesSense = isWriteOperation && 
        uniqueResourceFields.isNotEmpty && 
        methodVariations > 1;
  }
  
  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'totalPatterns': totalPatterns,
    'successCount': successCount,
    'methodVariations': methodVariations,
    'methods': methods.toList(),
    'dataFields': dataFields.toList(),
    'fieldFrequency': fieldFrequency,
    'isWriteOperation': isWriteOperation,
    'isIdempotent': isIdempotent,
    'hasConsistentDataStructure': hasConsistentDataStructure,
    'uniqueResourceFields': uniqueResourceFields,
    'conflictFields': conflictFields,
  };
}
