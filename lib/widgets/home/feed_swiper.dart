import 'dart:developer' show log;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/feed.dart' show feedProvider;
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/feeds.dart';
import 'package:muslimdigest/utils/format.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/widgets/components/cached_image.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';
import '../../widgets/animations/loader.dart';
import '../../widgets/components/placeholder.dart';
import '../../models/feed.dart';

final SWIPE_DIRECTION = CardSwiperDirection.left;
final UNDO_DIRECTION = SWIPE_DIRECTION == CardSwiperDirection.left ? CardSwiperDirection.right : CardSwiperDirection.left;

/// Feed swiper widget for displaying news cards with swipe navigation
class FeedSwiper extends ConsumerStatefulWidget {
  final VoidCallback onReload;
  
  const FeedSwiper({super.key, 
    required this.onReload,
  });

  @override
  ConsumerState<FeedSwiper> createState() => FeedSwiperState();
}

class FeedSwiperState extends ConsumerState<FeedSwiper> {
  final _controller = CardSwiperController();

  AppRepository get r => ref.read(appRepositoryProvider);

  bool get _isFeedLoading => ref.watch(feedProvider).isLoading;
  int get _readCount => ref.watch(readCountProvider);
  bool get _canGoBack => _readCount > 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _incrementReadCount(String lastClusterId) async {
    final readCount = ref.read(readCountProvider);
    final newCount = (readCount + 1).clamp(0, DAILY_READ_TARGET);
    await Future.wait([
      if (newCount == DAILY_READ_TARGET) logStreak(ref),
      ref.read(readCountProvider.notifier).setValue(newCount),
      ref.read(readLastDateProvider.notifier).setValue(today),
    ]);
    
    // Track reading history to backend
    markRead(lastClusterId);
  }

  Future<void> _decreaseReadCount() async {
    final readCount = ref.read(readCountProvider);
    if (readCount == 0) return;
    await ref.read(readCountProvider.notifier).setValue(readCount - 1);
  }

  @override
  Widget build(BuildContext context) {

    // When feed is empty
    if (r.feedDigest.isEmpty) {
      if (_isFeedLoading) {
        return MyLoader().center();
      }

      // Display empty feed placeholder
      return MyPlaceholder(
        'No articles available',
        icon: Icon(CupertinoIcons.news, size: 80, color: AppColors.accent),
        onRetry: widget.onReload,
        retryLabel: "Reload",
      ).center();
    }

    if (_isFeedLoading) {
      // TODO: small non-disruptive loader
      return MyLoader().center();
    }

    final cardsCount = r.feedDigest.length + 1;

    return CardSwiper(
      key: Key("CardSwiper_$_readCount"),
      controller: _controller,
      padding: EdgeInsets.zero,
      showBackCardOnUndo: true,
      undoSwipeThreshold: 15,
      undoDirection: UndoDirection.right,
      allowedSwipeDirection: AllowedSwipeDirection.only(
        left: SWIPE_DIRECTION == CardSwiperDirection.left || _canGoBack,
        right: SWIPE_DIRECTION == CardSwiperDirection.right || _canGoBack
      ),
      initialIndex: _readCount,
      cardsCount: cardsCount,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        if (index == cardsCount - 1) {
          return FeedCard();
        }
        return FeedCard(feedItem: r.feedDigest[index]);
      },
      isDisabled: false,
      isLoop: false,
      onEnd: () {
        log('[feed] ENDED!');
      },
      onSwipe: (previousIndex, currentIndex, direction) async {
        final previousItem = r.feedDigest[previousIndex];
        log('[feed] Swipe direction: $direction, previousItem: ${previousItem.title}');

        // When an undo swipe is detected
        if (direction == UNDO_DIRECTION) {
          // Trigger the undo action on the controller
          _controller.undo();
          _decreaseReadCount();
          
          // Return false to prevent the default swipe action
          return false;
        }

        if (direction == SWIPE_DIRECTION) {
          log('[feed] Swiped item: ${previousItem.title}');
          _incrementReadCount(previousItem.cluster.id);
        }
        return true;
      },
    );
  }
}

/// Individual feed card widget
class FeedCard extends StatelessWidget {
  final FeedItem? feedItem;

