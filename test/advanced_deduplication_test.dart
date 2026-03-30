import 'dart:developer' show log;
import 'package:muslimdigest/utils/offline_queue/offline_queue.dart';
import 'package:muslimdigest/utils/offline_queue/conflict_detection_engine.dart';

/// Comprehensive test suite for advanced deduplication strategies
class AdvancedDeduplicationTest {
  static Future<void> runAllTests() async {
    log('[AdvancedDeduplicationTest] Starting comprehensive test suite...');
    
    // Clear any existing queue
    await OfflineQueueService.clearQueue();
    
    // Test all deduplication strategies
    await _testExactMatchStrategy();
    await _testResourceBasedStrategy();
    await _testLastWriteWinsStrategy();
    await _testNoDeduplicationStrategy();
    await _testCrossEndpointConflicts();
    await _testComplexScenarios();
    await _testPerformance();
    
    log('[AdvancedDeduplicationTest] ✅ All tests completed successfully');
  }
  
  static Future<void> _testExactMatchStrategy() async {
    log('[AdvancedDeduplicationTest] Testing exact match strategy...');
    
    await OfflineQueueService.clearQueue();
    
    // Test identical requests
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'analytics/log',
      data: {'event': 'click', 'timestamp': '12345'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'analytics/log',
      data: {'event': 'click', 'timestamp': '12345'}, // Identical
    );
    
    // Should keep both since analytics uses 'none' strategy
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 2, 'Expected 2 items for analytics (no deduplication)');
    
