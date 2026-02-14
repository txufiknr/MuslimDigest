import 'package:go_router/go_router.dart';
import '../screens/splash.dart';
import '../screens/home.dart';
import '../screens/onboarding.dart';
import '../screens/welcome.dart';
import '../screens/settings.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          return HomePage(args: Map<String, dynamic>.from(state.extra as Map? ?? {}));
        },
        // onExit: (context, state) async {
        //   fireAndForget(saveAllData);
        //   return true;
        // },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
