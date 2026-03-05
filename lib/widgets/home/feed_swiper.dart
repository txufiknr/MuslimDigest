import 'dart:developer';
import 'dart:math' show max;

import 'package:flutter/cupertino.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
import 'package:muslimdigest/providers/feed/feed_history.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/home/feed_card.dart';
import 'package:muslimdigest/widgets/home/trending_card.dart';
import '../../widgets/components/placeholder.dart';
import '../../models/feed.dart';

/// Feed swiper widget for displaying news cards with swipe navigation
class FeedSwiper extends ConsumerStatefulWidget {
  final VoidCallback onReload;
  final VoidCallback onSeeLatest;
  final VoidCallback onSeeHome;
  final FeedType? feedType;
  final int? initialIndex;
  
  const FeedSwiper({super.key, 
    required this.onReload,
    required this.onSeeLatest,
    required this.onSeeHome,
    this.feedType,
    this.initialIndex,
  });

  @override
  ConsumerState<FeedSwiper> createState() => FeedSwiperState();
}

class FeedSwiperState extends ConsumerState<FeedSwiper> {
  final _controller = CardSwiperController();
  late var _isLoading = widget.initialIndex != null;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initInitialPage();
    });
  }

  Future<void> _initInitialPage() async {
    if (widget.initialIndex == null) return;
    if (_isDigestFeed) {
      await ref.read(readCountProvider.notifier).setValue(widget.initialIndex);
    } else {
      await ref.read(readCountStatesProvider.notifier).update({
        _readCountName: widget.initialIndex!,
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Feed type
  FeedType get _feedType => widget.feedType ?? ref.watch(feedTypeProvider);
  bool get _isDigestFeed => _feedType == FeedType.digest;
  bool get _isLatestFeed => _feedType == FeedType.latest;
  bool get _isTopicFeed => _isLatestFeed && _currentTopic != null;

  // Feed states
  List<FeedItem> get _feedItems => _feedType.watchItems(ref);
  bool get _isFeedLoading => _feedType.watch(ref).isLoading;
  int get _readCount => ref.watch(readCountProvider);
  FeedType get _homeFeedType => ref.read(appRepositoryProvider).homeFeedType;
  String? get _currentTopic => widget.feedType == null ? ref.watch(topicProvider) : null;
  int get _cardsCount => _feedItems.length + (_isDigestFeed ? 1 : 0);

  // Read state
  Map<String, int> get _readCountStates => ref.watch(readCountStatesProvider);
  String get _readCountName => _isTopicFeed ? _currentTopic! : _feedType.name;
  int get _readCountState => max(0, _readCountStates[_readCountName] ?? 0);
  int get _currentItemIndex => _isDigestFeed ? _readCount : _readCountState;
  int get _initialItemIndex => _cardsCount == 0 ? 0 : _currentItemIndex.clamp(0, _cardsCount - 1);
  
  // Navigation state
  bool get _canGoPrev => _cardsCount > 1 && _currentItemIndex > 0;
  bool get _canGoNext => _cardsCount > 1 && _currentItemIndex < _cardsCount - 1;

  // User settings
  UserSettings get _settings => ref.watch(settingsProvider);
  CardSwiperDirection get _swipeDirection => _settings.swipeDirection == SwipeDirection.left ? CardSwiperDirection.left : CardSwiperDirection.right;
  UndoDirection get _undoDirection => _swipeDirection == CardSwiperDirection.left ? UndoDirection.right : UndoDirection.left;

  // Lazy loading
  bool get _shouldTriggerLazyLoad {
    if (_isDigestFeed) return false;
    
    final feedState = _feedType.watch(ref);
    if (!feedState.hasMore || feedState.isLoadingMore) return false;
    
    // Only trigger when we're within TRIGGER items of the end of loaded items
    // AND we've made progress through the current page (at least TRIGGER items in)
    final itemsFromEnd = _feedItems.length - _currentItemIndex;
    final progressInPage = _currentItemIndex % CURSOR_PAGINATION_LIMIT;
    
    return itemsFromEnd <= CURSOR_PAGINATION_TRIGGER && progressInPage >= CURSOR_PAGINATION_TRIGGER;
  }

  Future<void> _triggerLazyLoad() async {
    if (_isLoadingMore || !_shouldTriggerLazyLoad) return;
    
    _isLoadingMore = true;
    try {
      await _feedType.getNotifier(ref).loadMore();
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _incrementReadCount(FeedItem previousItem) async {
    if (_isDigestFeed) {
      final readCount = ref.read(readCountProvider);
      final newCount = (readCount + 1).clamp(0, _feedItems.length);
      await Future.wait([
        if (newCount == _feedItems.length) logStreak(ref),
        ref.read(readCountProvider.notifier).setValue(newCount),
      ]);
    } else {
      await ref.read(readCountStatesProvider.notifier).update({
        _readCountName: _readCountState + 1,
      });

      // Trigger lazy loading after swipe
      _triggerLazyLoad();
    }

    // Request review after 5 swipes every 5 feed items
    if (_currentItemIndex > 5 && _currentItemIndex % 5 == 0) {
      requestReview();
    }

    // No need to log history when viewing history feed
    if (widget.feedType == FeedType.history) return;

    await _logHistory(previousItem, true);
  }

  Future<void> _updateHistoryState(FeedItem feedItem) async {
    try {
      // Get the history feed notifier
      final historyNotifier = ref.read(feedHistoryProvider.notifier);
      final currentHistoryState = ref.read(feedHistoryProvider);
      final currentHistoryItems = currentHistoryState.items ?? [];
      
      // Check if the item is already in history and move it to top if it exists
      final existingIndex = currentHistoryItems.where((item) => item.id == feedItem.id);
      
      if (existingIndex.isNotEmpty) {
        // Remove existing item and prepend it to the beginning
        await historyNotifier.setValue([
          feedItem,
          ...currentHistoryItems.where((item) => item.id != feedItem.id),
        ]);
      } else {
        // Add the feed item to the beginning of history
        await historyNotifier.setValue([feedItem, ...currentHistoryItems]);
      }

      // Invalidate cache for feed history since it was updated
      await ref.read(feedCacheProvider).invalidateAllCacheForEndpoint('feed/history');
    } catch (e) {
      // Log error but don't block the main functionality
      debugPrint('Error updating history state: $e');
    }
  }

  Future<void> _decreaseReadCount(FeedItem previousItem) async {
    if (_isDigestFeed) {
      final readCount = ref.read(readCountProvider);
      if (readCount == 0) return;
      await ref.read(readCountProvider.notifier).setValue(readCount - 1);
    } else if (_readCountState > 0) {
      await ref.read(readCountStatesProvider.notifier).update({
        _readCountName: _readCountState - 1,
      });
    }

    await _logHistory(previousItem);
  }

  Future<void> _logHistory(FeedItem previousItem, [bool addTotalReads = false]) async {
    // Update user total read
    if (addTotalReads) {
      final currentUser = ref.read(userProvider);
      await ref.read(userProvider.notifier).setValue(currentUser.copyWith(totalReads: currentUser.totalReads + 1));
    }

    // Update feed/history state by adding the read feed to history
    await _updateHistoryState(previousItem);
    
    // Track reading history to backend
    log('[swiper] Should mark read: "${previousItem.displayTitle}"');
    fireAndForget(() => markRead(previousItem.cluster.id));
  }

  @override
  Widget build(BuildContext context) {
    // Listen for topic changes and trigger load feed with debounce
    ref.listen<FeedType>(feedTypeProvider, (previous, next) {
      if (!mounted || previous == next) return;
      final feedTotal = next.readItems(ref).length;
      debugPrint("current feedType: ${next.label} (topic: $_currentTopic)");
      debugPrint("current feedType length: $feedTotal");
      if (feedTotal > 0) {
        debugPrint("first feed: ${next.readItems(ref).first.title}");
      }
      debugPrint("cardsCount: $_cardsCount");
      debugPrint("initialIndex: $_initialItemIndex");
    });

    // Check for lazy loading trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerLazyLoad();
    });

    // When feed is loading
    if (_isLoading || _isFeedLoading) {
      return Column(
        children: [
          TrendingFeedsCard().center().expand(),
          Lottie.asset('assets/lottie/pulse.json', width: 150),
        ],
      );
    }

    // When feed is empty
    if (_feedItems.isEmpty) {
      // log('current feed type: ${ref.read(feedTypeProvider)}');
      return Column(
        children: [
          MyPlaceholder(
            'No articles available${_currentTopic == null ? ' right now' : ' in ${_currentTopic!.toCapitalized()}'}',
            footer: 'Try switching to different topics or check your internet connection.',
            icon: Icon(CupertinoIcons.news, size: 80, color: AppColors.accent),
            onRetry: widget.onReload,
            retryLabel: "Reload",
          ).center().expand(),
          if (_feedType != _homeFeedType) ...[
            MyDivider().withPaddingVertical(AppThemes.contentPadding),
            MyButton(
              text: "Back to ${_homeFeedType.label}",
              icon: Icon(CupertinoIcons.back),
              variant: MyButtonVariant.success,
              onPressed: widget.onSeeHome,
              outlined: true,
            )
          ],
        ],
      ).withPaddingAll(AppThemes.contentPadding);
    }

    log('_initialItemIndex = $_initialItemIndex');
    log('_cardsCount = $_cardsCount');
    log('_canGoNext = $_canGoNext');
    log('_canGoPrev = $_canGoPrev');
    // log('Swipe direction: $_swipeDirection, Undo direction: $_undoDirection');

    return CardSwiper(
      key: Key("CardSwiper_${_feedType}_{$_currentTopic}_$_initialItemIndex}_${_swipeDirection.name}"),
      controller: _controller,
      padding: EdgeInsets.zero,
      showBackCardOnUndo: true,
      undoSwipeThreshold: 15,
      threshold: 70,
      undoDirection: _undoDirection,
      allowedSwipeDirection: AllowedSwipeDirection.only(
        left: _swipeDirection == CardSwiperDirection.left ? _canGoNext : _canGoPrev,
        right: _swipeDirection == CardSwiperDirection.right ? _canGoNext : _canGoPrev,
      ),
      initialIndex: _initialItemIndex,
      numberOfCardsDisplayed: _cardsCount == 1 ? 1 : 2,
      cardsCount: _cardsCount + 1,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        if (index == _cardsCount) return SizedBox.shrink();
        return FeedCard(
          _feedType,
          feedItem: _isDigestFeed && index == _feedItems.length ? null : _feedItems[index],
          onSeeLatest: widget.onSeeLatest,
        );
      },
      isDisabled: false,
      isLoop: false,
      onEnd: requestReview,
      onSwipe: (previousIndex, currentIndex, direction) async {
        final previousItem = _feedItems[previousIndex];
        // log('[feed] Swipe direction: $direction, previousItem: ${previousItem.title}');
        // log('[feed] Swiped item: ${previousItem.title}');

        // When an undo swipe is detected
        if (direction != _swipeDirection) {
          // Trigger the undo action on the controller
          _controller.undo();
          _decreaseReadCount(previousItem);
          
          // Return false to prevent the default swipe action
          return false;
        }

        _incrementReadCount(previousItem);

        return true;
      },
    );
  }
}