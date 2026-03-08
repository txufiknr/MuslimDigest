import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/services/dio.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/feed.dart';

Future<bool> markRead(String clusterId, FeedType? source) async {
  final response = await ApiService.post('feed/history', {'clusterId': clusterId, 'source': ?source?.name});
  log("[markRead] post history result: ${response.result}");
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
  log("[markNotInterested] 🔥 called for: $clusterId");
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