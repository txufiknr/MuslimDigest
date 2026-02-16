import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seeded via ProviderScope override in main(). Never call directly.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});