import 'dart:developer' show log;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/config/feeds.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count_states.dart';
import 'package:muslimdigest/providers/topic.dart';
import 'package:muslimdigest/utils/contents.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/settings.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/timeago/timeago.dart';
import 'package:muslimdigest/utils/app.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/format.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/variables/time.dart';
import 'package:muslimdigest/widgets/components/badge.dart';
import 'package:muslimdigest/widgets/components/button.dart';
import 'package:muslimdigest/widgets/components/cached_image.dart';
import 'package:muslimdigest/widgets/components/card.dart';
import 'package:muslimdigest/widgets/components/divider.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';
import 'package:muslimdigest/widgets/components/logo.dart';
import 'package:muslimdigest/widgets/components/popup_menu_item.dart';
import 'package:muslimdigest/widgets/components/popup_menu.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';
import 'package:muslimdigest/widgets/home/feedback_form.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/widgets/collections/collection_selection_sheet.dart';
import 'package:muslimdigest/widgets/user/reads_rank.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/feed.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// Individual feed card widget
class FeedCard extends ConsumerStatefulWidget {
  final FeedType feedType;
  final FeedItem? feedItem;
  final VoidCallback? onSeeLatest;

  const FeedCard(this.feedType, {
    super.key,
    this.feedItem,
    this.onSeeLatest,
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
    
    try {
      await _notifier.update(_feedId, isLiked: !_isLiked);
    } catch (e) {
      // Silent error handling - UI will revert automatically on state rebuild
      log('[FeedCard] Like update failed: $e');
    }
  }

  void _save() async {
    if (_feedId == null) return;
    
    // Predefine the new save state to avoid ambiguity
    final isSaved = !_isSaved;
    
    // try {
      // Step 1: Save immediately (fire and forget, uncategorized)
      await _notifier.update(_feedId, isSaved: isSaved);
      
      // Step 2: If saving (not unsaving), show collection selection
      if (isSaved && mounted) {
        _showCollectionSelectionSheet();
      }
    // } catch (e) {
    //   // Silent error handling - UI will revert automatically on state rebuild
    //   log('[FeedCard] Save update failed: $e');
    // }
  }

  void _showCollectionSelectionSheet() {
    if (_feedId == null || widget.feedItem == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CollectionSelectionSheet(
        feedId: _feedId,
        feedTitle: widget.feedItem!.displayTitle,
        onCollectionSelected: (collection) {
          _updateFeedCollection(collection);
        },
        onCollectionCreated: _createCollectionAndSave,
      ),
    );
  }

  void _updateFeedCollection(String collection) async {
    if (_feedId == null) return;
    
    try {
      final success = await updateCollection(_feedId, collection);
      if (!mounted) return;
      if (success) {
        showSnackBarSuccess(context, 'Saved to "$collection"');
        
        // Update cache with collection information
        await FeedStateService.updateSaveStatusEverywhere(
          ref, 
          widget.feedItem!, 
          true, 
          specificCollection: collection,
          updateCache: true, // Enable cache updates now that collection is known
        );
      } else {
        showSnackBarError(context, 'Failed to update collection');
        // CRITICAL: Update cache even on API failure to maintain consistency
        // UI shows item as saved, so cache must reflect it
        await FeedStateService.updateSaveStatusEverywhere(
          ref, 
          widget.feedItem!, 
          true, 
          updateCache: true, // Ensure cache reflects UI state
        );
        log('[FeedCard] API failed but cache updated to maintain UI consistency');
      }
    } catch (e) {
      log('[FeedCard] Update collection failed: $e');
      if (mounted) {
        showSnackBarError(context, 'Failed to update collection');
      }
      // CRITICAL: Update cache even on exception to maintain consistency
      await FeedStateService.updateSaveStatusEverywhere(
        ref, 
        widget.feedItem!, 
        true, 
        updateCache: true, // Ensure cache reflects UI state
      );
      log('[FeedCard] Exception but cache updated to maintain UI consistency');
    }
  }

  Future<void> _createCollectionAndSave(String collection) async {
    if (_feedId == null) return;
    
    try {
      // Collections are created implicitly when saving with a new collection name
      // Just save directly to the new collection - backend will handle creation
      final success = await save(_feedId, true, collection: collection);
      if (!mounted) return;
      if (success) {
        showSnackBarSuccess(context, 'Created and saved to "$collection"');
        
        // Update cache with collection information using FeedStateService
        await FeedStateService.updateSaveStatusEverywhere(
          ref, 
          widget.feedItem!,
          true,
          specificCollection: collection,
          updateCache: true, // Enable cache updates now that collection is known
        );
      } else {
        showSnackBarError(context, 'Failed to save to new collection');
      }
    } catch (e) {
      log('[FeedCard] Create collection and save failed: $e');
      if (mounted) {
        showSnackBarError(context, 'Failed to create collection');
      }
    }
  }

  Future<void> _share() async {
    setState(() => _isTakingScreenshot = true);
    final imagePath = await _screenshot(); // Take the screenshot of feed
    if (!mounted) return;

    setState(() => _isTakingScreenshot = false);
    if (imagePath == null) return;

    // Share the feed
    final isShareReading = widget.feedItem != null;
    await sharePlus.share(
      ShareParams(
        title: widget.feedItem?.title ?? "I got my daily streak",
        subject: '${isShareReading ? 'Read "${widget.feedItem!.title}"' : 'I got my daily streak'} on $APP_NAME',
        files: [XFile(imagePath)],
        text:
          'Hi, I wanted to share with you my latest ${isShareReading ? 'read' : 'achievement'} on $APP_NAME.\n'
          '$SHARE_MESSAGE',
      ),
    );
  }

  Future<String?> _screenshot() async {
    String? imagePath;
    try {
      // Request appropriate storage permissions based on Android version
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        if (mounted) showSnackBarError(context, "Storage permission is required to save screenshots. Please enable it in settings.");
        return null;
      }
      
      // Use application documents directory for better compatibility
      final directory = await getApplicationDocumentsDirectory();
      final imageName = "${_feedId ?? 'streak'}_$todayString.png";
      
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Validate directory path
      if (directory.path.isEmpty) {
        log('[FeedCard] Error: Directory path is empty');
        if (mounted) showSnackBarError(context, "Cannot access storage directory. Please try again.");
        return null;
      }
      
      log('[FeedCard] Attempting screenshot to: ${directory.path}/$imageName');
      
      // Add delay to ensure widget is fully rendered
      await Future.delayed(Duration(milliseconds: 200));
      
      imagePath = await _screenshotController.captureAndSave(
        directory.path, 
        fileName: imageName,
        pixelRatio: 2.0,
        delay: Duration(milliseconds: 100),
      );
      
      if (mounted && imagePath == null) {
        showSnackBarError(context, "Cannot save image. Please try again.");
        return null;
      }
      
      log('[FeedCard] Screenshot saved to: $imagePath');
      return imagePath;
    } catch (e) {
      log('[FeedCard] Screenshot error: $e');
      if (mounted) {
        showSnackBarError(context, "Screenshot failed. Please try again.");
      }
      
      // CRITICAL: Clean up on failure to prevent memory leaks
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
            log('[FeedCard] Cleaned up failed screenshot: $imagePath');
          }
        } catch (cleanupError) {
          log('[FeedCard] Failed to cleanup screenshot: $cleanupError');
        }
      }
      
      return null;
    }
  }
  
  void _backToPageOne() {
    if (widget.feedType.isDigest) return widget.onSeeLatest?.call();
    final currentReadCountStates = ref.read(readCountStatesProvider);
    final currentTopic = ref.read(topicProvider);
    final isTopicTab = currentTopic != null;
    final readCountStateKey = isTopicTab ? currentTopic : widget.feedType.name;
    ref.read(readCountStatesProvider.notifier).setValue({
      ...currentReadCountStates,
      readCountStateKey: 0,
    });
    // Preserve the current topic when going back to page one so users stay in the same topic feed
    widget.feedType.load(ref, topic: currentTopic, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final h = MyHelper(context);
    final streaks = ref.read(streaksProvider);
    final currentStreak = streaks.currentStreak;
    final isDigest = widget.feedType.isDigest;
    final isExtraCard = widget.feedItem == null;

    // Determine if feed should be hidden
    final shouldShowPlaceholder = FeedStateService.shouldHideFeed(ref, widget.feedItem);
    final reason = shouldShowPlaceholder 
        ? FeedStateService.getNotInterestedReason(ref, widget.feedItem!.id)
        : null;

    // Check if this feed item should be hidden due to avoided source
    final preferences = ref.watch(preferencesProvider);
    final isSourceAvoided = preferences.avoidedSources.contains(widget.feedItem?.source);

    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: double.infinity,
        decoration: h.cardDecoration,
        padding: isExtraCard ? EdgeInsets.all(AppThemes.contentPadding) : EdgeInsets.zero,
        child: isExtraCard ? Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isDigest ? "Another day of beneficial knowledge." : "You've reached the end", textAlign: TextAlign.center, style: h.currentTextTheme.titleLarge),
            Text(MESSAGES[(currentStreak - 1) % MESSAGES.length], textAlign: TextAlign.center, style: h.currentTextTheme.bodyMedium),
            if (isDigest) StreaksCard() else UserReadsRank(textAlign: TextAlign.center,),
            // Lottie.asset('assets/lottie/streak.json').expand(),
            Lottie.asset('assets/lottie/streak.json').flexible(),
            if (!_isTakingScreenshot) DonateButton(outlined: true,),
            MyButton(
              text: isDigest ? "Continue reading" : "Back to Page One",
              icon: isDigest ? Icon(CupertinoIcons.book) : Icon(CupertinoIcons.refresh),
              onPressed: isDigest ? widget.onSeeLatest : _backToPageOne,
            ),
            MyDivider(),
            Row(
              children: _isTakingScreenshot ? [
                Text(PROMO_MESSAGE).expand(),
                Logo(size: 100,),
              ] : [
                Text("Do you want to share it?", style: h.currentTextTheme.bodySmall?.copyWith(fontSize: 16)).expand(),
                MyIconButton(icon: CupertinoIcons.share, onPressed: _share,)
              ],
            ),
          ].addItemInBetween(SizedBox(height: 16,)),
        ) : shouldShowPlaceholder ? _NotInterestedPlaceholder(
          feedType: widget.feedType,
          feedItem: widget.feedItem!,
          reason: reason,
          isSourceAvoided: isSourceAvoided,
        ).center() : Column(
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
      ),
    );
  }
}

