import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed.dart';
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

  User? get user => _ref.read(userProvider);
  UserPreferences? get preferences => _ref.read(preferencesProvider);
  DateTime get readLastDate => _ref.read(readLastDateProvider) ?? today;
  int get readCount => _ref.read(readCountProvider);

  bool get isFirstRun => user == null;
  bool get isNewDay => !isToday(readLastDate);
  bool get shouldLoadFeedToday => isNewDay || _ref.read(feedProvider).isEmpty;
  bool get shouldLoadFeedTodayAndStillNone => shouldLoadFeedToday && _ref.read(feedProvider).isNone;

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