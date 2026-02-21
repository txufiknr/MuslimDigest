import 'dart:math' show max;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/repository.dart';

final readCountProvider = NotifierProvider<ReadCountNotifier, int>(ReadCountNotifier.new);

class ReadCountNotifier extends Notifier<int> {
  static const _key = 'read_count';

  @override
  int build() {
    final value = ref.watch(preferencesRepositoryProvider).getInt(_key);
    return max(0, value ?? 0);
  }

  Future<void> setValue(int? value) async {
    state = max(0, value ?? 0);
    await ref
        .read(preferencesRepositoryProvider)
        .setInt(_key, state);
  }

  Future<void> clear() async {
    state = 0;
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}