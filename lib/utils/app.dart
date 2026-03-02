import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> preCacheAssets(BuildContext context) async {
  return precacheImage(AssetImage(APP_ASSETS_LOGO), context);
}

Future<void> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
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

Future<bool> isOnline() async {
  final connectivityResults = await Connectivity().checkConnectivity();
  return connectivityResults.any((result) => result != ConnectivityResult.none);
}

/// Check if asset exists in the app bundle
Future<bool> doesAssetExist(String assetPath) async {
  try {
    await rootBundle.loadString(assetPath);
    return true;
  } catch (e) {
    return false;
  }
}