/// Placeholder for feed items marked as not interested or reported
class _NotInterestedPlaceholder extends ConsumerWidget {
  final FeedType feedType;
  final FeedItem feedItem;
  final FeedbackCategory? reason;
  final bool isSourceAvoided;

  const _NotInterestedPlaceholder({
    required this.feedType,
    required this.feedItem,
    this.reason,
    this.isSourceAvoided = false,
  });

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    // Restore avoided source
    if (isSourceAvoided) {
      restoreAvoidedSource(context, ref, feedItem.source.id);
      return;
    }

    // Update local state immediately - unmark from all feed types
    if (context.mounted) {
      await FeedStateService.unmarkNotInterestedEverywhere(ref, feedItem.id);
    }
    
    // Fire-and-forget API call
    fireAndForget(() => unmarkNotInterested(feedItem.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReportedContent = reason != null && reason!.shouldHideFeed;
    final title = isReportedContent 
      ? 'Content reported: ${reason!.label}'
      : isSourceAvoided 
        ? 'Source marked as not interested'
        : 'Feed marked as not interested';
    final footer = isReportedContent
      ? 'Thank you for helping improve our content quality.'
      : 'We\'ll show less content like this in the future.';
    final icon = isReportedContent
      ? Icon(reason!.icon, size: 80, color: AppColors.accent)
      : Icon(CupertinoIcons.hand_thumbsdown, size: 80, color: AppColors.accent);
    
    final h = MyHelper(context);
    return MyPlaceholder(
      title,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(feedItem.displayTitle, textAlign: TextAlign.center, style: h.currentTextTheme.titleSmall,),
          _FeedFooterSource(feedItem),
        ].addItemInBetween(SizedBox(height: 8,)),
      ),
      footer: footer,
      icon: icon,
      onRetry: () => _undo(context, ref),
      retryLabel: "Undo",
    );
  }
}

