import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/settings.dart';
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
  int get _cardsCount => _isDigestFeed && _feedItems.length == DAILY_READ_TARGET
    ? _feedItems.length + 1
    : _feedItems.length;

  // Read state
  Map<String, int> get _readCountStates => ref.watch(readCountStatesProvider);
  String get _readCountName => _isTopicFeed ? _currentTopic! : _feedType.name;
  int get _readCountState => _readCountStates[_readCountName] ?? 0;
  int get _currentItemIndex => _isDigestFeed ? _readCount : _readCountState;
  int get _initialItemIndex => _cardsCount == 0 ? 0 : _currentItemIndex.clamp(0, _cardsCount - 1);
  int get _currentPage => _currentItemIndex % CURSOR_PAGINATION_LIMIT;
  
  bool get _canGoPrev => _cardsCount > 1 && _currentItemIndex > 0;
  bool get _canGoNext => _cardsCount > 1 && _currentItemIndex < _cardsCount - 1;
  bool get _canUndo => _canGoPrev;

  // User settings
  UserSettings get _settings => ref.watch(settingsProvider);
  CardSwiperDirection get _swipeDirection => _settings.swipeDirection == SwipeDirection.left ? CardSwiperDirection.left : CardSwiperDirection.right;
  UndoDirection get _undoDirection => _swipeDirection == CardSwiperDirection.left ? UndoDirection.right : UndoDirection.left;

  // Lazy loading
  bool get _shouldTriggerLazyLoad {
    if (_isDigestFeed) return false;
    
    final feedState = _feedType.read(ref);
    if (!feedState.hasMore || feedState.isLoadingMore) return false;
    
    final threshold = (CURSOR_PAGINATION_LIMIT * _currentPage) - CURSOR_PAGINATION_TRIGGER;
    return _currentItemIndex >= threshold && _currentItemIndex < _feedItems.length - CURSOR_PAGINATION_TRIGGER;
  }

  Future<void> _triggerLazyLoad() async {
    if (_shouldTriggerLazyLoad) {
      await _feedType.getNotifier(ref).loadMore();
    }
  }

  // @override
  // void didUpdateWidget(covariant FeedSwiper oldWidget) {
  //   if (oldWidget.feedType != widget.feedType) {
  //     // Reset initialIndex to 0 when feed type changes
  //     // Note: initialIndex is not directly accessible on CardSwiperController
  //     // We'll handle this by rebuilding the swiper with new key
  //     final feedTotal = widget.feedType.readItems(ref).length;
  //     debugPrint("Resetting swiper to index 0");
  //     debugPrint("current feedType: ${widget.feedType.label}");
  //     debugPrint("current feedType length: $feedTotal");
  //     if (feedTotal > 0) {
  //       debugPrint("first feed: ${widget.feedType.readItems(ref).first.title}");
  //     }
  //     debugPrint("cardsCount: $_cardsCount");
  //     debugPrint("initialIndex: $_initialItemIndex");
  //     // setState(() {
  //     //   _controller.moveTo(_initialItemIndex);
  //     // });
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _incrementReadCount(String lastClusterId) async {
    if (_isDigestFeed) {
      final readCount = ref.read(readCountProvider);
      final newCount = (readCount + 1).clamp(0, DAILY_READ_TARGET);
      await Future.wait([
        if (newCount == DAILY_READ_TARGET) logStreak(ref),
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
    
    // Track reading history to backend
    fireAndForget(() => markRead(lastClusterId));
  }

  Future<void> _decreaseReadCount() async {
    if (_isDigestFeed) {
      final readCount = ref.read(readCountProvider);
      if (readCount == 0) return;
      await ref.read(readCountProvider.notifier).setValue(readCount - 1);
    } else if (_readCountState > 0) {
      await ref.read(readCountStatesProvider.notifier).update({
        _readCountName: _readCountState - 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for topic changes and trigger load feed with debounce
    ref.listen<FeedType>(feedTypeProvider, (previous, next) {
      if (!mounted || previous == next) return;
      final feedTotal = next.readItems(ref).length;
      debugPrint("current feedType: ${next.label}");
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
            )
          ],
        ],
      ).withPaddingAll(AppThemes.contentPadding);
    }

    final _numberOfCardsDisplayed = _cardsCount == 1 ? 1 : 2;

    log('_initialItemIndex = $_initialItemIndex');
    log('_numberOfCardsDisplayed = $_numberOfCardsDisplayed');
    log('_cardsCount = $_cardsCount');
    // [log] _initialItemIndex = 8
    // [log] _numberOfCardsDisplayed = 2
    // [log] _cardsCount = 9

    return CardSwiper(
      key: Key("CardSwiper_${_feedType}_{$_currentTopic}_$_currentItemIndex"),
      controller: _controller,
      padding: EdgeInsets.zero,
      showBackCardOnUndo: true,
      undoSwipeThreshold: 15,
      threshold: 70,
      undoDirection: _undoDirection,
      allowedSwipeDirection: AllowedSwipeDirection.only(
        left: _swipeDirection == CardSwiperDirection.left ? _canGoNext : _canUndo,
        right: _swipeDirection == CardSwiperDirection.right ? _canGoNext : _canUndo
      ),
      initialIndex: _initialItemIndex,
      numberOfCardsDisplayed: _numberOfCardsDisplayed,
      cardsCount: _cardsCount,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return FeedCard(
          _feedType,
          feedItem: _isDigestFeed && index == DAILY_READ_TARGET ? null : _feedItems[index],
          onSeeLatest: widget.onSeeLatest,
        );
      },
      isDisabled: false,
      isLoop: false,
      onEnd: requestReview,
      onSwipe: (previousIndex, currentIndex, direction) async {
        // Skip swipe processing for the extra congratulations card in digest
        // if (_isDigest && previousIndex == DAILY_READ_TARGET) {
        //   return true;
        // }
        
        final previousItem = _feedItems[previousIndex];
        // log('[feed] Swipe direction: $direction, previousItem: ${previousItem.title}');

        // When an undo swipe is detected
        if (direction != _swipeDirection) {
          // Trigger the undo action on the controller
          _controller.undo();
          _decreaseReadCount();
          
          // Return false to prevent the default swipe action
          return false;
        }

        // log('[feed] Swiped item: ${previousItem.title}');
        _incrementReadCount(previousItem.cluster.id);
        
        return true;
      },
    );
  }
}