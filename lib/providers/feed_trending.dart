import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/feeds.dart' show CURSOR_PAGINATION_LIMIT;
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';

class FeedTrendingState {
  final List<FeedItem>? items;
  final bool isLoading;
  final String? error;

  bool get isEmpty => items?.isEmpty ?? true;

  const FeedTrendingState({
    this.items,
    this.isLoading = false,
    this.error,
  });

  FeedTrendingState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedTrendingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final feedTrendingProvider = NotifierProvider<FeedTrendingNotifier, FeedTrendingState>(FeedTrendingNotifier.new);

class FeedTrendingNotifier extends Notifier<FeedTrendingState> {
  static const _key = 'feed/trending';

  @override
  FeedTrendingState build() {
    final jsonString = ref.watch(preferencesRepositoryProvider).getString(_key);
    if (jsonString == null) return const FeedTrendingState();
    final feedItems = List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
    return FeedTrendingState(items: feedItems);
  }

  Future<void> setValue(List<FeedItem>? value) async {
    state = state.copyWith(items: value);
    final feedItemsString = value == null ? null : jsonEncode(value.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(_key, feedItemsString);
  }

  Future<void> clear() async {
    state = const FeedTrendingState();
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }

  Future<bool> load({int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await ApiService.get(
        'feed/trending',
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