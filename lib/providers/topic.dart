import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/repository.dart';

final topicProvider = NotifierProvider<TopicNotifier, String?>(TopicNotifier.new);

class TopicNotifier extends Notifier<String?> {
  static const _key = 'topic';

  @override
  String? build() {
    final value = ref.watch(preferencesRepositoryProvider).getString(_key);
    return value;
  }

  Future<void> setValue(String? value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setString(_key, value);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}