import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/feeds.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/user.dart';
import '../config/constants.dart';
import '../config/colors.dart';
import '../widgets/animations/loading_indicator_bar.dart';
import '../widgets/components/logo.dart';

/// Duration of the splash screen in seconds
const SPLASH_DURATION_MS = 2000;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(preCacheAssets(context));
    unawaited(getAppVersion());
    // unawaited(getUser());
    unawaited(_startSplash());
  }

  Future<bool> _loadFeeds() async {
    // Maximum double duration of splash screen
    return !isFirstRun && await loadFeeds(timeoutMs: SPLASH_DURATION_MS * 2);
  }

  /// Start the splash screen animation and navigation
  Future<void> _startSplash() async {
    // Preload the target route during splash delay
    final target = isFirstRun ? '/onboarding' : '/home';
    debugPrint('[splash] Preloading $target route');
    preloadRoutes(context);
    
    // Preload user feeds within splash screen delay
    final results = await Future.wait([
      _loadFeeds(),
      delay(SPLASH_DURATION_MS),
    ]);

    final feedLoaded = results[0];
    if (!mounted) return;

    // Navigate to target route
    debugPrint('[splash] Navigating to $target');
    context.go(target, extra: { 'feedLoaded': feedLoaded });
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: Center(
              child: Column(
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
              ),
            ),
          ),
          
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
