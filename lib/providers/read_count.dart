import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/repository.dart';

final readCountProvider = NotifierProvider<UserNotifier, int>(UserNotifier.new);

class UserNotifier extends Notifier<int> {
  static const _key = 'read_count';

  @override
  int build() {
    final value = ref.watch(preferencesRepositoryProvider).getInt(_key);
    return value ?? 0;
  }

  Future<void> setValue(int? value) async {
    state = value ?? 0;
    await ref
        .read(preferencesRepositoryProvider)
        .setInt(_key, value);
  }

  Future<void> clear() async {
    state = 0;
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}