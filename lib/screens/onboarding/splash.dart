import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/services/dio.dart';
import 'package:muslimdigest/variables/user.dart';
import '../../config/colors.dart';
import '../../widgets/animations/loading_indicator_bar.dart';
import '../../widgets/components/logo.dart';

/// Duration of the splash screen in seconds
const SPLASH_DURATION_MS = 2000;

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  AppRepository get r => ref.read(appRepositoryProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      [_loadAppData, r.initData, r.initActiveFeed, r.loadUserFeed, _processOfflineQueue, _startSplash].forEach(fireAndForget);
    });
  }

  Future<void> _loadAppData() async {
    await Future.wait([
      preCacheAssets(context),
      getAppVersion(),
    ]);
  }

  /// Process offline API queue on app startup
  Future<void> _processOfflineQueue() async {
    try {
      final processedCount = await ApiService.processOfflineQueue();
      if (processedCount > 0) {
        log('[Splash] Processed $processedCount offline requests');
      }
    } catch (e) {
      log('[Splash] Error processing offline queue: $e');
    }
  }

  /// Start the splash screen animation and navigation
  Future<void> _startSplash() async {
    await delay(SPLASH_DURATION_MS);
    if (!mounted) return;

    // Navigate to target route
    if (isFirstRun) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Main content area
          Splash().center().expand(),
          
          // Loading indicator at the bottom
          LoadingIndicatorBar(),
        ],
      ),
    );
  }
}