/// Feed header containing image and title
class _FeedHeader extends ConsumerWidget {
  final FeedItem feedItem;

  const _FeedHeader({required this.feedItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final hasYouTubeVideo = feedItem.hasYouTubeVideo;
    final settings = ref.watch(settingsProvider);
    final textSize = settings.textSize.toDouble();
    final vibe = feedItem.vibe;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // Image or video
          CachedImageWidget(
            imageUrl: feedItem.displayImageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorColor: h.currentTheme.colorScheme.secondary,
            errorChild: Logo(),
          ),
          
          // YouTube play button
          if (hasYouTubeVideo)
            Image.asset('assets/images/youtube-play.png', width: 64).center().fill(),

          // Vibe animation overlay during Islamic event
          if (feedItem.isOngoing)
            FutureBuilder<bool>(
              future: doesAssetExist(feedItem.vibeAnimationAsset),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Lottie.asset(feedItem.vibeAnimationAsset, fit: BoxFit.contain),
                  );
                }
                return const SizedBox.shrink();
              },
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
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyBadge(text: vibe.title, description: vibe.description, color: vibe.color),
                  SizedBox(height: 8,),
                  Text(
                    feedItem.displayTitle,
                    style: h.currentTextTheme.titleMedium?.copyWith(
                      fontSize: textSize * TITLE_TEXT_SIZE_MULTIPLIER,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4,),
                  Text(feedItem.readTimeLabel, style: h.currentTextTheme.bodySmall?.copyWith(fontSize: textSize * .6, color: Colors.white70)),
                ],
              ),
            ),
          ),

          // Image URL overlay
          // if (APP_IN_DEVELOPMENT && feedItem.relatedEvent != null) Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     padding: EdgeInsets.all(AppThemes.contentPadding),
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: [
          //           Colors.transparent,
          //           Colors.black.withValues(alpha: 0.7),
          //         ],
          //       ),
          //     ),
          //     child: Text(
          //       feedItem.relatedEvent!.title,
          //       style: h.currentTextTheme.titleSmall?.copyWith(
          //         color: Colors.white,
          //       ),
          //       maxLines: 2,
          //       overflow: TextOverflow.ellipsis,
          //     ),
          //   ).onTap(() {
          //     debugPrint('🧾 Feed info:');
          //     debugPrint('🧾 title: ${feedItem.title}');
          //     debugPrint('🧾 video title: ${feedItem.videoTitle}');
          //     debugPrint('🧾 summary: ${feedItem.summary}');
          //     debugPrint('🧾 topic: ${feedItem.topic}');

          //     debugPrint('🧾 Event info:');
          //     debugPrint('📅 event title: ${feedItem.relatedEvent!.title}');
          //     debugPrint('📅 isOngoing backend: ${feedItem.relatedEvent!.isOngoing}');
          //     debugPrint('📅 isOngoing frontend: ${feedItem.relatedEvent!.name.isOngoing}');
          //     debugPrint('📅 feedItem.isOngoing: ${feedItem.isOngoing}');
          //     debugPrint('📅 feedItem.vibeAnimationAsset: ${feedItem.vibeAnimationAsset}');
          //   }),
          // ),
        ],
      ).onTap(() {
        if (APP_IN_DEVELOPMENT) {
          log('[feed_card] feedItem.videoUrl = ${feedItem.videoUrl}');
          log('[feed_card] feedItem.hasYouTubeVideo = ${feedItem.hasYouTubeVideo}');
          log('[feed_card] feedItem.youTubeVideoID = ${feedItem.youTubeVideoID}');
          log('[feed_card] feedItem.displayImageUrl = ${feedItem.displayImageUrl}');
          ref.read(feedTypeProvider.notifier).setValue(FeedType.latest);
          ref.read(topicProvider.notifier).clear();
        } else {
          if (hasYouTubeVideo) openUrl(feedItem.videoUrl!);
        }
      }),
    );
  }
}