  const FeedCard({
    super.key,
    this.feedItem,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Container(
      decoration: BoxDecoration(
        color: h.currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: feedItem == null ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: end card
          Text("End of feed", textAlign: TextAlign.center, style: h.currentTextTheme.titleMedium)
        ],
      ) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and title
          _FeedHeader(feedItem: feedItem!),
          
          // Content with article text and badges
          _FeedContent(feedItem: feedItem!).expand(),
          
          // Footer with source and actions buttons
          _FeedFooter(feedItem: feedItem!),
        ],
      ),
    );
  }
}

/// Feed header containing image and title
class _FeedHeader extends StatelessWidget {
  final FeedItem feedItem;

  const _FeedHeader({required this.feedItem});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // Image
          CachedImageWidget(
            imageUrl: feedItem.image,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          
          // Title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(AppThemes.contentPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Text(
                feedItem.title,
                style: h.currentTextTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feed content with article text and badges
class _FeedContent extends StatelessWidget {
  final FeedItem feedItem;

  const _FeedContent({required this.feedItem});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppThemes.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article text
          formatText(
            feedItem.summary,
            style: h.currentTextTheme.bodyMedium
          ),
          const SizedBox(height: 16),
          
          // Badges
          if (feedItem.badges.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: feedItem.badgeToDisplay.map((badge) {
                return _FeedBadgeChip(badge);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Feed footer with source and summarizer information
class _FeedFooter extends StatelessWidget {
  final FeedItem feedItem;

  const _FeedFooter({required this.feedItem});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Divider(height: 1, thickness: 1, color: h.currentTheme.colorScheme.outline),
            _FeedFooterSource(feedItem).moveX(-8),
          ],
        ),
        Row(children: [
          // Summarizer info
          if (feedItem.summaryProvider != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Summarizer: ${feedItem.summaryProvider!.toCapitalized()}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          // Action buttons
          ...<Widget>[
            MyIconButton(icon: CupertinoIcons.heart, size: 50, outlined: true, onPressed: () {},),
            MyIconButton(icon: CupertinoIcons.bookmark, size: 50, outlined: true, onPressed: () {},),
            MyIconButton(icon: CupertinoIcons.share, size: 50, outlined: true, onPressed: () {},),
          ].addItemInBetween(SizedBox(width: 8)),
        ],)
      ],
    ).withPaddingAll(AppThemes.contentPadding - 8);
  }
}

class _FeedFooterSource extends StatelessWidget {
  final FeedItem feedItem;

  const _FeedFooterSource(this.feedItem);

  @override
  Widget build(BuildContext context) {
    final sourceLink = feedItem.sourceLink;
    final h = MyHelper(context);

    return Material(
      color: h.currentTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: sourceLink == null ? null : () => openUrl(sourceLink),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Source site icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedImageWidget(
                  imageUrl: feedItem.source.siteIcon,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(
                    CupertinoIcons.globe,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Source site name
            Text(
              feedItem.sourceLabel,
              style: h.currentTextTheme.bodySmall?.copyWith(
                // fontSize: 12,
                // color: Colors.black87,
                // fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ).withPadding(horizontal: 8, vertical: 4),
      ),
    );
  }
}

class _FeedBadgeChip extends StatelessWidget {
  final String badge;
  
  const _FeedBadgeChip(this.badge);

  List<String> get _badgeSplit => badge.split(':');
  String get _badgeLabel => _badgeSplit[0];
  String get _badgeValue => _badgeSplit[1];

  String get _badgeText {
    final labelCapitalized = _badgeLabel.unslugTitleCase();
    final valueCapitalized = _badgeValue.unslugTitleCase();
    if (_badgeLabel == 'madhhab') return '$valueCapitalized Fiqh';
    return '$labelCapitalized: $valueCapitalized';
  }

  String get _badgeDescription {
    // TODO: Implement description logic based on _badgeLabel and _badgeValue
    return '';
  }

  MaterialColor get _badgeColor {
    // TODO: Implement color logic based on _badgeLabel and _badgeValue
    switch (_badgeValue) {
      case 'high': return Colors.red;
      case 'medium': case 'requires_review': return Colors.orange;
      case 'low': case 'verified': return Colors.green;
      case 'unverified': return Colors.blueGrey;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _badgeDescription,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: _badgeColor[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _badgeColor[200]!),
        ),
        child: Text(
          _badgeText,
          style: TextStyle(
            fontSize: 12,
            color: _badgeColor[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}