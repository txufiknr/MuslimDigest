import 'dart:developer' show log;
import 'package:muslimdigest/config/offline_queue.dart' as config;

/// Circuit breaker states for offline queue request processing
enum CircuitBreakerState {
  /// Circuit is closed - requests flow through normally
  closed,
  
  /// Circuit is open - all requests are blocked
  open,
  
  /// Circuit is half-open - limited requests are allowed to test recovery
  halfOpen,
}

/// Circuit breaker configuration
class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration recoveryTimeout;
  final int halfOpenMaxCalls;
  final Duration resetTimeout;
  
  const CircuitBreakerConfig({
    this.failureThreshold = config.CircuitBreakerConfig.failureThreshold,
    this.recoveryTimeout = config.CircuitBreakerConfig.recoveryTimeout,
    this.halfOpenMaxCalls = config.CircuitBreakerConfig.halfOpenMaxCalls,
    this.resetTimeout = config.CircuitBreakerConfig.resetTimeout,
  });
}

/// Circuit breaker for managing offline queue request failures
class CircuitBreaker {
  final String endpoint;
  final CircuitBreakerConfig config;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _halfOpenCalls = 0;
  DateTime? _lastFailureTime;
  DateTime? _nextAttemptTime;
  
  CircuitBreaker({
    required this.endpoint,
    this.config = const CircuitBreakerConfig(),
  });
  
  /// Get current circuit breaker state
  CircuitBreakerState get state => _state;
  
  /// Check if request is allowed through the circuit breaker
  bool canExecute() {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
        
      case CircuitBreakerState.open:
        if (_shouldAttemptReset()) {
          _transitionToHalfOpen();
          return true;
        }
        return false;
        
      case CircuitBreakerState.halfOpen:
        return _halfOpenCalls < config.halfOpenMaxCalls;
    }
  }
  
  /// Record a successful request
  void recordSuccess() {
    switch (_state) {
      case CircuitBreakerState.closed:
        // Reset failure count on success in closed state
        _failureCount = 0;
        break;
        
      case CircuitBreakerState.halfOpen:
        _halfOpenCalls++;
        // If we've had enough successful calls in half-open, close the circuit
        if (_halfOpenCalls >= config.halfOpenMaxCalls) {
          _transitionToClosed();
        }
        break;
        
      case CircuitBreakerState.open:
        // Should not happen, but handle gracefully
        _transitionToClosed();
        break;
    }
  }
  
  /// Record a failed request
  void recordFailure() {
    _lastFailureTime = DateTime.now();
    
    switch (_state) {
      case CircuitBreakerState.closed:
        _failureCount++;
        if (_failureCount >= config.failureThreshold) {
          _transitionToOpen();
        }
        break;
        
      case CircuitBreakerState.halfOpen:
        // Any failure in half-open immediately opens the circuit
        _transitionToOpen();
        break;
        
      case CircuitBreakerState.open:
        // Already open, just update the failure time
        _nextAttemptTime = DateTime.now().add(config.recoveryTimeout);
        break;
    }
  }
  
  /// Force reset the circuit breaker to closed state
  void reset() {
    _transitionToClosed();
  }
  
  /// Check if circuit breaker should attempt reset
  bool _shouldAttemptReset() {
    if (_nextAttemptTime == null) return false;
    return DateTime.now().isAfter(_nextAttemptTime!);
  }
  
  /// Transition to closed state
  void _transitionToClosed() {
    if (_state != CircuitBreakerState.closed) {
      log('[CircuitBreaker] $endpoint: Circuit closed');
    }
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _halfOpenCalls = 0;
    _nextAttemptTime = null;
  }
  
  /// Transition to open state
  void _transitionToOpen() {
    log('[CircuitBreaker] $endpoint: Circuit opened after $_failureCount failures');
    _state = CircuitBreakerState.open;
    _nextAttemptTime = DateTime.now().add(config.recoveryTimeout);
  }
  
  /// Transition to half-open state
  void _transitionToHalfOpen() {
    log('[CircuitBreaker] $endpoint: Circuit half-open - testing recovery');
    _state = CircuitBreakerState.halfOpen;
    _halfOpenCalls = 0;
  }
  
  /// Get circuit breaker statistics
  Map<String, dynamic> getStats() {
    return {
      'endpoint': endpoint,
      'state': _state.toString(),
      'failureCount': _failureCount,
      'halfOpenCalls': _halfOpenCalls,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'nextAttemptTime': _nextAttemptTime?.toIso8601String(),
      'canExecute': canExecute(),
    };
  }
  
  /// Serialize circuit breaker state for persistence
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'state': _state.index,
      'failureCount': _failureCount,
      'halfOpenCalls': _halfOpenCalls,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'nextAttemptTime': _nextAttemptTime?.toIso8601String(),
    };
  }
  
  /// Deserialize circuit breaker state from persistence
  factory CircuitBreaker.fromJson(Map<String, dynamic> json, CircuitBreakerConfig config) {
    final breaker = CircuitBreaker(
      endpoint: json['endpoint'] as String,
      config: config,
    );
    
    breaker._state = CircuitBreakerState.values[json['state'] as int];
    breaker._failureCount = json['failureCount'] as int;
    breaker._halfOpenCalls = json['halfOpenCalls'] as int;
    breaker._lastFailureTime = json['lastFailureTime'] != null 
        ? DateTime.parse(json['lastFailureTime'] as String)
        : null;
    breaker._nextAttemptTime = json['nextAttemptTime'] != null
        ? DateTime.parse(json['nextAttemptTime'] as String)
        : null;
    
    return breaker;
  }
}

