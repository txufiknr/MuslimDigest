import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/variables/feed.dart';

final feedTypeProvider = NotifierProvider<FeedTypeNotifier, FeedType>(FeedTypeNotifier.new);

class FeedTypeNotifier extends Notifier<FeedType> {
  static const _key = 'feed_type';

  FeedType get _defaultFeedType => ref.read(appRepositoryProvider).homeFeedType;

  @override
  FeedType build() {
    final value = ref.watch(preferencesRepositoryProvider).getString(_key);
    return FeedType.fromString(value ?? _defaultFeedType.name);
  }

  Future<void> reset() async {
    state = _defaultFeedType;
    await ref
        .read(preferencesRepositoryProvider)
        .remove(_key);
  }

  Future<void> setValue(FeedType value) async {
    state = value;
    await ref
        .read(preferencesRepositoryProvider)
        .setString(_key, value.name);
  }
}