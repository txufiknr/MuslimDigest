import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Seeded via ProviderScope override in main(). Never call directly.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// Seeded via ProviderScope override in main(). Never call directly.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('secureStorageProvider must be overridden in ProviderScope');
});