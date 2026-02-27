import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/shared_preferences.dart';
import 'package:muslimdigest/utils/secure_feed_cache.dart';

// Provider for feed cache
final feedCacheProvider = Provider<SecureFeedCache>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SecureFeedCache(secureStorage);
});
