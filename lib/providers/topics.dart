import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/repository.dart';

class TopicsState {
  final List<String>? items;
  final bool isLoading;
  final String? error;

  bool get isEmpty => items?.isEmpty ?? true;
  List<String> get availableTopics => items ?? [];

  const TopicsState({
    this.items,
    this.isLoading = false,
    this.error,
  });

  TopicsState copyWith({
    List<String>? items,
    bool? isLoading,
    String? error,
  }) {
    return TopicsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final topicsProvider = NotifierProvider<TopicsNotifier, TopicsState>(TopicsNotifier.new);

class TopicsNotifier extends Notifier<TopicsState> {
  static const _key = 'topics';

  @override
  TopicsState build() {
    final json = ref.watch(preferencesRepositoryProvider).getJsonList(_key);
    return TopicsState(items: json);
  }

  Future<void> setValue(List<String>? value) async {
    state = state.copyWith(items: value);
    await ref
        .read(preferencesRepositoryProvider)
        .setJsonList(_key, value);
  }

  Future<void> clear() async {
    state = const TopicsState();
    await ref.read(preferencesRepositoryProvider).remove(_key);
  }

  Future<bool> load() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await ApiService.get('topics');
      if (response.successful) {
        // log('[TopicsNotifier] Available topics: ${response.data}');
        await setValue(List<String>.from(response.data));
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