    // Test with different data
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'analytics/log',
      data: {'event': 'scroll', 'timestamp': '12346'}, // Different
    );
    
    stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 3, 'Expected 3 items when data differs');
    
    log('[AdvancedDeduplicationTest] ✅ Exact match strategy test passed');
  }
  
  static Future<void> _testResourceBasedStrategy() async {
    log('[AdvancedDeduplicationTest] Testing resource-based strategy...');
    
    await OfflineQueueService.clearQueue();
    
    // Test same feed, different operations
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-123', 'value': true, 'collection': 'A'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-123', 'value': true, 'collection': 'B'}, // Same feed, different collection
    );
    
    // Should only keep the latest (resource-based deduplication)
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 1, 'Expected 1 item after resource-based deduplication');
    
    // Test different feeds
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-456', 'value': true, 'collection': 'A'}, // Different feed
    );
    
    stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 2, 'Expected 2 items for different feeds');
    
    // Test different methods on same resource
    await OfflineQueueService.queueRequest(
      method: 'DELETE',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-123', 'value': false}, // Same feed, different method
    );
    
    stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 2, 'Expected 2 items (DELETE replaces POST for same resource)');
    
    log('[AdvancedDeduplicationTest] ✅ Resource-based strategy test passed');
  }
  
  static Future<void> _testLastWriteWinsStrategy() async {
    log('[AdvancedDeduplicationTest] Testing last-write-wins strategy...');
    
    await OfflineQueueService.clearQueue();
    
    // Simulate multiple profile updates for same user
    await OfflineQueueService.queueRequest(
      method: 'PUT',
      endpoint: 'user/profile',
      data: {'userId': 'user-123', 'name': 'John', 'email': 'john@example.com'},
    );
    
    // Add a small delay to ensure different timestamps
    await Future.delayed(Duration(milliseconds: 10));
    
    await OfflineQueueService.queueRequest(
      method: 'PUT',
      endpoint: 'user/profile',
      data: {'userId': 'user-123', 'name': 'John Updated', 'email': 'john@new.com'},
    );
    
    await Future.delayed(Duration(milliseconds: 10));
    
    await OfflineQueueService.queueRequest(
      method: 'PUT',
      endpoint: 'user/profile',
      data: {'userId': 'user-123', 'name': 'John Final', 'email': 'john@final.com'},
    );
    
    // Should only keep the newest
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 1, 'Expected 1 item after last-write-wins deduplication');
    
    // Verify it's the newest
    var queue = await OfflineQueueService.getQueue();
    var profileRequests = queue.where((r) => r.endpoint == 'user/profile').toList();
    assert(profileRequests.length == 1, 'Expected 1 profile request');
    assert(profileRequests.first.data['name'] == 'John Final', 'Expected newest profile update');
    
    log('[AdvancedDeduplicationTest] ✅ Last-write-wins strategy test passed');
  }
  
  static Future<void> _testNoDeduplicationStrategy() async {
    log('[AdvancedDeduplicationTest] Testing no deduplication strategy...');
    
    await OfflineQueueService.clearQueue();
    
    // Test search operations (should not be deduplicated)
    await OfflineQueueService.queueRequest(
      method: 'GET',
      endpoint: 'search',
      data: {'query': 'islam', 'page': 1},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'GET',
      endpoint: 'search',
      data: {'query': 'islam', 'page': 1}, // Identical
    );
    
    await OfflineQueueService.queueRequest(
      method: 'GET',
      endpoint: 'search',
      data: {'query': 'islam', 'page': 2}, // Different page
    );
    
    // Should keep all (no deduplication)
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 3, 'Expected 3 items for search (no deduplication)');
    
    log('[AdvancedDeduplicationTest] ✅ No deduplication strategy test passed');
  }
  
  static Future<void> _testCrossEndpointConflicts() async {
    log('[AdvancedDeduplicationTest] Testing cross-endpoint conflicts...');
    
    await OfflineQueueService.clearQueue();
    
    // Test operations on same resource across different endpoints
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-789', 'value': true, 'collection': 'A'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/like',
      data: {'clusterId': 'feed-789', 'value': true}, // Same feed, different endpoint
    );
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/not-interested',
      data: {'clusterId': 'feed-789', 'value': true, 'reason': 'not-relevant'}, // Same feed, different endpoint
    );
    
    // Should keep all since they're different endpoints
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 3, 'Expected 3 items for different endpoints');
    
    log('[AdvancedDeduplicationTest] ✅ Cross-endpoint conflicts test passed');
  }
  
  static Future<void> _testComplexScenarios() async {
    log('[AdvancedDeduplicationTest] Testing complex real-world scenarios...');
    
    await OfflineQueueService.clearQueue();
    
    // Scenario 1: User performs multiple rapid operations on same feed
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-complex', 'value': true, 'collection': 'Reading List'},
    );
    
    await Future.delayed(Duration(milliseconds: 5));
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/like',
      data: {'clusterId': 'feed-complex', 'value': true},
    );
    
    await Future.delayed(Duration(milliseconds: 5));
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-complex', 'value': true, 'collection': 'Favorites'}, // Moved to different collection
    );
    
    await Future.delayed(Duration(milliseconds: 5));
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-complex', 'value': false}, // Unsaved
    );
    
    // Should have: like operation + latest save operation (unsaved)
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 2, 'Expected 2 items in complex scenario');
    
    // Scenario 2: Multiple users updating profiles
    await OfflineQueueService.queueRequest(
      method: 'PUT',
      endpoint: 'user/profile',
      data: {'userId': 'user-1', 'name': 'User 1 Updated'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'PUT',
      endpoint: 'user/profile',
      data: {'userId': 'user-2', 'name': 'User 2 Updated'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'PUT',
      endpoint: 'user/profile',
      data: {'userId': 'user-1', 'name': 'User 1 Final'}, // User 1 updates again
    );
    
    // Should have: latest for user-1 + user-2's update
    stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 4, 'Expected 4 items after multi-user scenario');
    
    // Verify conflict statistics
    final conflictStats = ConflictDetectionEngine.getConflictStats(await OfflineQueueService.getQueue());
    assert(conflictStats['resourceConflicts']['user/profile'] != null, 'Expected resource conflicts for user/profile');
    
    log('[AdvancedDeduplicationTest] ✅ Complex scenarios test passed');
  }
  
  static Future<void> _testPerformance() async {
    log('[AdvancedDeduplicationTest] Testing performance with large queue...');
    
    await OfflineQueueService.clearQueue();
    
    final stopwatch = Stopwatch()..start();
    
    // Add many requests with conflicts
    for (int i = 0; i < 100; i++) {
      await OfflineQueueService.queueRequest(
        method: 'POST',
        endpoint: 'feed/save',
        data: {'clusterId': 'feed-${i % 10}', 'value': true, 'collection': 'Collection $i'},
      );
    }
    
    stopwatch.stop();
    
    final stats = await OfflineQueueService.getQueueStats();
    final duration = stopwatch.elapsedMilliseconds;
    
    // Should only have 10 items (one per unique feed)
    assert(stats['total'] == 10, 'Expected 10 items after deduplication');
    assert(duration < 1000, 'Expected processing to complete in under 1 second, took ${duration}ms');
    
    log('[AdvancedDeduplicationTest] ✅ Performance test passed (${duration}ms for 100 requests)');
  }
}
