import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';

class FeedLatestState {
  final List<FeedItem>? items;
  final bool isLoading;
  final String? error;

  bool get isEmpty => items?.isEmpty ?? true;

  const FeedLatestState({
    this.items,
    this.isLoading = false,
    this.error,
  });

  FeedLatestState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedLatestState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final feedLatestProvider = NotifierProvider<FeedLatestNotifier, FeedLatestState>(FeedLatestNotifier.new);

class FeedLatestNotifier extends Notifier<FeedLatestState> {
  static const _key = 'feed/latest';

  @override
  FeedLatestState build() {
    final jsonString = ref.watch(preferencesRepositoryProvider).getString(_key);
    if (jsonString == null) return const FeedLatestState();
    final feedItems = List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
    return FeedLatestState(items: feedItems);
  }

  Future<void> setValue(List<FeedItem>? value) async {
    state = state.copyWith(items: value);
    final feedItemsString = value == null ? null : jsonEncode(value.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(_key, feedItemsString);
  }

  Future<void> clear() async {
    state = const FeedLatestState();
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }

  Future<bool> load({int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await ApiService.get(
        'feed/latest',
        queryParams: {
          'limit': (limit ?? CURSOR_PAGINATION_LIMIT).toString(),
        },
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