/// Feed content with article text and badges
class _FeedContent extends ConsumerWidget {
  final FeedItem feedItem;

  const _FeedContent({required this.feedItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final settings = ref.watch(settingsProvider);
    final textSize = settings.textSize.toDouble();
    final badges = feedItem.badgeToDisplay.map<Widget>((badge) => _FeedBadgeChip(badge, feedItem.isNuanced));
    final keywords = feedItem.keywordsToDisplay.map<Widget>((keyword) => ChipBadge(keyword.toTitleCase()));
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppThemes.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hook text
          if (feedItem.hook != null) HookCard(feedItem.hook!, fontSize: textSize),

          // Summary text
          formatText(
            context,
            feedItem.summary,
            style: h.currentTextTheme.bodyMedium?.copyWith(
              fontSize: textSize,
            ),
          ),
          
          // Badges
          if (feedItem.badges.isNotEmpty) Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...badges,
              ...(badges.length < MAX_BADGES_TO_DISPLAY ? keywords.take(MAX_BADGES_TO_DISPLAY - badges.length) : [])
            ],
          ),

          // Context text
          if (feedItem.context != null) ContextCard(feedItem.context!),

          // Also read chips
          if (feedItem.alsoRead.isNotEmpty) Wrap(
            spacing: 6,
            runSpacing: 6,
            children: feedItem.alsoRead.where((c) => c.displayTitle != null).map((cluster) {
              return _AlsoReadChip(cluster);
            }).toList(),
          ),
        ].addItemInBetween(SizedBox(height: 16)),
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
    final likeCount = currentFeedItem.likeCount;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            MyDivider(),
            _FeedFooterSource(currentFeedItem).moveX(-8).left(),
            MyPopupMenu(
              icon: Icon(CupertinoIcons.ellipsis, color: h.currentTheme.colorScheme.tertiary),
              onSelected: (String value) {
                _handleMenuAction(context, ref, value);
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
              ],
            ).right(),
          ],
        ),

        Row(children: [
          // Summarizer info
          if (feedItem.summaryProvider != null) _FeedSummarizer(feedItem.summaryProvider!),

          const Spacer(),

          // Action buttons
          if (isTakingScreenshot) Logo(size: 50,) else ...<Widget>[
            if (likeCount > 0) Text(formatNumber(likeCount), textAlign: TextAlign.right, style: h.currentTextTheme.bodySmall,).withPadding(right: 4),
            MyIconButton(icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart, size: 50, outlined: true, onPressed: onLike, iconColor: isLiked ? Colors.red : null),
            MyIconButton(icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark, size: 50, outlined: true, onPressed: onSave, iconColor: isSaved ? AppColors.primary : null),
            MyIconButton(icon: CupertinoIcons.share, size: 50, outlined: true, onPressed: onShare,),
          ].addItemInBetween(SizedBox(width: 8)),
        ],),

        SizedBox(height: 8,),
      ],
    ).withPaddingAll(AppThemes.contentPadding - 8);
  }

  Future<void> _notInterested(BuildContext context, WidgetRef ref) async {
    final confirm = await showBottomModalConfirm(
      context,
      title: "Not Interested?",
      message: "Are you sure you are not interested in this feed?",
      confirmButtonText: "Not Interested",
      cancelButtonText: "I've changed my mind",
    ) ?? false;

    if (!context.mounted || !confirm) return;
    
    try {
      // Capture all notifiers before async operations to avoid ref issues
      final userNotifier = ref.read(userProvider.notifier);
      // Increment user's not interested count
      if (context.mounted) {
        await userNotifier.incrementNotInterested();
      }

      // Call API to mark as not interested
      fireAndForget(() async {
        final success = await markNotInterested(feedItem.id);

        if (!context.mounted) return;
        if (success) {
          showSnackBarSuccess(context, "Feed hidden. We'll show less content like this.");
        } else {
          showSnackBarError(context, "Failed to mark as not interested");
        }
      });

      // Mark as not interested across all feed types
      if (context.mounted) {
        await FeedStateService.markNotInterestedEverywhere(ref, feedItem);
      }
    } catch (e) {
      log("[_notInterested] 🔥 ERROR! $e");
    }
  }

  Future<void> _avoidSource(BuildContext context, WidgetRef ref) async {
    // Do nothing if source already avoided
    // if (isSourceAvoided(ref, feedItem.source.id)) return;
    final isSourceAvoided = ref.read(preferencesProvider).avoidedSources.contains(feedItem.source);
    if (isSourceAvoided) return;

    // Display confirmation dialog
    final sourceName = feedItem.source.name ?? 'this source';
    final sourceIcon = feedItem.source.siteIcon;
    final confirm = await showBottomModalConfirm(
      context,
      header: sourceIcon != null ? CachedImageWidget(imageUrl: sourceIcon, width: 48, height: 48, fit: BoxFit.contain) : null,
      title: "Don't like $sourceName?",
      message: "Are you sure you don't want to see more from $sourceName?",
      confirmButtonText: "Yes, don't recommend",
      cancelButtonText: "I've changed my mind",
    ) ?? false;
    if (!context.mounted || !confirm) return;
    avoidSource(ref, feedItem.source);
    showSnackBarSuccess(context, "Won't recommend feeds from $sourceName");
  }

  Future<void> _feedback(BuildContext context, WidgetRef ref) async {
    final feedbackResult = await showBottomModalSheetContent(
      context, 
      title: "Send Feedback", 
      widgets: [FeedbackForm(feedId: feedItem.id)],
      isDismissible: false,
    ) as Map<String, dynamic>?;

    final FeedbackCategory? category = feedbackResult?['category'];
    final bool shouldHideFeed = category?.shouldHideFeed ?? false;
    if (!context.mounted || !shouldHideFeed) return;
    
    // Remove the feed item from the current feed
    final notifier = feedType.getNotifier(ref);
    await notifier.markAsNotInterested(feedItem.id, reason: category);
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'not_interested':
        _notInterested(context, ref);
        break;
      case 'dont_recommend_source':
        _avoidSource(context, ref);
        break;
      case 'send_feedback':
        _feedback(context, ref);
        break;
    }
  }
}

