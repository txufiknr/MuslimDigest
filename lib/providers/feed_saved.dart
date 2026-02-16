import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';

class FeedSavedState {
  final List<FeedItem>? items;
  final bool isLoading;
  final String? error;

  bool get isEmpty => items?.isEmpty ?? true;
  bool get isGetting => isEmpty && isLoading;
  bool get isNone => isEmpty && !isLoading;

  const FeedSavedState({
    this.items,
    this.isLoading = false,
    this.error,
  });

  FeedSavedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedSavedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final feedSavedProvider = NotifierProvider<FeedSavedNotifier, FeedSavedState>(FeedSavedNotifier.new);

class FeedSavedNotifier extends Notifier<FeedSavedState> {
  static const _key = 'feed/saved';

  @override
  FeedSavedState build() {
    final jsonString = ref.watch(preferencesRepositoryProvider).getString(_key);
    if (jsonString == null) return const FeedSavedState();
    final feedItems = List<FeedItem>.from(List<Map<String, dynamic>>.from(jsonDecode(jsonString)).map(FeedItem.fromJson));
    return FeedSavedState(items: feedItems);
  }

  Future<void> setValue(List<FeedItem>? value) async {
    state = state.copyWith(items: value);
    final feedItemsString = value == null ? null : jsonEncode(value.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(_key, feedItemsString);
  }

  Future<void> clear() async {
    state = const FeedSavedState();
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }

  Future<void> update(String feedId, {bool? isLiked, bool? isSaved}) async {
    final updatedItems = state.items?.map((item) {
      if (item.id == feedId) {
        return item.copyWith(
          isLiked: isLiked ?? item.isLiked,
          isSaved: isSaved ?? item.isSaved,
        );
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
    
    // Update cached data
    final feedItemsString = updatedItems == null ? null : jsonEncode(updatedItems.map((item) => item.toJson()).toList());
    await ref.read(preferencesRepositoryProvider).setString(_key, feedItemsString);
  }

  Future<bool> load() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await ApiService.get('feed/saved');

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