/// Manager for multiple circuit breakers
class CircuitBreakerManager {
  static final Map<String, CircuitBreaker> _breakers = {};
  static CircuitBreakerConfig _globalConfig = const CircuitBreakerConfig();
  
  /// Set global circuit breaker configuration
  static void setGlobalConfig(CircuitBreakerConfig config) {
    _globalConfig = config;
    log('[CircuitBreakerManager] Global config updated');
  }
  
  /// Get or create circuit breaker for endpoint
  static CircuitBreaker getBreaker(String endpoint) {
    return _breakers.putIfAbsent(
      endpoint,
      () => CircuitBreaker(endpoint: endpoint, config: _globalConfig),
    );
  }
  
  /// Check if request is allowed through circuit breaker
  static bool canExecute(String endpoint) {
    return getBreaker(endpoint).canExecute();
  }
  
  /// Record successful request
  static void recordSuccess(String endpoint) {
    getBreaker(endpoint).recordSuccess();
  }
  
  /// Record failed request
  static void recordFailure(String endpoint) {
    getBreaker(endpoint).recordFailure();
  }
  
  /// Reset specific circuit breaker
  static void resetBreaker(String endpoint) {
    getBreaker(endpoint).reset();
  }
  
  /// Reset all circuit breakers
  static void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
    log('[CircuitBreakerManager] All circuit breakers reset');
  }
  
  /// Get statistics for all circuit breakers
  static Map<String, dynamic> getAllStats() {
    return {
      'totalBreakers': _breakers.length,
      'globalConfig': {
        'failureThreshold': _globalConfig.failureThreshold,
        'recoveryTimeout': _globalConfig.recoveryTimeout.inMinutes,
        'halfOpenMaxCalls': _globalConfig.halfOpenMaxCalls,
        'resetTimeout': _globalConfig.resetTimeout.inMinutes,
      },
      'breakers': _breakers.map((k, v) => MapEntry(k, v.getStats())),
    };
  }
  
  /// Get list of endpoints with open circuits
  static List<String> getOpenCircuits() {
    return _breakers.entries
        .where((entry) => entry.value.state == CircuitBreakerState.open)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Save circuit breaker states to persistent storage
  static Future<void> saveStates() async {
    try {
      // This would use your preferred storage method
      // final states = _breakers.map((k, v) => MapEntry(k, v.toJson()));
      // await prefs.setString('circuit_breakers', jsonEncode(states));
      
      log('[CircuitBreakerManager] Saved ${_breakers.length} circuit breaker states');
    } catch (e) {
      log('[CircuitBreakerManager] Error saving states: $e');
    }
  }
  
  /// Load circuit breaker states from persistent storage
  static Future<void> loadStates() async {
    try {
      // This would use your preferred storage method
      // final statesJson = prefs.getString(_storageKey);
      // if (statesJson != null) {
      //   final states = jsonDecode(statesJson) as Map<String, dynamic>;
      //   for (final entry in states.entries) {
      //     final breaker = CircuitBreaker.fromJson(entry.value, _globalConfig);
      //     _breakers[entry.key] = breaker;
      //   }
      //   log('[CircuitBreakerManager] Loaded ${_breakers.length} circuit breaker states');
      // }
    } catch (e) {
      log('[CircuitBreakerManager] Error loading states: $e');
    }
  }
  
  /// Clean up old circuit breakers (those not used recently)
  static void cleanup({Duration maxAge = config.CircuitBreakerConfig.cleanupMaxAge}) {
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <String>[];
    
    for (final entry in _breakers.entries) {
      final breaker = entry.value;
      if (breaker._lastFailureTime != null && 
          breaker._lastFailureTime!.isBefore(cutoff) &&
          breaker.state == CircuitBreakerState.closed) {
        toRemove.add(entry.key);
      }
    }
    
    for (final endpoint in toRemove) {
      _breakers.remove(endpoint);
    }
    
    if (toRemove.isNotEmpty) {
      log('[CircuitBreakerManager] Cleaned up ${toRemove.length} inactive circuit breakers');
    }
  }
}
