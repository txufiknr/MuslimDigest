import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/ingest_last_date.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart' show FeedType;
import 'package:muslimdigest/variables/user.dart';

final userProvider = NotifierProvider<UserNotifier, User>(UserNotifier.new);

class UserNotifier extends Notifier<User> {
  static const _key = 'user';

  @override
  User build() {
    final json = ref.watch(preferencesRepositoryProvider).getJson(_key);
    return json == null ? PrefData.user : User.fromJson(json);
  }

  Future<void> setValue(User value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setJson(_key, value.toJson());
  }

  Future<void> clear() async {
    await ref.read(preferencesRepositoryProvider).remove(_key);
    state = PrefData.user; // Reset to default values
  }

  DateTime? get ingestLastDate => ref.read(ingestLastDateProvider);
  DateTime? get streakLastDate => ref.read(streaksProvider).lastReadAt;
  bool get isStreakToday => ref.read(streaksProvider.notifier).isStreakToday;
  bool get isDailyDigestDone => isStreakToday || isSameDay(ingestLastDate, streakLastDate);
  FeedType get homeFeedType => isDailyDigestDone ? FeedType.latest : FeedType.digest;

  Future<bool> load() async {
    try {
      final response = await ApiService.get('user');
      if (response.successful) {
        // log("🧑 Current user result: ${response.result}");
        final user = User.fromJson(response.data);
        await setValue(user);
        log("🧑 Current user: ${user.toString()}");
      } else {
        log("🙅‍♂️ Current user: none");
      }
      return response.successful;
    } catch (e) {
      log("🙅‍♂️ Current user: $e");
      return false;
    }
  }
}