import 'dart:developer' show log;
import 'package:muslimdigest/utils/offline_queue/offline_queue.dart';

/// Test utility to verify offline queue idempotency
class OfflineQueueTest {
  static Future<void> testIdempotency() async {
    log('[OfflineQueueTest] Starting idempotency test...');
    
    // Clear any existing queue
    await OfflineQueueService.clearQueue();
    
    // Test Case 1: Conflicting save operations
    await _testConflictingSaves();
    
    // Test Case 2: Different feeds should not conflict
    await _testDifferentFeeds();
    
    // Test Case 3: Different endpoints should not conflict
    await _testDifferentEndpoints();
    
    log('[OfflineQueueTest] Idempotency test completed');
  }
  
  static Future<void> _testConflictingSaves() async {
    log('[OfflineQueueTest] Testing conflicting save operations...');
    
    // Simulate saving feed 1 to collection A (API failed, gets queued)
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {
        'clusterId': 'feed-123',
        'value': true,
        'collection': 'Collection A',
      },
    );
    
    // Check queue state
    var stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 1, 'Expected 1 item in queue');
    log('[OfflineQueueTest] ✓ First operation queued');
    
    // Simulate changing feed 1 to collection B (API failed, gets queued)
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {
        'clusterId': 'feed-123',
        'value': true,
        'collection': 'Collection B',
      },
    );
    
    // Check that only the latest operation remains
    stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 1, 'Expected 1 item in queue after deduplication');
    
    final queuedRequests = await OfflineQueueService.getQueuedRequestsForFeed('feed-123');
    assert(queuedRequests.length == 1, 'Expected 1 queued request for feed-123');
    assert(queuedRequests.first.data['collection'] == 'Collection B', 'Expected collection B to remain');
    
    log('[OfflineQueueTest] ✓ Conflicting operations deduplicated correctly');
  }
  
  static Future<void> _testDifferentFeeds() async {
    log('[OfflineQueueTest] Testing operations on different feeds...');
    
    // Clear queue
    await OfflineQueueService.clearQueue();
    
    // Queue operations for different feeds
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-123', 'value': true, 'collection': 'Collection A'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-456', 'value': true, 'collection': 'Collection A'},
    );
    
    // Both should remain since they're different feeds
    final stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 2, 'Expected 2 items in queue for different feeds');
    
    final collectionOps = stats['collectionOperations'] as Map<String, int>;
    assert(collectionOps['feed-123'] == 1, 'Expected 1 operation for feed-123');
    assert(collectionOps['feed-456'] == 1, 'Expected 1 operation for feed-456');
    
    log('[OfflineQueueTest] ✓ Different feeds handled correctly');
  }
  
  static Future<void> _testDifferentEndpoints() async {
    log('[OfflineQueueTest] Testing operations on different endpoints...');
    
    // Clear queue
    await OfflineQueueService.clearQueue();
    
    // Queue operations for different endpoints
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/save',
      data: {'clusterId': 'feed-123', 'value': true, 'collection': 'Collection A'},
    );
    
    await OfflineQueueService.queueRequest(
      method: 'POST',
      endpoint: 'feed/like',
      data: {'clusterId': 'feed-123', 'value': true},
    );
    
    // Both should remain since they're different endpoints
    final stats = await OfflineQueueService.getQueueStats();
    assert(stats['total'] == 2, 'Expected 2 items in queue for different endpoints');
    
    log('[OfflineQueueTest] ✓ Different endpoints handled correctly');
  }
}
