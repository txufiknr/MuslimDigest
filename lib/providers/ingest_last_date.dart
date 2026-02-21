import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/repository.dart';

final ingestLastDateProvider = NotifierProvider<IngestLastDateNotifier, DateTime?>(IngestLastDateNotifier.new);

class IngestLastDateNotifier extends Notifier<DateTime?> {
  static const _key = 'ingest_last_date';

  @override
  DateTime? build() {
    final json = ref.watch(preferencesRepositoryProvider).getString(_key);
    return json == null ? null : DateTime.parse(json);
  }

  Future<void> setValue(DateTime? value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setString(_key, value?.toIso8601String());
  }

  Future<void> clear() async {
    state = null;
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }
}