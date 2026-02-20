import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed.dart';
import 'package:muslimdigest/providers/feed_trending.dart';
import 'package:muslimdigest/providers/topics.dart';
import 'package:muslimdigest/providers/user.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
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
      fireAndForget(_loadUserData);
      unawaited(_startSplash());
    });
  }

  Future<void> _loadAppData() async {
    await Future.wait([
      preCacheAssets(context),
      getAppVersion(),
    ]);
  }

  Future<bool> _loadUserData() async {
    final userId = prefs.getString('user_id');
    if (userId == null) { // MUST: Create new user
      final user = User(userId: PrefData.userId);
      await ref.read(userProvider.notifier).setValue(user);
    }

    final results = await Future.wait<bool>([
      ref.read(userProvider.notifier).load(),
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
