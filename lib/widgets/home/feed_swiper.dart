import 'dart:developer' show log;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/base_feed_notifier.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/read_last_date.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/utils/format.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/utils/time.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/widgets/components/cached_image.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';
import 'package:muslimdigest/widgets/components/logo.dart';
import 'package:muslimdigest/widgets/components/popup_menu_item.dart';
import 'package:muslimdigest/widgets/components/popup_menu.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/animations/loader.dart';
import '../../widgets/components/placeholder.dart';
import '../../models/feed.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

final SWIPE_DIRECTION = CardSwiperDirection.left;
final UNDO_DIRECTION = SWIPE_DIRECTION == CardSwiperDirection.left ? CardSwiperDirection.right : CardSwiperDirection.left;

/// Feed swiper widget for displaying news cards with swipe navigation
class FeedSwiper extends ConsumerStatefulWidget {
  final VoidCallback onReload;
  final FeedType feedType;
  
  const FeedSwiper({super.key, 
    required this.onReload,
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

    // TODO: `MyLoader()` is not gone when feed has been loaded

    // When feed is empty
    if (_feedItems.isEmpty) {
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
        return FeedCard(widget.feedType, feedItem: index == cardsCount - 1 ? null : _feedItems[index]);
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

/// Individual feed card widget
class FeedCard extends ConsumerStatefulWidget {
  final FeedType feedType;
  final FeedItem? feedItem;

  const FeedCard(this.feedType, {
    super.key,
    this.feedItem,
  });

  @override
  ConsumerState<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<FeedCard> with AutomaticKeepAliveClientMixin {
  final _screenshotController = ScreenshotController();
  late final _feedId = widget.feedItem?.id;
  bool _isTakingScreenshot = false;

  @override
  bool get wantKeepAlive => true;

  BaseFeedNotifier get _notifier => widget.feedType.getNotifier(ref);
  
  bool get _isLiked {
    if (_feedId == null) return false;
    final currentItem = widget.feedType.readItem(ref, _feedId);
    return currentItem?.isLiked ?? false;
  }
  
  bool get _isSaved {
    if (_feedId == null) return false;
    final currentItem = widget.feedType.readItem(ref, _feedId);
    return currentItem?.isSaved ?? false;
  }

  void _like() async {
    if (_feedId == null) return;
    await _notifier.update(_feedId, isLiked: !_isLiked);
  }

  void _save() async {
    if (_feedId == null) return;
    await _notifier.update(_feedId, isSaved: !_isSaved);
  }

  Future<void> _share() async {
    if (_feedId == null) return;

    setState(() => _isTakingScreenshot = true);

    // Wait for the feed to be fully rendered
    await delay(100);

    // Take the screenshot of feed
    final imagePath = await _screenshot();
    if (!mounted) return;

    setState(() => _isTakingScreenshot = false);
    if (imagePath == null) return;

    // Share the feed
    await sharePlus.share(
      ShareParams(
        title: widget.feedItem!.title,
        subject: 'Read "${widget.feedItem!.title}" in $APP_NAME',
        files: [XFile(imagePath)],
        text:
          'Hi, I just read "${widget.feedItem!.title}" in $APP_NAME.\n'
          'Check out the app to level up your Islamic knowledge with daily high-quality digests:\n'
          '$APP_URL_PLAYSTORE',
      ),
    );
  }

  Future<String?> _screenshot() async {
    final imageName = "$_feedId.png";
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await _screenshotController.captureAndSave(directory.path, fileName: imageName);
    if (mounted && imagePath == null) {
      showSnackBar(context, "Cannot save feed image.");
    }
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      child: widget.feedItem == null ? Column(
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
          _FeedHeader(feedItem: widget.feedItem!),
          
          // Content with article text and badges
          _FeedContent(feedItem: widget.feedItem!).expand(),
          
          // Footer with source and actions buttons
          _FeedFooter(
            feedType: widget.feedType,
            feedItem: widget.feedItem!,
            isTakingScreenshot: _isTakingScreenshot,
            onShare: _share,
            onSave: _save,
            onLike: _like,
          ),
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
            errorColor: h.currentTheme.colorScheme.secondary,
            errorChild: Logo(),
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
class _FeedFooter extends ConsumerWidget {
  final FeedType feedType;
  final FeedItem feedItem;
  final bool isTakingScreenshot;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onLike;

  const _FeedFooter({
    required this.feedType,
    required this.feedItem,
    required this.isTakingScreenshot,
    required this.onShare,
    required this.onSave,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);

    // Listen to provider state for real-time updates
    final currentFeedItem = feedType.watch(ref).getItem(feedItem.id) ?? feedItem;
    final isLiked = currentFeedItem.isLiked;
    final isSaved = currentFeedItem.isSaved;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Divider(height: 1, thickness: 1, color: h.currentTheme.colorScheme.outline),
            _FeedFooterSource(currentFeedItem).moveX(-8).left(),
            MyPopupMenu(
              icon: Icon(CupertinoIcons.ellipsis, color: h.currentTheme.colorScheme.tertiary),
              onSelected: (String value) {
                _handleMenuAction(context, value);
              },
              items: [
                MyPopupMenuItem(
                  value: 'not_interested',
                  icon: CupertinoIcons.hand_thumbsdown,
                  text: 'Not interested',
                ),
                MyPopupMenuItem(
                  value: 'dont_recommend_source',
                  icon: CupertinoIcons.eye_slash,
                  text: "Don't recommend source",
                ),
                MyPopupMenuItem(
                  value: 'send_feedback',
                  icon: CupertinoIcons.chat_bubble_text,
                  text: 'Send feedback',
                ),
                MyPopupMenuItem(
                  value: 'report',
                  icon: CupertinoIcons.exclamationmark_triangle,
                  text: 'Report',
                ),
              ],
            ).right(),
          ],
        ),

        // SizedBox(height: 8,),

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
          if (!isTakingScreenshot) ...<Widget>[
            MyIconButton(icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart, size: 50, outlined: true, onPressed: onLike, iconColor: isLiked ? AppColors.primary : null),
            MyIconButton(icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark, size: 50, outlined: true, onPressed: onSave, iconColor: isSaved ? AppColors.primary : null),
            MyIconButton(icon: CupertinoIcons.share, size: 50, outlined: true, onPressed: onShare,),
          ].addItemInBetween(SizedBox(width: 8)),
        ],),

        SizedBox(height: 8,),
      ],
    ).withPaddingAll(AppThemes.contentPadding - 8);
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'not_interested':
        // TODO: Implement "Not interested" functionality
        showSnackBar(context, 'Marked as not interested');
        break;
      case 'dont_recommend_source':
        // TODO: Implement "Don't recommend source" functionality
        showSnackBar(context, "Won't recommend this source");
        break;
      case 'send_feedback':
        // TODO: Implement "Send feedback" functionality
        showSnackBar(context, 'Feedback form opened');
        break;
      case 'report':
        // TODO: Implement "Report" functionality
        showSnackBar(context, 'Report submitted');
        break;
    }
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
              style: h.currentTextTheme.bodySmall,
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