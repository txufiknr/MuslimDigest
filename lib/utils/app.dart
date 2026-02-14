import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> preCacheAssets(BuildContext context) async {
  return precacheImage(AssetImage(APP_ASSETS_LOGO), context);
}

Future<void> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
}

/// Save user and preferences data
Future<bool> saveAllData() async {
  // TODO: save settings
  final responses = await Future.wait([
    if (user != null) ApiService.post('user', user!.toJson()),
    if (preferences != null) ApiService.post('preferences', preferences!.toJson()),
  ]);
  final successCount = responses.where((result) => result.success).length;
  debugPrint('[saveAllData] Save result: $successCount/${responses.length} success');
  return successCount == responses.length;
}

Future<void> quit() {
  return SystemNavigator.pop(animated: true);
}

Future<void> openStoreListing([String? appId]) async {
  if (appId == null) return inAppReview.openStoreListing();
  await LaunchApp.openApp(androidPackageName: 'com.tarra.$appId');
}

Future<void> requestReview() async {
  if (await inAppReview.isAvailable()) return inAppReview.requestReview();
}