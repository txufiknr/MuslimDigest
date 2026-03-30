import 'dart:developer' show log;
import 'package:muslimdigest/utils/offline_queue/deduplication_config.dart';
import 'package:muslimdigest/utils/offline_queue/api_pattern_detector.dart';
import 'package:muslimdigest/config/offline_queue.dart' as config;

/// Automatic deduplication rule discovery and optimization system
/// 
/// This service continuously analyzes API patterns and automatically
/// applies optimal deduplication strategies to the offline queue.
class AutoDeduplicationOptimizer {
  static bool _isOptimizationEnabled = true;
  static Duration _optimizationInterval = config.PatternDetectionConfig.optimizationInterval;
  static DateTime? _lastOptimization;
  
  /// Enable or disable automatic optimization
  static void setOptimizationEnabled(bool enabled) {
    _isOptimizationEnabled = enabled;
    log('[AutoDeduplicationOptimizer] Optimization ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Set optimization interval
  static void setOptimizationInterval(Duration interval) {
    _optimizationInterval = interval;
    log('[AutoDeduplicationOptimizer] Optimization interval set to ${interval.inMinutes} minutes');
  }
  
  /// Run automatic optimization if needed
  static Future<void> runOptimizationIfNeeded() async {
    if (!_isOptimizationEnabled) return;
    
    final now = DateTime.now();
    if (_lastOptimization != null && 
        now.difference(_lastOptimization!) < _optimizationInterval) {
      return; // Not time for optimization yet
    }
    
    await runOptimization();
    _lastOptimization = now;
  }
  
  /// Run comprehensive optimization
  static Future<OptimizationResult> runOptimization() async {
    log('[AutoDeduplicationOptimizer] Starting automatic optimization...');
    
    final result = OptimizationResult();
    
    try {
      // 1. Analyze current patterns
      final analysisReport = ApiPatternDetector.getAnalysisReport();
      result.totalPatternsAnalyzed = analysisReport['totalPatterns'] as int;
      result.endpointsAnalyzed = analysisReport['endpointsAnalyzed'] as int;
      
      // 2. Generate optimal configurations
      final suggestedConfigs = analysisReport['suggestedConfigs'] as Map<String, dynamic>;
      final currentConfigs = DeduplicationConfig.getAllConfigs();
      
      int improvements = 0;
      int newConfigs = 0;
      
      for (final entry in suggestedConfigs.entries) {
        final endpoint = entry.key;
        final suggestedConfig = entry.value as Map<String, dynamic>;
        final currentConfig = currentConfigs[endpoint];
        
        if (currentConfig == null) {
          // New endpoint discovered
          await _addNewEndpointConfig(endpoint, suggestedConfig);
          newConfigs++;
          result.newEndpoints.add(endpoint);
        } else {
          // Check if current config can be improved
          if (_shouldUpdateConfig(currentConfig, suggestedConfig)) {
            await _updateEndpointConfig(endpoint, suggestedConfig);
            improvements++;
            result.improvedEndpoints.add(endpoint);
          }
        }
      }
      
      result.configurationsAdded = newConfigs;
      result.configurationsImproved = improvements;
      
      // 3. Log optimization results
      _logOptimizationResults(result);
      
      log('[AutoDeduplicationOptimizer] ✅ Optimization completed successfully');
      return result;
      
    } catch (e) {
      log('[AutoDeduplicationOptimizer] ❌ Optimization failed: $e');
      result.error = e.toString();
      return result;
    }
  }
  
  /// Add configuration for newly discovered endpoint
  static Future<void> _addNewEndpointConfig(String endpoint, Map<String, dynamic> configData) async {
    final strategy = _parseStrategy(configData['strategy'] as String);
    final resourceFields = (configData['resourceFields'] as List<dynamic>).cast<String>();
    final conflictFields = (configData['conflictFields'] as List<dynamic>).cast<String>();
    final allowDifferentMethods = configData['allowDifferentMethods'] as bool;
    
    final newConfig = EndpointDeduplicationConfig(
      strategy: strategy,
      resourceFields: resourceFields,
      conflictFields: conflictFields,
      allowDifferentMethods: allowDifferentMethods,
    );
    
    DeduplicationConfig.addConfig(endpoint, newConfig);
    log('[AutoDeduplicationOptimizer] Added new config for $endpoint: $strategy');
  }
  
  /// Update existing endpoint configuration
  static Future<void> _updateEndpointConfig(String endpoint, Map<String, dynamic> configData) async {
    // For now, we just log the recommendation
    // In a production system, you might want to apply this automatically
    final strategy = _parseStrategy(configData['strategy'] as String);
    log('[AutoDeduplicationOptimizer] Recommended update for $endpoint: $strategy');
  }
  
  /// Parse strategy from string
  static DeduplicationStrategy _parseStrategy(String strategyString) {
    switch (strategyString) {
      case 'DeduplicationStrategy.none':
        return DeduplicationStrategy.none;
      case 'DeduplicationStrategy.exact':
        return DeduplicationStrategy.exact;
      case 'DeduplicationStrategy.resourceBased':
        return DeduplicationStrategy.resourceBased;
      case 'DeduplicationStrategy.lastWriteWins':
        return DeduplicationStrategy.lastWriteWins;
      case 'DeduplicationStrategy.custom':
        return DeduplicationStrategy.custom;
      default:
        return DeduplicationStrategy.none;
    }
  }
  
  /// Check if current configuration should be updated
  static bool _shouldUpdateConfig(EndpointDeduplicationConfig current, Map<String, dynamic> suggested) {
    // Simple heuristic: if suggested strategy is more specific, update
    final currentStrategyIndex = _getStrategySpecificity(current.strategy);
    final suggestedStrategyIndex = _getStrategySpecificity(_parseStrategy(suggested['strategy'] as String));
    
    return suggestedStrategyIndex > currentStrategyIndex;
  }
  
  /// Get specificity score for strategy (higher = more specific)
  static int _getStrategySpecificity(DeduplicationStrategy strategy) {
    switch (strategy) {
      case DeduplicationStrategy.none:
        return 0;
      case DeduplicationStrategy.exact:
        return 1;
      case DeduplicationStrategy.custom:
        return 2;
      case DeduplicationStrategy.resourceBased:
        return 3;
      case DeduplicationStrategy.lastWriteWins:
        return 4;
    }
  }
  
  /// Log optimization results
  static void _logOptimizationResults(OptimizationResult result) {
    log('[AutoDeduplicationOptimizer] Optimization Results:');
    log('  Patterns analyzed: ${result.totalPatternsAnalyzed}');
    log('  Endpoints analyzed: ${result.endpointsAnalyzed}');
    log('  New configurations: ${result.configurationsAdded}');
    log('  Improved configurations: ${result.configurationsImproved}');
    
    if (result.newEndpoints.isNotEmpty) {
      log('  New endpoints: ${result.newEndpoints.join(', ')}');
    }
    
    if (result.improvedEndpoints.isNotEmpty) {
      log('  Improved endpoints: ${result.improvedEndpoints.join(', ')}');
    }
    
    if (result.error != null) {
      log('  Error: ${result.error}');
    }
  }
  
  /// Get current optimization status
  static Map<String, dynamic> getOptimizationStatus() {
    return {
      'enabled': _isOptimizationEnabled,
      'intervalMinutes': _optimizationInterval.inMinutes,
      'lastOptimization': _lastOptimization?.toIso8601String(),
      'nextOptimization': _lastOptimization?.add(_optimizationInterval).toIso8601String(),
    };
  }
  
  /// Force immediate optimization run
  static Future<OptimizationResult> forceOptimization() async {
    _lastOptimization = null; // Reset timer
    return await runOptimization();
  }
}

/// Result of an optimization run
class OptimizationResult {
  int totalPatternsAnalyzed = 0;
  int endpointsAnalyzed = 0;
  int configurationsAdded = 0;
  int configurationsImproved = 0;
  final List<String> newEndpoints = [];
  final List<String> improvedEndpoints = [];
  String? error;
  
  Map<String, dynamic> toJson() => {
    'totalPatternsAnalyzed': totalPatternsAnalyzed,
    'endpointsAnalyzed': endpointsAnalyzed,
    'configurationsAdded': configurationsAdded,
    'configurationsImproved': configurationsImproved,
    'newEndpoints': newEndpoints,
    'improvedEndpoints': improvedEndpoints,
    'error': error,
    'timestamp': DateTime.now().toIso8601String(),
  };
}
