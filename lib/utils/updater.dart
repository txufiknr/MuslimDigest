import 'dart:async';
import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/dialogs.dart';

/// Utility class for handling in-app updates
/// Reduces boilerplate code in UI components
class AppUpdater {
  
  /// Check for in-app updates and handle them appropriately
  /// 
  /// [context] - BuildContext for showing dialogs
  /// [forceCheck] - Force check even in debug mode (default: false)
  static Future<void> checkForAppUpdate(BuildContext context, {bool forceCheck = false}) async {
    try {
      // Skip update checks in debug mode unless forced
      if (kDebugMode && !forceCheck) {
        log('[AppUpdate] Skipping update check in debug mode');
        return;
      }
      
      // Only Android supports in-app updates
      if (!Platform.isAndroid) {
        log('[AppUpdate] In-app updates only supported on Android');
        return;
      }
      
      log('[AppUpdate] Checking for app updates...');
      
      // Check for update availability
      final info = await InAppUpdate.checkForUpdate();
      
      log('[AppUpdate] Update available: ${info.updateAvailability}');
      log('[AppUpdate] Update priority: ${info.updatePriority}');
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Get version info for better user experience
        final packageInfo = await PackageInfo.fromPlatform();
        log('[AppUpdate] Current version: ${packageInfo.version}');
        if (!context.mounted) return;
        
        // Show update dialog based on update priority
        if (info.updatePriority >= 4) { // 4 = high priority
          // For high priority updates, show immediate update
          await _performImmediateUpdate(context);
        } else if (context.mounted) {
          // For flexible updates, show optional update
          await _performFlexibleUpdate(context);
        }
      } else {
        log('[AppUpdate] No update available');
      }
    } catch (e) {
      log('[AppUpdate] Error checking for updates: $e');
      
      // Fallback: Try manual store redirect if in-app update fails
      if (context.mounted && Platform.isAndroid) {
        _showManualUpdateOption(context);
      }
    }
  }

  /// Perform immediate update (for high priority updates)
  static Future<void> _performImmediateUpdate(BuildContext context) async {
    try {
      log('[AppUpdate] Starting immediate update...');
      
      final result = await InAppUpdate.performImmediateUpdate();
      
      if (result == AppUpdateResult.success) {
        log('[AppUpdate] Immediate update successful - app will restart');
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        log('[AppUpdate] User denied immediate update');
        // Show user-friendly message about importance of update
        if (context.mounted) _showUpdateDeniedMessage(context);
      } else {
        log('[AppUpdate] Immediate update failed: $result');
      }
    } catch (e) {
      log('[AppUpdate] Error performing immediate update: $e');
    }
  }

  /// Perform flexible update (for flexible updates)
  static Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      log('[AppUpdate] Starting flexible update...');
      
      final result = await InAppUpdate.startFlexibleUpdate();
      
      if (result == AppUpdateResult.success) {
        log('[AppUpdate] Flexible update download started');
        
        // For flexible updates, we'll check completion after a delay
        // since the stream might not be available in all versions
        if (context.mounted) _checkFlexibleUpdateCompletion(context);
      } else {
        log('[AppUpdate] Failed to start flexible update: $result');
      }
    } catch (e) {
      log('[AppUpdate] Error performing flexible update: $e');
    }
  }

  /// Check flexible update completion periodically
  static void _checkFlexibleUpdateCompletion(BuildContext context) async {
    // Check every 5 seconds for up to 1 minute
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateNotAvailable) {
          log('[AppUpdate] Flexible update completed - restart required');
          if (context.mounted) _showFlexibleUpdateCompleteDialog(context);
          break;
        }
      } catch (e) {
        log('[AppUpdate] Error checking update completion: $e');
      }
    }
  }

  /// Show dialog when flexible update completes
  static void _showFlexibleUpdateCompleteDialog(BuildContext context) {
    showSnackBar(
      context,
      'The app has been updated. Please restart to apply the changes.',
      icon: Icon(CupertinoIcons.arrow_up_circle, color: AppColors.success),
      buttons: [
        TextButton(onPressed: () {
          InAppUpdate.completeFlexibleUpdate();
          // App will restart automatically
        }, child: Text('Restart now')),
      ],
    );
  }

  /// Show manual update option as fallback
  static void _showManualUpdateOption(BuildContext context) {
    showSnackBar(
      context,
      'An update is available. Please visit the Play Store to update.',
      icon: Icon(CupertinoIcons.arrow_up_circle, color: AppColors.primary),
      buttons: [
        TextButton(
          onPressed: () => _openPlayStore(),
          child: Text('Update now'),
        ),
      ],
    );
  }

  /// Show message when user denies critical update
  static void _showUpdateDeniedMessage(BuildContext context) {
    log('[AppUpdate] Critical update was denied by user');
    // Could show a persistent banner or notification here
    showSnackBarWarning(context, 'Critical update was denied. Please update the app to continue using it.');
  }

  /// Open Play Store for manual update
  static void _openPlayStore() {
    log('[AppUpdate] Opening Play Store for manual update');
    openStoreListing();
  }
}
