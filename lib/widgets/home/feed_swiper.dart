import 'dart:developer' show log;

import 'package:flutter/cupertino.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/home/feed_card.dart';
import 'package:muslimdigest/widgets/home/trending_card.dart';
import '../../widgets/components/placeholder.dart';
import '../../models/feed.dart';

final SWIPE_DIRECTION = CardSwiperDirection.left;
final UNDO_DIRECTION = SWIPE_DIRECTION == CardSwiperDirection.left ? CardSwiperDirection.right : CardSwiperDirection.left;

/// Feed swiper widget for displaying news cards with swipe navigation
class FeedSwiper extends ConsumerStatefulWidget {
  final VoidCallback onReload;
  final VoidCallback onBackToDigest;
  final FeedType feedType;
  
  const FeedSwiper({super.key, 
    required this.onReload,
    required this.onBackToDigest,
    required this.feedType,
  });

  @override
  ConsumerState<FeedSwiper> createState() => FeedSwiperState();
}

class FeedSwiperState extends ConsumerState<FeedSwiper> {
  final _controller = CardSwiperController();

  List<FeedItem> get _feedItems => widget.feedType.watchItems(ref);
  bool get _isFeedLoading => widget.feedType.watch(ref).isLoading;
  int get _readCount => ref.watch(readCountProvider);
  bool get _canGoBack => _readCount > 0;

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
    }
    
    // Track reading history to backend
    fireAndForget(() => markRead(lastClusterId));
  }

  Future<void> _decreaseReadCount() async {
    final readCount = ref.read(readCountProvider);
    if (readCount == 0) return;
    await ref.read(readCountProvider.notifier).setValue(readCount - 1);
  }

  @override
  Widget build(BuildContext context) {

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
            'No articles available',
            icon: Icon(CupertinoIcons.news, size: 80, color: AppColors.accent),
            onRetry: widget.onReload,
            retryLabel: "Reload",
          ).center().expand(),
          MyDivider().withPaddingVertical(AppThemes.contentPadding),
          MyButton(
            text: "Back to digest",
            icon: Icon(CupertinoIcons.back),
            variant: MyButtonVariant.success,
            onPressed: widget.onBackToDigest,
          )
        ],
      ).withPaddingAll(AppThemes.contentPadding);
    }

    final cardsCount = _feedItems.length + 1;

    return CardSwiper(
      key: Key("CardSwiper_$_readCount"),
      controller: _controller,
      padding: EdgeInsets.zero,
      showBackCardOnUndo: true,
      undoSwipeThreshold: 15,
      threshold: 70,
      undoDirection: UndoDirection.right,
      allowedSwipeDirection: AllowedSwipeDirection.only(
        left: SWIPE_DIRECTION == CardSwiperDirection.left || _canGoBack,
        right: SWIPE_DIRECTION == CardSwiperDirection.right || _canGoBack
      ),
      initialIndex: _readCount,
      cardsCount: cardsCount,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return FeedCard(
          widget.feedType,
          feedItem: index == cardsCount - 1 ? null : _feedItems[index],
          onReload: widget.onReload,
        );
      },
      isDisabled: false,
      isLoop: false,
      onEnd: () {
        log('[feed] ENDED!');
      },
      onSwipe: (previousIndex, currentIndex, direction) async {
        final previousItem = _feedItems[previousIndex];
        // log('[feed] Swipe direction: $direction, previousItem: ${previousItem.title}');

        // When an undo swipe is detected
        if (direction == UNDO_DIRECTION) {
          // Trigger the undo action on the controller
          _controller.undo();
          _decreaseReadCount();
          
          // Return false to prevent the default swipe action
          return false;
        }

        if (direction == SWIPE_DIRECTION) {
          // log('[feed] Swiped item: ${previousItem.title}');
          _incrementReadCount(previousItem.cluster.id);
        }
        return true;
      },
    );
  }
}