class _FeedSummarizer extends StatelessWidget {
  final String provider;

  const _FeedSummarizer(this.provider);

  @override
  Widget build(BuildContext context) {
    final providerLabel = provider.toCapitalized();
    return MyBadge(
      text: provider == 'none' ? 'Original text' : 'Summarizer: $providerLabel',
      description: provider == 'none'
          ? 'This content is from the original source'
          : 'AI-generated summary by $providerLabel',
    );
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
                color: h.currentTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: CachedImageWidget(
                imageUrl: feedItem.source.siteIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => Icon(
                  CupertinoIcons.globe,
                  size: 16,
                  color: h.currentTheme.colorScheme.surfaceContainerHigh,
                ),
              ).clipRadius(4),
            ),
            const SizedBox(width: 8),
            
            // Source site name
            Text(
              feedItem.sourceLabel,
              style: h.currentTextTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ).flexible(),

            if (feedItem.sources.length > 1) MyBadge(text: "+${feedItem.sources.length - 1}", color: Colors.blueGrey,).withPadding(left: 4),
    
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 14, color: h.currentTheme.colorScheme.tertiary),

            if (!feedItem.isEvergreen && feedItem.publishedAt != null) ...[
              SizedBox(width: 4),
              Text('•', style: TextStyle(
                color: h.currentTheme.colorScheme.tertiary,
                fontSize: 12,
              ),),
              SizedBox(width: 4),
              TimeagoCompact(
                dateTime: feedItem.publishedAt!,
                explicit: true,
                color: h.currentTheme.colorScheme.tertiary,
                fontSize: 12,
              ),
            ],
          ],
        ).withPadding(horizontal: 8, vertical: 4),
      ),
    ).withTooltip("Read full article");
  }
}

