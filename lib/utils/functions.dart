import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  try {
    if (!await launchUrl(Uri.parse(url))) debugPrint('Could not launch $url');
  } catch (e) {
    debugPrint('Could not launch $url. Error: $e');
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