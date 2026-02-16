import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show DAILY_READ_TARGET;
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';
import 'package:muslimdigest/variables/user.dart';

class FeedState {
  final List<FeedItem>? items;
  final bool isLoading;
  final String? error;

  bool get isEmpty => items?.isEmpty ?? true;
  bool get isGetting => isEmpty && isLoading;
  bool get isNone => isEmpty && !isLoading;

  const FeedState({
    this.items,
    this.isLoading = false,
    this.error,
  });

  FeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends Notifier<FeedState> {
  static const _key = 'feed';

  @override
  FeedState build() {
    final jsonString = ref.watch(preferencesRepositoryProvider).getString(_key);
    if (jsonString == null) return const FeedState();
    final feedItems = List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
    return FeedState(items: feedItems);
  }

  Future<void> setValue(List<FeedItem>? value) async {
    state = state.copyWith(items: value);
    final feedItemsString = value == null ? null : jsonEncode(value.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(_key, feedItemsString);
  }

  Future<void> clear() async {
    state = const FeedState();
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }

  Future<bool> load({String? topic, int? timeoutMs}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final options = timeoutMs == null ? null : ApiOptions(timeout: Duration(milliseconds: timeoutMs));
      final response = await ApiService.get(
        'feed',
        queryParams: {
          'topic': ?(topic ?? PrefData.currentTopic),
          'limit': DAILY_READ_TARGET.toString(),
        },
        options: options,
      );

      if (response.successful) {
        final feedItems = List<FeedItem>.from(
          response.data.map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
        );
        await setValue(feedItems);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: response.error);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}