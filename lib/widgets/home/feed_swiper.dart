import 'package:flutter/cupertino.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/api/user.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/home/feed_card.dart';
import 'package:muslimdigest/widgets/home/trending_card.dart';
import '../../widgets/components/placeholder.dart';
import '../../models/feed.dart';
import '../../providers/feed/feed_latest.dart';

/// Feed swiper widget for displaying news cards with swipe navigation
class FeedSwiper extends ConsumerStatefulWidget {
  final VoidCallback onReload;
  final VoidCallback onSeeLatest;
  final VoidCallback onSeeHome;
  final FeedType feedType;
  
  const FeedSwiper({super.key, 
    required this.onReload,
    required this.onSeeLatest,
    required this.onSeeHome,
    required this.feedType,
  });

  @override
  ConsumerState<FeedSwiper> createState() => FeedSwiperState();
}

class FeedSwiperState extends ConsumerState<FeedSwiper> {
  final _controller = CardSwiperController();
  final _readCountStates = <String, int>{};

  // Feed type
  // bool get _isHomeFeed => widget.feedType == _homeFeedType;
  bool get _isDigestFeed => widget.feedType == FeedType.digest;
  // bool get _isDailyDigest => _isDigestFeed && _currentTopic == null;
  // bool get _isTopicDigest => _isDigestFeed && _currentTopic != null;
  bool get _isLatestFeed => widget.feedType == FeedType.latest;
  bool get _isTopicFeed => _isLatestFeed && _currentTopic != null;
  // bool get _isTrendingFeed => widget.feedType == FeedType.trending;

  // Feed states
  // TODO: cache feed per type & topic
  List<FeedItem> get _feedItems => widget.feedType.watchItems(ref);
  bool get _isFeedLoading => widget.feedType.watch(ref).isLoading;
  int get _readCount => ref.watch(readCountProvider);
  FeedType get _homeFeedType => ref.read(appRepositoryProvider).homeFeedType;
  String? get _currentTopic => ref.watch(topicProvider);
  int get _cardsCount => _isDigestFeed && _feedItems.length == DAILY_READ_TARGET
    ? _feedItems.length + 1
    : _feedItems.length;

  // Read state
  String get _readCountName => _isTopicFeed ? _currentTopic! : widget.feedType.name;
  int get _readCountState => _readCountStates[_readCountName] ?? 0;
  int get _currentItemIndex => _isDigestFeed ? _readCount : _readCountState;
  int get _initialItemIndex => _cardsCount == 0 ? 0 : _currentItemIndex.clamp(0, _cardsCount - 1);
  bool get _canGoPrev => _currentItemIndex > 0;
  bool get _canGoNext => _currentItemIndex < _cardsCount - 1;
  bool get _canUndo => _canGoPrev;

  int get _currentPage => _currentItemIndex % CURSOR_PAGINATION_LIMIT;

  // User settings
  UserSettings get _settings => ref.watch(settingsProvider);
  CardSwiperDirection get _swipeDirection => _settings.swipeDirection == SwipeDirection.left ? CardSwiperDirection.left : CardSwiperDirection.right;
  UndoDirection get _undoDirection => _swipeDirection == CardSwiperDirection.left ? UndoDirection.right : UndoDirection.left;

  // Lazy loading
  bool get _shouldTriggerLazyLoad {
    if (_isDigestFeed) return false;
    // TODO: implement infinity lazy load, except for _isDigestFeed

    if (widget.feedType != FeedType.latest) return false;
    
    final feedState = ref.read(feedLatestProvider);
    if (!feedState.hasMore || feedState.isLoadingMore) return false;
    
    // Trigger when _currentItemIndex is 3 pages before CURSOR_PAGINATION_LIMIT * _currentPage
    final threshold = (CURSOR_PAGINATION_LIMIT * _currentPage) - 3;
    return _currentItemIndex >= threshold && _currentItemIndex < _feedItems.length - 3;
  }

  Future<void> _triggerLazyLoad() async {
    if (_shouldTriggerLazyLoad) {
      await ref.read(feedLatestProvider.notifier).loadMore();
    }
  }

  @override
  void didUpdateWidget(covariant FeedSwiper oldWidget) {
    if (oldWidget.feedType != widget.feedType) {
      // Reset initialIndex to 0 when feed type changes
      // Note: initialIndex is not directly accessible on CardSwiperController
      // We'll handle this by rebuilding the swiper with new key
      final feedTotal = widget.feedType.readItems(ref).length;
      debugPrint("Resetting swiper to index 0");
      debugPrint("current feedType: ${widget.feedType.label}");
      debugPrint("current feedType length: $feedTotal");
      if (feedTotal > 0) {
        debugPrint("first feed: ${widget.feedType.readItems(ref).first.title}");
      }
      debugPrint("cardsCount: $_cardsCount");
      debugPrint("initialIndex: $_initialItemIndex");
      // setState(() {
      //   _controller.moveTo(_initialItemIndex);
      // });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _incrementReadCount(String lastClusterId) async {
    if (widget.feedType == FeedType.digest) {
      final readLastDate = ref.read(readLastDateProvider) ?? today;
      final readCount = ref.read(readCountProvider);
      final newCount = isToday(readLastDate) ? (readCount + 1).clamp(0, DAILY_READ_TARGET) : 1;
      await Future.wait([
        if (newCount == DAILY_READ_TARGET) logStreak(ref),
        ref.read(readCountProvider.notifier).setValue(newCount),
        ref.read(readLastDateProvider.notifier).setValue(today),
      ]);
    } else {
      setState(() {
        _readCountStates.addAll({
          _readCountName: _readCountState + 1,
        });
      });
    }
    
    // Track reading history to backend
    fireAndForget(() => markRead(lastClusterId));
  }

  Future<void> _decreaseReadCount() async {
    if (widget.feedType == FeedType.digest) {
      final readCount = ref.read(readCountProvider);
      if (readCount == 0) return;
      await ref.read(readCountProvider.notifier).setValue(readCount - 1);
    } else if (_readCountState > 0) {
      setState(() {
        _readCountStates.addAll({
          _readCountName: _readCountState - 1,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for lazy loading trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerLazyLoad();
    });

    // When feed is loading
    if (_isFeedLoading) {
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
          if (widget.feedType != _homeFeedType) ...[
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

    return CardSwiper(
      key: Key("CardSwiper_$_currentItemIndex"),
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
      numberOfCardsDisplayed: _cardsCount == 1 ? 1 : 2,
      cardsCount: _cardsCount,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return FeedCard(
          widget.feedType,
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
        
        // Trigger lazy loading after swipe
        _triggerLazyLoad();
        
        return true;
      },
    );
  }
}