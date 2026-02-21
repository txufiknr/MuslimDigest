import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/variables/user.dart';

final settingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(UserSettingsNotifier.new);

class UserSettingsNotifier extends Notifier<UserSettings> {
  static const _key = 'settings';

  @override
  UserSettings build() {
    final json = ref.watch(preferencesRepositoryProvider).getJson(_key);
    return json == null ? PrefData.settings : UserSettings.fromJson(json);
  }

  Future<void> setValue(UserSettings value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setJson(_key, value.toJson());
  }

  Future<void> updateTextSize(int textSize) async {
    final updated = state.copyWith(textSize: textSize);
    await setValue(updated);
  }

  Future<void> updateSwipeDirection(String swipeDirection) async {
    final updated = state.copyWith(swipeDirection: swipeDirection);
    await setValue(updated);
  }
}
