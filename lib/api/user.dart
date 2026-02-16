import 'package:flutter/material.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/variables/user.dart';

/// Save user, preferences, and streaks data
Future<bool> saveAllData() async {
  // TODO: save settings
  final responses = await Future.wait([
    if (PrefData.user != null) ApiService.post('user', PrefData.user!.toJson()),
    if (PrefData.preferences != null) ApiService.post('preferences', PrefData.preferences!.toJson()),
    if (PrefData.streaks != null) ApiService.post('streaks', PrefData.streaks!.toJson()),
  ]);
  final successCount = responses.where((result) => result.success).length;
  debugPrint('[saveAllData] Save result: $successCount/${responses.length} success');
  return successCount == responses.length;
}