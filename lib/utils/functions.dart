import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
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