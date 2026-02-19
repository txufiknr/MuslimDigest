import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/utils/time.dart';

final streaksProvider = NotifierProvider<UserNotifier, UserStreaks?>(UserNotifier.new);

class UserNotifier extends Notifier<UserStreaks?> {
  static const _key = 'streaks';

  @override
  UserStreaks? build() {
    final json = ref.watch(preferencesRepositoryProvider).getJson(_key);
    return json == null ? null : UserStreaks.fromJson(json);
  }

  bool get isStreakToday => state?.lastReadAt != null && isToday(state!.lastReadAt!);

  Future<void> setValue(UserStreaks? value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setJson(_key, value?.toJson());
  }

  Future<void> clear() async {
    state = null;
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}