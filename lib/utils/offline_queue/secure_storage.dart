import 'dart:convert';
import 'dart:developer' show log;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/config/offline_queue.dart' as config;

/// Secure storage service for offline queue data
/// 
/// This service provides a secure way to store sensitive offline queue data
/// using flutter_secure_storage with fallback to shared_preferences for migration.
class OfflineQueueSecureStorage {
  /// Get shared secure storage instance from global variables
  static FlutterSecureStorage get _secureStorage => secureStorage;

  /// Storage key for migration tracking
  static const String _migrationKey = 'offline_queue_migrated_to_secure';

  /// Read queue data from secure storage with fallback to shared_preferences
  static Future<List<String>?> readQueueData(String key) async {
    try {
      // Try secure storage first
      final secureData = await _secureStorage.read(key: key);
      if (secureData != null) {
        // Data is stored as JSON string, decode to list
        final decoded = jsonDecode(secureData) as List<dynamic>;
        return decoded.cast<String>();
      }

      // Fallback to shared_preferences for migration
      await _migrateFromSharedPreferences(key);
      
      // Try secure storage again after migration
      final migratedData = await _secureStorage.read(key: key);
      if (migratedData != null) {
        final decoded = jsonDecode(migratedData) as List<dynamic>;
        return decoded.cast<String>();
      }

      return null;
    } catch (e) {
      log('[OfflineQueueSecureStorage] Error reading queue data: $e');
      // Fallback to shared_preferences on error
      try {
        return prefs.getStringList(key);
      } catch (fallbackError) {
        log('[OfflineQueueSecureStorage] Fallback also failed: $fallbackError');
        return null;
      }
    }
  }

  /// Write queue data to secure storage
  static Future<bool> writeQueueData(String key, List<String> value) async {
    try {
      // Encode list as JSON string for secure storage
      final encodedData = jsonEncode(value);
      await _secureStorage.write(key: key, value: encodedData);
      
      // Mark migration as complete
      await _secureStorage.write(key: _migrationKey, value: 'true');
      
      // Remove from shared_preferences after successful secure write
      await prefs.remove(key);
      
      return true;
    } catch (e) {
      log('[OfflineQueueSecureStorage] Error writing queue data: $e');
      // Fallback to shared_preferences on error
      try {
        await prefs.setStringList(key, value);
        return true;
      } catch (fallbackError) {
        log('[OfflineQueueSecureStorage] Fallback write also failed: $fallbackError');
        return false;
      }
    }
  }

  /// Remove queue data from both secure storage and shared_preferences
  static Future<bool> removeQueueData(String key) async {
    try {
      await Future.wait([
        _secureStorage.delete(key: key),
        prefs.remove(key),
      ]);
      return true;
    } catch (e) {
      log('[OfflineQueueSecureStorage] Error removing queue data: $e');
      return false;
    }
  }

  /// Check if migration has been completed
  static Future<bool> isMigrationComplete() async {
    try {
      final migrated = await _secureStorage.read(key: _migrationKey);
      return migrated == 'true';
    } catch (e) {
      log('[OfflineQueueSecureStorage] Error checking migration status: $e');
      return false;
    }
  }

  /// Migrate data from shared_preferences to secure storage
  static Future<void> _migrateFromSharedPreferences(String key) async {
    try {
      if (await isMigrationComplete()) {
        log('[OfflineQueueSecureStorage] Migration already completed');
        return;
      }

      final sharedPrefsData = prefs.getStringList(key);
      if (sharedPrefsData != null && sharedPrefsData.isNotEmpty) {
        log('[OfflineQueueSecureStorage] Migrating ${sharedPrefsData.length} queue items to secure storage');
        
        // Write to secure storage
        final encodedData = jsonEncode(sharedPrefsData);
        await _secureStorage.write(key: key, value: encodedData);
        
        // Mark migration as complete
        await _secureStorage.write(key: _migrationKey, value: 'true');
        
        // Remove from shared_preferences after successful migration
        await prefs.remove(key);
        
        log('[OfflineQueueSecureStorage] Migration completed successfully');
      } else {
        // No data to migrate, just mark as complete
        await _secureStorage.write(key: _migrationKey, value: 'true');
        log('[OfflineQueueSecureStorage] No data to migrate, marked as complete');
      }
    } catch (e) {
      log('[OfflineQueueSecureStorage] Migration failed: $e');
      // Don't rethrow, allow fallback to shared_preferences
    }
  }

  /// Get storage statistics for debugging
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final isMigrated = await isMigrationComplete();
      final hasSecureData = await _secureStorage.read(key: config.OfflineQueueConfig.storageKey) != null;
      final hasSharedData = prefs.getStringList(config.OfflineQueueConfig.storageKey) != null;
      
      return {
        'migrationComplete': isMigrated,
        'hasSecureData': hasSecureData,
        'hasSharedData': hasSharedData,
        'storageKey': config.OfflineQueueConfig.storageKey,
      };
    } catch (e) {
      log('[OfflineQueueSecureStorage] Error getting storage stats: $e');
      return {
        'migrationComplete': false,
        'hasSecureData': false,
        'hasSharedData': false,
        'error': e.toString(),
      };
    }
  }

  /// Force migration (for testing or manual migration)
  static Future<void> forceMigration(String key) async {
    try {
      // Reset migration flag
      await _secureStorage.delete(key: _migrationKey);
      
      // Perform migration
      await _migrateFromSharedPreferences(key);
      
      log('[OfflineQueueSecureStorage] Force migration completed');
    } catch (e) {
      log('[OfflineQueueSecureStorage] Force migration failed: $e');
      rethrow;
    }
  }
}
