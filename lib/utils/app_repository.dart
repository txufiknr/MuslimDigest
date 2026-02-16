import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed.dart';
import 'package:muslimdigest/providers/feed_latest.dart';
import 'package:muslimdigest/providers/feed_trending.dart';
import 'package:muslimdigest/providers/preferences.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/user.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/time.dart';

/// Business-logic repository. Uses Ref, never WidgetRef.
/// Expose via provider so it can be watched or read anywhere.
class AppRepository {
  AppRepository(this._ref);

  final Ref _ref;

  List<FeedItem> get feedDigest => _ref.read(feedProvider).items ?? [];
  List<FeedItem> get feedLatest => _ref.read(feedLatestProvider).items ?? [];
  List<FeedItem> get feedTrending => _ref.read(feedTrendingProvider).items ?? [];

  User? get user => _ref.read(userProvider);
  UserPreferences? get preferences => _ref.read(preferencesProvider);
  DateTime get readLastDate => _ref.read(readLastDateProvider) ?? DateTime.now();
  int get readCount => _ref.read(readCountProvider);

  bool get isFirstRun => user == null;
  bool get isNewDay => !isSameDay(today, readLastDate);
  bool get shouldLoadFeedToday => isNewDay || feedDigest.isEmpty;

  String get firstName {
    final name = extractFirstName(user?.name);
    if (name.isNotEmpty) return name;
    return switch (user?.gender) {
      'male' => 'Brother',
      'female' => 'Sister',
      _ => 'Friend',
    };
  }

  List<String> get preferredTopics => preferences?.topics ?? [];
}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref);
});