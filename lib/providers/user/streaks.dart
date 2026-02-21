import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/user.dart';

final streaksProvider = NotifierProvider<UserStreaksNotifier, UserStreaks>(UserStreaksNotifier.new);

class UserStreaksNotifier extends Notifier<UserStreaks> {
  static const _key = 'streaks';

  @override
  UserStreaks build() {
    final json = ref.watch(preferencesRepositoryProvider).getJson(_key);
    return json == null ? PrefData.streaks : UserStreaks.fromJson(json);
  }

  bool get isStreakToday => state.lastReadAt != null && isToday(state.lastReadAt!);

  Future<void> setValue(UserStreaks value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setJson(_key, value.toJson());
  }
}