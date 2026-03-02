import 'dart:async';
import 'dart:developer' show log;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:muslimdigest/services/api.dart';

/// Manages connectivity monitoring and automatic offline queue processing
class ConnectivityMonitor {
  static final ConnectivityMonitor _instance = ConnectivityMonitor._internal();
  factory ConnectivityMonitor() => _instance;
  ConnectivityMonitor._internal();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _isProcessing = false;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    final instance = ConnectivityMonitor();
    await instance._startMonitoring();
  }

  /// Start monitoring connectivity changes
  Future<void> _startMonitoring() async {
    try {
      // Check initial connectivity state
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      
      log('[ConnectivityMonitor] Initial state: ${_isOnline ? "online" : "offline"}');

      // Listen for connectivity changes
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        final newOnlineState = results.any((result) => result != ConnectivityResult.none);
        
        if (_isOnline != newOnlineState) {
          _isOnline = newOnlineState;
          log('[ConnectivityMonitor] Connectivity changed to: ${_isOnline ? "online" : "offline"}');
          
          // If we just came online, process the offline queue
          if (_isOnline && !_isProcessing) {
            _processQueueOnConnectivityRestore();
          }
        }
      });
    } catch (e) {
      log('[ConnectivityMonitor] Error starting monitoring: $e');
    }
  }

  /// Process offline queue when connectivity is restored
  Future<void> _processQueueOnConnectivityRestore() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    try {
      log('[ConnectivityMonitor] Processing offline queue after connectivity restore');
      final processedCount = await ApiService.processOfflineQueue();
      
      if (processedCount > 0) {
        log('[ConnectivityMonitor] ✅ Processed $processedCount offline requests after connectivity restore');
      }
    } catch (e) {
      log('[ConnectivityMonitor] Error processing queue on connectivity restore: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Get current connectivity status
  bool get isOnline => _isOnline;

  /// Stop monitoring connectivity
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    log('[ConnectivityMonitor] Connectivity monitoring stopped');
  }

  /// Manually trigger queue processing (useful for manual sync)
  static Future<int> manualSync() async {
    log('[ConnectivityMonitor] Manual sync triggered');
    return await ApiService.processOfflineQueue();
  }

  /// Get queue statistics
  static Future<Map<String, dynamic>> getQueueStats() async {
    return await ApiService.getQueueStats();
  }

  /// Clear all queued requests
  static Future<void> clearQueue() async {
    await ApiService.clearQueue();
    log('[ConnectivityMonitor] Queue cleared manually');
  }
}
