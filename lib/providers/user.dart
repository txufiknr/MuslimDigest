import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/variables/app.dart';

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

  Future<bool> load() async {
    final userId = prefs.getString('user_id');
    if (userId == null) return true;
    // PrefData.userId;
    try {
      final response = await ApiService.get('user');
      if (response.successful) {
        await setValue(User.fromJson(response.data));
      }
      return response.successful;
    } catch (e) {
      return false;
    }
  }

  Future<void> clear() async {
    state = null;
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}