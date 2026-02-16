import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/providers/feed.dart';
import 'package:muslimdigest/providers/feed_trending.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import '../config/constants.dart';
import '../config/colors.dart';
import '../widgets/animations/loading_indicator_bar.dart';
import '../widgets/components/logo.dart';

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
      fireAndForget(_loadAppData);
      fireAndForget(_loadFeedData);
      unawaited(_startSplash());
    });
  }

  Future<void> _loadAppData() async {
    await Future.wait([
      preCacheAssets(context),
      getAppVersion(),
    ]);
  }

  Future<bool> _loadFeedData() async {
    final results = await Future.wait<bool>([
      if (r.shouldLoadFeedToday) ref.read(feedProvider.notifier).load(),
      ref.read(feedTrendingProvider.notifier).load(),
      ref.read(topicsProvider.notifier).load(),
    ]);
    final isSuccess = results.every((result) => result);
    return isSuccess;
  }

  /// Start the splash screen animation and navigation
  Future<void> _startSplash() async {
    await delay(SPLASH_DURATION_MS);
    if (!mounted) return;

    // Navigate to target route
    if (r.isFirstRun) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Main content area
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              const Logo(size: 180).pulseIt(duration: 3000, scaleEnd: 1.1),
              
              const SizedBox(height: 32),
              
              // App title
              Text(
                APP_NAME,
                style: h.currentTextTheme.headlineLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // App subtitle
              Text(
                APP_TAGLINE,
                style: h.currentTextTheme.bodyMedium?.copyWith(
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ).center().expand(),
          
          // Loading indicator at the bottom
          LoadingIndicatorBar(
            height: 4,
            duration: Duration(milliseconds: 2000),
          ),
        ],
      ),
    );
  }
}
