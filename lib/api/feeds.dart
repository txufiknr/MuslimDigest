import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/functions.dart';

Future<bool> markRead(String clusterId) async {
  final response = await ApiService.post('feed/history', {'clusterId': clusterId});
  return response.success;
}

Future<bool> like(String clusterId, bool value) async {
  final response = await ApiService.post('feed/like', {'clusterId': clusterId, 'value': value});
  return response.success;
}

Future<bool> save(String clusterId, bool value) async {
  final response = await ApiService.post('feed/save', {'clusterId': clusterId, 'value': value});
  return response.success;
}

Future<bool> deleteHistory(String clusterId) async {
  final response = await ApiService.delete('feed/history?clusterId=$clusterId');
  return response.success;
}

Future<bool> markNotInterested(String clusterId) async {
  final response = await ApiService.post('feed/not_interested', {'clusterId': clusterId});
  return response.success;
}

Future<bool> unmarkNotInterested(String clusterId) async {
  final response = await ApiService.delete('feed/not_interested?clusterId=$clusterId');
  return response.success;
}

Future<ApiResponse> submitFeedback(String clusterId, String category, String message) async {
  return await ApiService.post('feed/feedback', {
    'clusterId': clusterId,
    'category': category,
    'message': message,
  });
}

Future<void> avoidSource(WidgetRef ref, Source source) async {
  final preferences = ref.read(preferencesProvider);
  final updatedAvoidedSources = Set<Source>.from(preferences.avoidedSources)..add(source);
  await ref.read(preferencesProvider.notifier).setValue(preferences.copyWith(
    avoidedSources: updatedAvoidedSources,
  ));
  fireAndForget(saveAllData);
}

/// Restore a previously avoided source by removing it from the avoided sources list
/// 
/// [ref] - WidgetRef for accessing providers
/// [source] - The source name to restore
/// [context] - BuildContext for showing snackbars (optional)
/// 
/// Returns true if the operation was successful, false otherwise
Future<bool> restoreAvoidedSource(
  BuildContext context,
  WidgetRef ref, 
  String sourceId
) async {
  try {
    // Update local user preferences
    final preferences = ref.read(preferencesProvider);
    final updatedAvoidedSources = Set<Source>.from(preferences.avoidedSources)
      ..removeWhere((source) => source.id == sourceId);
    
    final newPreferences = preferences.copyWith(avoidedSources: updatedAvoidedSources);
    await ref.read(preferencesProvider.notifier).setValue(newPreferences);
    
    // Save user preferences update in backend
    fireAndForget(() => savePreferences(ref));

    // Show success message
    if (context.mounted) {
      showSnackBarSuccess(context, 'Source restored: $sourceId');
    }
    
    return true;
  } catch (e) {
    // Show error message
    if (context.mounted) {
      showSnackBarError(context, 'Failed to restore source: $e');
    }
    
    return false;
  }
}

/// Add a source to the avoided sources list
/// 
/// [ref] - WidgetRef for accessing providers
/// [source] - The source name to avoid
/// [context] - BuildContext for showing snackbars (optional)
/// 
/// Returns true if the operation was successful, false otherwise
// Future<bool> avoidSource(
//   WidgetRef ref, 
//   String source, {
//   BuildContext? context,
// }) async {
//   try {
//     final preferences = ref.read(preferencesProvider);
//     final updatedAvoidedSources = Set<String>.from(preferences.avoidedSources)
//       ..add(source);
    
//     await ref.read(preferencesProvider.notifier).setValue(
//       preferences.copyWith(avoidedSources: updatedAvoidedSources.toList()),
//     );
    
//     // Show success message
//     if (context != null && context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Source avoided: $source'),
//           backgroundColor: AppColors.success,
//         ),
//       );
//     }
    
//     return true;
//   } catch (e) {
//     // Show error message
//     if (context != null && context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to avoid source: $e'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
    
//     return false;
//   }
// }

/// Check if a source is currently avoided
/// 
/// [ref] - WidgetRef for accessing providers
/// [source] - The source ID to check
/// 
/// Returns true if the source is avoided, false otherwise
bool isSourceAvoided(WidgetRef ref, String source) {
  return getAvoidedSources(ref).any((s) => s.id == source);
}

/// Get all avoided sources
/// 
/// [ref] - WidgetRef for accessing providers
/// 
/// Returns a list of all avoided sources
List<Source> getAvoidedSources(WidgetRef ref) {
  final preferences = ref.read(preferencesProvider);
  return preferences.avoidedSources.toList();
}

/// Clear all avoided sources
/// 
/// [ref] - WidgetRef for accessing providers
/// [context] - BuildContext for showing snackbars (optional)
/// 
/// Returns true if the operation was successful, false otherwise
// Future<bool> clearAllAvoidedSources(
//   WidgetRef ref, {
//   BuildContext? context,
// }) async {
//   try {
//     await ref.read(preferencesProvider.notifier).setValue(
//       ref.read(preferencesProvider).copyWith(avoidedSources: []),
//     );
    
//     // Show success message
//     if (context != null && context.mounted) {
//       showSnackBarSuccess(context, 'All avoided sources cleared');
//     }
    
//     return true;
//   } catch (e) {
//     // Show error message
//     if (context != null && context.mounted) {
//       showSnackBarError(context, 'Failed to clear avoided sources: $e');
//     }
    
//     return false;
//   }
// }

/// Restore a previously marked feed by finding and unmarking it from the appropriate feed provider
/// 
/// [ref] - WidgetRef for accessing providers
/// [feedId] - The feed ID to restore
/// [context] - BuildContext for showing snackbars (optional)
/// 
/// Returns true if the operation was successful, false otherwise
// Future<bool> _restoreFeed(
//   BuildContext context,
//   WidgetRef ref, 
//   String feedId
// ) async {
//   try {
//     // Find which feed notifier contains this feed and restore it
//     final feedStates = [
//       ref.read(feedProvider),
//       ref.read(feedLikedProvider),
//       ref.read(feedSavedProvider),
//     ];

//     for (final state in feedStates) {
//       if (state.notInterestedItems.contains(feedId)) {
//         final notifier = ref.read(feedProvider.notifier);
//         await notifier.unmarkAsNotInterested(feedId);
        
//         // Show success message
//         if (context.mounted) {
//           showSnackBarSuccess(context, 'Feed restored');
//         }
        
//         return true;
//       }
//     }
    
//     // Feed not found in any provider
//     if (context.mounted) {
//       showSnackBarError(context, 'Feed not found in hidden list');
//     }
    
//     return false;
//   } catch (e) {
//     // Show error message
//     if (context.mounted) {
//       showSnackBarError(context, 'Failed to restore feed: $e');
//     }
    
//     return false;
//   }
// }