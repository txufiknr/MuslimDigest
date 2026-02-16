import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/repository.dart';

final userProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);

class UserNotifier extends Notifier<User?> {
  static const _key = 'user';

  @override
  User? build() {
    final json = ref.watch(preferencesRepositoryProvider).getJson(_key);
    return json == null ? null : User.fromJson(json);
  }

  Future<void> setValue(User? value) async {
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