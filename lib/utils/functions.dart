import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  
  try {
    // First try to launch the URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // I/UrlLauncher(21394): component name for https://www.aljazeera.com/news/2026/2/22/north-koreas-kim-jong-un-re-elected-as-chief-of-workers?traffic_source=rss is null
      // I/UrlLauncher(21394): component name for https://flutter.dev is null
      // I/flutter (21394): Cannot launch URL: https://www.aljazeera.com/news/2026/2/22/north-koreas-kim-jong-un-re-elected-as-chief-of-workers?traffic_source=rss
      // TODO: Cannot launch URL: https://www.aljazeera.com/news/2026/2/22/north-koreas-kim-jong-un-re-elected-as-chief-of-workers?traffic_source=rss
      debugPrint('Cannot launch URL: $url');
    }
  } catch (e) {
    debugPrint('Error launching URL: $url, error: $e');
    
    // Fallback: try with different modes
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (fallbackError) {
      debugPrint('Fallback also failed for URL: $url, error: $fallbackError');
    }
  }
}

void unfocus() {
  FocusManager.instance.primaryFocus?.unfocus();
}

Future<void> delay(int ms, [VoidCallback? callback]) {
  return Future.delayed(Duration(milliseconds: ms), callback);
}

void fireAndForget(Future<void> Function() fn) {
  try {
    unawaited(fn());
  } catch (_) {}
}