import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/variables/user.dart';

final preferencesProvider = NotifierProvider<UserNotifier, UserPreferences>(UserNotifier.new);

class UserNotifier extends Notifier<UserPreferences> {
  static const _key = 'preferences';

  @override
  UserPreferences build() {
    final json = ref.watch(preferencesRepositoryProvider).getJson(_key);
    return json == null ? UserPreferences(userId: PrefData.userId) : UserPreferences.fromJson(json);
  }

  Future<void> setValue(UserPreferences value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setJson(_key, value.toJson());
  }
}