class _FeedBadgeChip extends StatelessWidget {
  final String badge;
  final bool isNuanced;
  
  const _FeedBadgeChip(this.badge, this.isNuanced);

  List<String> get _badgeSplit => badge.split(':');
  String get _badgeLabel => _badgeSplit[0];
  String get _badgeValue => _badgeSplit[1];
  String get _valueCapitalized => _badgeValue.unslugTitleCase();

  static const Map<String, String> _badgeMappings = {
    // Trust & Source Credibility
    'trust_level:high': 'Trusted source',
    'trust_level:medium': 'Reputable source', 
    'trust_level:basic': 'Informational source',
    'trust_level:unverified': 'Unverified source',
    // Safety & Review Signals
    'summary_status:verified': 'Verified summary',
    'summary_status:requires_review': 'Read carefully',
    'content_risk:high': 'Sensitive topic',
    // Scholarly Presence
    'scholars:single': 'Scholarly reference',
    'scholars:multiple': 'Multiple scholars',
    // Madhhab / Jurisprudence
    'madhhab:multiple': 'Multiple fiqh views',
    // Coverage & Maturity
    'coverage:multiple_sources': 'Multiple sources',
    // Image Source
    'image:illustrative': 'Illustrative',
  };

  static const Map<String, String> _badgeDescriptions = {
    // Trust & Source Credibility
    'trust_level:high': 'Recognized scholarly or reputable institution',
    'trust_level:medium': 'Generally reliable, editorial standards present',
    'trust_level:basic': 'Useful content, limited verification',
    'trust_level:unverified': 'Source credibility not yet established',
    // Safety & Review Signals
    'summary_status:verified': 'Summary generated with sufficient confidence',
    'summary_status:requires_review': 'Topic may require scholarly review',
    'content_risk:high': 'Content involves rulings, disputes, or strong claims',
    // Scholarly Presence
    'scholars:single': 'Mentions a recognized Islamic scholar',
    'scholars:multiple': 'References more than one recognized scholar',
    // Madhhab / Jurisprudence
    'madhhab:multiple': 'Presents more than one scholarly opinion',
    // Coverage & Maturity
    'coverage:multiple_sources': 'Covered by more than one source',
    // Image Source
    'image:illustrative': 'Illustrative image representing content',
    // Engagement
    'engagement:trending': 'High engagement and trending topics',
  };

