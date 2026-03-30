// ===============================
// OFFLINE QUEUE RETRY CONFIGURATION
// ===============================

/// Offline queue retry configuration
class OfflineQueueConfig {
  /// Maximum number of retry attempts for failed requests
  static const int maxRetries = 5;
  
  /// Initial delay before first retry (in milliseconds)
  static const int initialRetryDelayMs = 5000;
  
  /// Queue storage key for SharedPreferences
  static const String storageKey = 'offline_api_queue';
}

// ===============================
// CIRCUIT BREAKER CONFIGURATION
// ===============================

/// Default circuit breaker configuration
class CircuitBreakerConfig {
  /// Number of consecutive failures before circuit breaker trips
  static const int failureThreshold = 3;
  
  /// Time to wait before attempting recovery (circuit breaker opens)
  static const Duration recoveryTimeout = Duration(minutes: 1);
  
  /// Maximum number of requests allowed in half-open state
  static const int halfOpenMaxCalls = 5;
  
  /// Time to wait before automatically resetting inactive circuit breakers
  static const Duration resetTimeout = Duration(minutes: 5);
  
  /// Time to wait before cleaning up inactive circuit breakers
  static const Duration cleanupMaxAge = Duration(days: 7);
}

// ===============================
// PATTERN DETECTION CONFIGURATION
// ===============================

/// Pattern detection and analysis configuration
class PatternDetectionConfig {
  /// Maximum number of request patterns to keep in history
  static const int maxHistory = 1000;
  
  /// Interval for automatic pattern optimization
  static const Duration optimizationInterval = Duration(minutes: 5);
  
  /// Minimum number of patterns needed before analysis
  static const int analysisMinPatterns = 5;
  
  /// Success rate threshold for considering endpoint idempotent
  static const double analysisIdempotentThreshold = 0.9;
  
  /// Consistency threshold for data structure analysis
  static const double analysisConsistencyThreshold = 0.8;
}

// ===============================
// LOGGING CONFIGURATION
// ===============================

/// Logging configuration for offline queue system
class LoggingConfig {
  /// Enable detailed logging for offline queue operations
  static const bool enableOfflineQueueVerboseLogging = true;
  
  /// Enable pattern detection logging
  static const bool enablePatternDetectorLogging = true;
  
  /// Enable circuit breaker logging
  static const bool enableCircuitBreakerLogging = true;
}

// ===============================
// PERFORMANCE CONFIGURATION
// ===============================

/// Performance tuning configuration
class PerformanceConfig {
  /// Maximum number of requests to process in a single batch
  static const int offlineQueueBatchSize = 10;
  
  /// Maximum time to spend processing queue in one session
  static const Duration offlineQueueMaxProcessingTime = Duration(minutes: 2);
  
  /// Maximum size for request data (in bytes)
  static const int apiRequestMaxDataSize = 1024 * 1024; // 1MB
  
  /// Maximum number of endpoints to track with circuit breakers
  static const int circuitBreakerMaxEndpoints = 100;
  
  /// Maximum age for queued requests before auto-cleanup
  static const Duration offlineQueueMaxRequestAge = Duration(days: 30);
}

// ===============================
// DEVELOPMENT CONFIGURATION
// ===============================

/// Development and testing configuration
class DevelopmentConfig {
  /// Enable circuit breaker bypass for development
  static const bool circuitBreakerBypassInDev = false;
  
  /// Enable pattern detection bypass for development
  static const bool patternDetectorBypassInDev = false;
  
  /// Force circuit breaker to be always closed (for testing)
  static const bool circuitBreakerForceClosed = false;
}
