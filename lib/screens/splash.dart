import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/user.dart';
import '../config/constants.dart';
import '../config/colors.dart';
import '../variables/app.dart';
import '../widgets/animations/loading_indicator_bar.dart';
import '../widgets/components/logo.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Duration of the splash screen in seconds
const SPLASH_DURATION_SECONDS = 2;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  /// Initialize splash screen
  Future<void> _initSplash() async {
    await Future.wait([
      _initAppData(),
      _initUserData(),
    ]);
    _startSplash();
  }

  /// Initialize app data
  Future<void> _initAppData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
  }

  /// Initialize user data from backend API
  /// 
  /// This function handles fetching and caching user data and preferences.
  /// It includes proper error handling, null safety, and early returns for optimization.
  Future<void> _initUserData() async {
    debugPrint('[splash] Initializing user data... (user id: $userId)');
    
    try {
      // Parallel API calls for better performance - fetch user and preferences simultaneously
      final responses = await Future.wait([
        ApiService.get('user'), // Get user data
        ApiService.get('preferences'), // Get user preferences
        ApiService.get('streaks'), // Get user reading streaks
      ]);

      // Process responses using the utility function
      await handleUserResponses(responses);
      
    } catch (e) {
      // Global error handling - show user-friendly modal
      debugPrint('[splash] Error during user data initialization: $e');
      
      // Show bottom modal sheet with error details and retry options
      if (mounted) {
        final shouldRetry = await showRetryableError(
          context,
          title: 'Failed to get user data',
          message: 'Please check your internet connection and try again.',
          error: e,
        );
        if (shouldRetry && mounted) {
          return _initUserData();
        }
      }
    }
  }

  /// Preload target route during splash delay for faster navigation
  void _preloadTargetRoute(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Route is already in the stack, no need to preload
    } else {
      // Preload hint for go_router
      GoRouter.of(context).routeInformationProvider;
    }
  }

  /// Start the splash screen animation and navigation
  void _startSplash() async {
    // Preload the target route during splash delay
    final target = user == null ? '/onboarding' : '/home';
    if (mounted) {
      debugPrint('[splash] Preloading $target route');
      _preloadTargetRoute(context);
    }
    
    await Future.delayed(Duration(seconds: SPLASH_DURATION_SECONDS));
    if (mounted) {
      debugPrint('[splash] Navigating to $target');
      context.go(target);
    }
  }

  /// Show bottom modal confirm with error details and retry options
  // Future<bool> _handleUserError() async {
  //   final confirmed = await showBottomModalConfirm(
  //     context,
  //     message: 'Failed to load your data. Please check your internet connection and try again.',
  //     cancelButtonText: 'Continue Anyway',
  //     confirmButtonText: 'Retry',
  //     confirmButtonIcon: Icon(CupertinoIcons.refresh),
  //   );
  //   return confirmed;
  // }

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
