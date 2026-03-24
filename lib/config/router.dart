import 'package:go_router/go_router.dart';
import 'package:muslimdigest/screens/feed/feed_history_page.dart';
import 'package:muslimdigest/screens/feed/multi_feed.dart';
import 'package:muslimdigest/screens/settings/edit_profile.dart';
import 'package:muslimdigest/screens/feed/liked_feeds.dart';
import 'package:muslimdigest/screens/settings/personalization.dart';
import 'package:muslimdigest/screens/feed/saved_feeds.dart';
import 'package:muslimdigest/screens/feed/single_feed.dart';
import 'package:muslimdigest/screens/settings/hidden_content.dart';
import 'package:muslimdigest/screens/collections/collections_page.dart';
import '../screens/onboarding/splash.dart';
import '../screens/home.dart';
import '../screens/onboarding/onboarding.dart';
import '../screens/settings/settings.dart';
import '../screens/onboarding/welcome.dart';
import '../variables/feed.dart';
import '../variables/app.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    observers: [routeObserver],
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
        builder: (context, state) {
          final collection = state.uri.queryParameters['collection'];
          return SavedFeedsPage(collection: collection);
        },
      ),
      GoRoute(
        path: '/collections',
        name: 'collections',
        builder: (context, state) => const CollectionsPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const FeedHistoryPage(),
      ),
      GoRoute(
        path: '/hidden_content',
        name: 'hidden_content',
        builder: (context, state) {
          final initialTab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
          return HiddenContentPage(initialTab: initialTab);
        },
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
      GoRoute(
        path: '/feeds/:feedId',
        name: 'multi_feeds',
        builder: (context, state) {
          final feedId = state.pathParameters['feedId']!;
          final feedType = state.uri.queryParameters['feedType'] ?? FeedType.digest.name;
          return MultiFeedPage(
            feedId: feedId,
            feedType: FeedType.fromString(feedType),
          );
        },
      ),
    ],
  );
}