  IconData? get _badgeIcon {
    switch (badge) {
      case 'engagement:trending': return isNuanced ? CupertinoIcons.moon_stars_fill : CupertinoIcons.graph_square_fill;
      case 'content_risk:high': return CupertinoIcons.exclamationmark_triangle_fill;
      default: return null;
    }
  }

  String get _badgeText {
    // Check exact mappings first
    final mappedText = _badgeMappings[badge];
    if (mappedText != null) return mappedText;
    
    if (badge == 'engagement:trending' && isNuanced) return "Highlight";

    // Handle dynamic patterns
    if (_badgeLabel == 'madhhab') return '$_valueCapitalized Fiqh';
    if (_badgeLabel == 'topic') return getTopicLabel(_badgeValue);
    if (_badgeLabel == 'content_type') return getContentTypeLabel(_badgeValue);
    
    // Default fallback
    return _valueCapitalized;
  }

  String? get _badgeDescription {
    // Check exact mappings first
    final mappedDescription = _badgeDescriptions[badge];
    if (mappedDescription != null) return mappedDescription;
    
    // Handle dynamic patterns
    if (_badgeLabel == 'madhhab') return 'Based on $_valueCapitalized fiqh';
    if (_badgeLabel == 'target') return 'Target audience: $_valueCapitalized';
    
    return null;
  }

  MaterialColor get _badgeColor {
    // Handle dynamic patterns for all badges
    if (_badgeLabel == 'scholars') return Colors.deepPurple;
    if (_badgeLabel == 'madhhab') return Colors.indigo;
    if (_badgeLabel == 'image') return Colors.cyan;
    if (_badgeLabel == 'coverage') return Colors.teal;
    if (_badgeLabel == 'target') return Colors.pink;

    switch (_badgeLabel) {
      case 'trust_level':
        switch (_badgeValue) {
          case 'high': return Colors.green;
          case 'medium': return Colors.blue;
          case 'basic': return Colors.cyan;
          case 'unverified': return Colors.blueGrey;
        }

      case 'content_type':
        return getContentTypeColor(_badgeValue);
        
      case 'content_tier':
        switch (_badgeValue) {
          case 'evergreen': return Colors.green;
          case 'semi_evergreen': return Colors.cyan;
          case 'ephemeral': return Colors.amber;
        }
        
      case 'topic':
        return getTopicColor(_badgeValue);
        
      default:
        // Fallback colors based on value
        switch (_badgeValue) {
          case 'high': return Colors.red;
          case 'medium': case 'requires_review': case 'trending': return Colors.orange;
          case 'low': case 'verified': case 'ok': return Colors.green;
          case 'unverified': return Colors.blueGrey;
        }
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return ChipBadge(_badgeText, color: _badgeColor, icon: _badgeIcon, description: _badgeDescription);
  }
}

/// Also read chip widget for displaying related clusters
class _AlsoReadChip extends StatelessWidget {
  final Cluster cluster;

  const _AlsoReadChip(this.cluster);

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: h.currentTheme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppThemes.buttonRadius),
        border: Border.all(
          color: h.currentTheme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        cluster.displayTitle!,
        style: TextStyle(
          fontSize: 12,
          color: h.currentTheme.colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ).onTap(() => context.go('/feed/${cluster.id}'));
  }
}