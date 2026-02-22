import 'package:go_router/go_router.dart';
import 'package:muslimdigest/screens/edit_profile.dart';
import 'package:muslimdigest/screens/liked_feeds.dart';
import 'package:muslimdigest/screens/personalization.dart';
import 'package:muslimdigest/screens/saved_feeds.dart';
import 'package:muslimdigest/screens/single_feed.dart';
import '../screens/splash.dart';
import '../screens/home.dart';
import '../screens/onboarding.dart';
import '../screens/settings.dart';
import '../screens/welcome.dart';
import '../variables/feed.dart';

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
        builder: (context, state) => const HomePage(),
        // builder: (context, state) {
        //   return HomePage(args: Map<String, dynamic>.from(state.extra as Map? ?? {}));
        // },
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
      GoRoute(
        path: '/personalization',
        name: 'personalization',
        builder: (context, state) => const PersonalizationPage(),
      ),
      GoRoute(
        path: '/edit_profile',
        name: 'edit_profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/liked_feeds',
        name: 'liked_feeds',
        builder: (context, state) => const LikedFeedsPage(),
      ),
      GoRoute(
        path: '/saved_feeds',
        name: 'saved_feeds',
        builder: (context, state) => const SavedFeedsPage(),
      ),
      GoRoute(
        path: '/feed/:feedId',
        name: 'single_feed',
        builder: (context, state) {
          final feedId = state.pathParameters['feedId']!;
          final feedType = state.uri.queryParameters['feedType'] ?? FeedType.digest.name;
          return SingleFeedPage(
            feedId: feedId,
            feedType: FeedType.fromString(feedType),
          );
        },
      ),
    ],
  );
}
