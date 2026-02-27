import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/repository.dart';

final readCountStatesProvider = NotifierProvider<ReadCountStatesNotifier, Map<String, int>>(ReadCountStatesNotifier.new);

class ReadCountStatesNotifier extends Notifier<Map<String, int>> {
  static const _key = 'read_count_states';

  @override
  Map<String, int> build() {
    final value = ref.watch(preferencesRepositoryProvider).getString(_key);
    if (value == null) return {};
    return Map<String, int>.from(jsonDecode(value));
  }

  Future<void> setValue(Map<String, int> value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setString(_key, jsonEncode(state));
  }

  Future<void> update(Map<String, int> value) async {
    state = {...state, ...value};
    await ref
        .read(preferencesRepositoryProvider)
        .setString(_key, jsonEncode(state));
  }

  Future<void> clear() async {
    state = {};
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}