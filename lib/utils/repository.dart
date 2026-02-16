import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Type-safe wrapper around SharedPreferencesWithCache.
/// Handles serialization and provides named accessors per domain.
class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferencesWithCache _prefs;

  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool? getBool(String key) => _prefs.getBool(key);

  /// Returns null if the key is absent or JSON is malformed.
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  List<String>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<String>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setString(String key, String? value) {
    if (value == null) return remove(key);
    return _prefs.setString(key, value);
  }

  Future<void> setInt(String key, int? value) {
    if (value == null) return remove(key);
    return _prefs.setInt(key, value);
  }

  Future<void> setJson(String key, Map<String, dynamic>? value) {
    if (value == null) return remove(key);
    return _prefs.setString(key, jsonEncode(value));
  }

  Future<void> setJsonList(String key, List<String>? value) {
    if (value == null) return remove(key);
    return _prefs.setString(key, jsonEncode(value));
  }

  Future<void> remove(String key) => _prefs.remove(key);
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(ref.watch(sharedPreferencesProvider));
});