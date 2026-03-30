import 'dart:developer' show log;

/// Configuration for deduplication strategies per endpoint
enum DeduplicationStrategy {
  /// No deduplication - keep all requests
  none,
  
  /// Exact match - same endpoint + identical data
  exact,
  
  /// Resource-based - same endpoint + same resource ID
  resourceBased,
  
  /// Last-write-wins - same endpoint + same primary entity
  lastWriteWins,
  
  /// Custom logic defined in endpoint configuration
  custom,
}

/// Configuration for a specific API endpoint's deduplication behavior
class EndpointDeduplicationConfig {
  final DeduplicationStrategy strategy;
  final List<String> resourceFields; // Fields that identify the resource
  final List<String> conflictFields; // Fields that determine if requests conflict
  final bool allowDifferentMethods; // Whether different HTTP methods can conflict
  final String? customLogicKey; // Key for custom deduplication logic
  
  const EndpointDeduplicationConfig({
    required this.strategy,
    this.resourceFields = const [],
    this.conflictFields = const [],
    this.allowDifferentMethods = false,
    this.customLogicKey,
  });
  
  factory EndpointDeduplicationConfig.none() => 
      const EndpointDeduplicationConfig(strategy: DeduplicationStrategy.none);
      
  factory EndpointDeduplicationConfig.exact({
    bool allowDifferentMethods = false,
  }) => EndpointDeduplicationConfig(
    strategy: DeduplicationStrategy.exact,
    allowDifferentMethods: allowDifferentMethods,
  );
      
  factory EndpointDeduplicationConfig.resourceBased({
    required List<String> resourceFields,
    List<String> conflictFields = const [],
    bool allowDifferentMethods = true,
  }) => EndpointDeduplicationConfig(
    strategy: DeduplicationStrategy.resourceBased,
    resourceFields: resourceFields,
    conflictFields: conflictFields,
    allowDifferentMethods: allowDifferentMethods,
  );
      
  factory EndpointDeduplicationConfig.lastWriteWins({
    required List<String> resourceFields,
    List<String> conflictFields = const [],
    bool allowDifferentMethods = true,
  }) => EndpointDeduplicationConfig(
    strategy: DeduplicationStrategy.lastWriteWins,
    resourceFields: resourceFields,
    conflictFields: conflictFields,
    allowDifferentMethods: allowDifferentMethods,
  );
}

/// Central configuration for all endpoint deduplication rules
class DeduplicationConfig {
  static final Map<String, EndpointDeduplicationConfig> _configs = {
    // Feed operations - deduplicate by feed ID (clusterId)
    'feed/save': EndpointDeduplicationConfig.resourceBased(
      resourceFields: ['clusterId'],
      conflictFields: ['clusterId'],
      allowDifferentMethods: true, // POST and PUT can conflict
    ),
    
    'feed/like': EndpointDeduplicationConfig.resourceBased(
      resourceFields: ['clusterId'],
      conflictFields: ['clusterId'],
      allowDifferentMethods: true, // POST only, but allow for future flexibility
    ),
    
    'feed/not_interested': EndpointDeduplicationConfig.resourceBased(
      resourceFields: ['clusterId'],
      conflictFields: ['clusterId'],
      allowDifferentMethods: true, // POST and DELETE can conflict
    ),
    
    'feed/history': EndpointDeduplicationConfig.resourceBased(
      resourceFields: ['clusterId'],
      conflictFields: ['clusterId'],
      allowDifferentMethods: true, // POST and DELETE can conflict
    ),
    
    'feed/saved': EndpointDeduplicationConfig.resourceBased(
      resourceFields: ['clusterId'],
      conflictFields: ['clusterId'],
      allowDifferentMethods: false, // DELETE only, but different actions matter
    ),
    
    // User profile operations - last write wins per data type
    'user': EndpointDeduplicationConfig.lastWriteWins(
      resourceFields: ['endpoint'], // Different user endpoints don't conflict
      conflictFields: ['endpoint'],
      allowDifferentMethods: false,
    ),
    
    'preferences': EndpointDeduplicationConfig.lastWriteWins(
      resourceFields: ['endpoint'],
      conflictFields: ['endpoint'],
      allowDifferentMethods: false,
    ),
    
    'user/reset': EndpointDeduplicationConfig.exact(
      allowDifferentMethods: false,
    ),
    
    // Collection operations - no deduplication for GET (read operations)
    'feed/collections': EndpointDeduplicationConfig.none(),
    
    // Feed reading operations - no deduplication (each read is unique)
    'feed/latest': EndpointDeduplicationConfig.none(),
    'feed/digest': EndpointDeduplicationConfig.none(),
    'feed/trending': EndpointDeduplicationConfig.none(),
    
    // Analytics and logging - no deduplication
    'feed/feedback': EndpointDeduplicationConfig.none(),
    
    // Default configuration for unknown endpoints
    '_default': EndpointDeduplicationConfig.none(),
  };
  
  static EndpointDeduplicationConfig getConfig(String endpoint) {
    return _configs[endpoint] ?? _configs['_default']!;
  }
  
  static void addConfig(String endpoint, EndpointDeduplicationConfig config) {
    // This could be made configurable at runtime if needed
    // For now, this is for development/testing purposes
    log('[DeduplicationConfig] Added config for $endpoint');
  }
  
  /// Get all configured endpoints for debugging
  static Map<String, EndpointDeduplicationConfig> getAllConfigs() {
    return Map.from(_configs);
  }
}
