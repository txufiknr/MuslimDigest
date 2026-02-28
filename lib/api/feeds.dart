import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/functions.dart';

Future<bool> markRead(String clusterId) async {
  final response = await ApiService.post('feed/history', {'clusterId': clusterId});
  return response.successful;
}

Future<bool> like(String clusterId, bool value) async {
  final response = await ApiService.post('feed/like', {'clusterId': clusterId, 'value': value});
  return response.successful;
}

Future<bool> save(String clusterId, bool value) async {
  final response = await ApiService.post('feed/save', {'clusterId': clusterId, 'value': value});
  return response.successful;
}

Future<ApiResponse> markNotInterested(String clusterId) async {
  return ApiService.post('feed/not_interested', {'clusterId': clusterId});
}

Future<ApiResponse> unmarkNotInterested(String clusterId) async {
  return ApiService.delete('feed/not_interested?clusterId=$clusterId');
}

Future<ApiResponse> submitFeedback(String clusterId, String category, String message) async {
  return ApiService.post('feed/feedback', {
    'clusterId': clusterId,
    'category': category,
    'message': message,
  });
}

Future<void> avoidSource(WidgetRef ref, String sourceId) async {
  final preferences = ref.read(preferencesProvider);
  await ref.read(preferencesProvider.notifier).setValue(preferences.copyWith(
    avoidedSources: [...preferences.avoidedSources, sourceId],
  ));
  fireAndForget(saveAllData);
}