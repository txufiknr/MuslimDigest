import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/constants.dart' show APP_ASSETS_LOGO;
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> preCacheAssets(BuildContext context) async {
  return precacheImage(AssetImage(APP_ASSETS_LOGO), context);
}

void preloadRoutes(BuildContext context) {
  final navigator = Navigator.of(context);
  // Preload hint for routes which are not already in the stack
  if (!navigator.canPop()) {
    // Preload hint for go_router
    GoRouter.of(context).routeInformationProvider;
  }
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

void quit() async {
  SystemNavigator.pop(animated: true);
}