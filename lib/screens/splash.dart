import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/utils/extensions.dart';
import '../config/constants.dart';
import '../config/colors.dart';
import '../utils/helpers.dart';
import '../utils/variables.dart';
import '../widgets/animations/loading_indicator_bar.dart';
import '../widgets/components/logo.dart';

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
    debugPrint('[splash] Initializing... (user id: $userId)');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplash();
    });
  }

  void _preloadTargetRoute(BuildContext context) {
    // Preload target route during splash delay for faster navigation
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Route is already in the stack, no need to preload
    } else {
      // Preload hint for go_router
      GoRouter.of(context).routeInformationProvider;
    }
  }

  void _startSplash() async {
    // Preload the target route during splash delay
    final target = userId == null ? '/onboarding' : '/home';
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
