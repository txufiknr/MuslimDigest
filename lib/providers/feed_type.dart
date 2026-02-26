import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/variables/feed.dart';

final feedTypeProvider = NotifierProvider<FeedTypeNotifier, FeedType>(FeedTypeNotifier.new);

class FeedTypeNotifier extends Notifier<FeedType> {
  static const _key = 'feedType';

  @override
  FeedType build() {
    final value = ref.watch(preferencesRepositoryProvider).getString(_key);
    return FeedType.fromString(value ?? ref.read(appRepositoryProvider).homeFeedType.name);
  }

  Future<void> setValue(FeedType value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setString(_key, value.name);
  }
}