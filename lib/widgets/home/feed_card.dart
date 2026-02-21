// import 'dart:math' show max;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/feed.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Individual feed card widget
class FeedCard extends ConsumerStatefulWidget {
  final FeedType feedType;
  final FeedItem? feedItem;
  final VoidCallback onReload;
  final VoidCallback onSeeLatest;

  const FeedCard(this.feedType, {
    super.key,
    this.feedItem,
    required this.onReload,
    required this.onSeeLatest,
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
    setState(() => _isTakingScreenshot = true);
    await delay(100); // Wait for the feed to be fully rendered
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
          'Hi, I wanted to share with you my latest ${isShareReading ? 'read' : 'achievement'} on $APP_NAME.'
          'Check out $APP_NAME and level up your Islamic knowledge with daily high-quality digests:'
          '$APP_URL_PLAYSTORE',
      ),
    );
  }

  Future<String?> _screenshot() async {
    final imageName = "${_feedId ?? today.toIso8601String().substring(0, 10)}.png";
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await _screenshotController.captureAndSave(directory.path, fileName: imageName);
    if (mounted && imagePath == null) {
      showSnackBar(context, "Cannot save image. Please try again.");
    }
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final h = MyHelper(context);
    final streaks = ref.read(streaksProvider);
    final currentStreak = streaks.currentStreak;
    final isStreakCard = widget.feedItem == null;

    return Container(
      width: double.infinity,
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
      padding: isStreakCard ? EdgeInsets.all(AppThemes.contentPadding) : EdgeInsets.zero,
      child: isStreakCard ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Another day of beneficial knowledge.", textAlign: TextAlign.center, style: h.currentTextTheme.titleLarge),
          Text(MESSAGES[(currentStreak - 1) % MESSAGES.length], textAlign: TextAlign.center, style: h.currentTextTheme.bodyMedium),
          StreaksCard(),
          Lottie.asset('assets/lottie/streak.json'),
          MyButton(text: "Continue reading", icon: Icon(CupertinoIcons.book), onPressed: widget.onSeeLatest,),
          MyDivider(),
          Row(
            children: _isTakingScreenshot ? [
              Text('Check out $APP_NAME and level up your Islamic knowledge').expand(),
              Logo(size: 100,),
            ] : [
              Text("Do you want to share it?", style: h.currentTextTheme.bodySmall?.copyWith(fontSize: 16)).expand(),
              MyIconButton(icon: CupertinoIcons.share, onPressed: _share,)
            ],
          ),
        ].addItemInBetween(SizedBox(height: 16,)),
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
    final hasYouTubeVideo = feedItem.videoUrl?.contains('youtu') == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(
            children: [
              // Image or video
              if (hasYouTubeVideo)
                YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: feedItem.videoUrl!,
                    flags: const YoutubePlayerFlags(
                      autoPlay: false,
                    ),
                  ),
                  // aspectRatio: 16 / 9,
                  aspectRatio: maxWidth / 200,
                )
              else
                CachedImageWidget(
                  imageUrl: feedItem.imageUrl,
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
              
              // Image URL overlay
              // if (feedItem.imageUrl != null) Positioned(
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
              //       feedItem.imageUrl ?? '',
              //       style: h.currentTextTheme.titleSmall?.copyWith(
              //         color: Colors.white,
              //       ),
              //       maxLines: 2,
              //       overflow: TextOverflow.ellipsis,
              //     ),
              //   ).onTap(() {
              //     openUrl(feedItem.imageUrl!);
              //   }),
              // ),
            ],
          ),
        );
      }
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
          // Hook text
          if (feedItem.hook != null) Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal[100]!, width: 1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              feedItem.hook!,
              style: h.currentTextTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.teal[800]
              ),
            ),
          ),

          // Summary text
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

          // TODO: also read chips
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

        Row(children: [
          // Summarizer info
          if (feedItem.summaryProvider != null) _FeedSummarizer(feedItem.summaryProvider!),

          const Spacer(),

          // Action buttons
          if (isTakingScreenshot) Logo(size: 100,) else ...<Widget>[
            // if (isLiked || likeCount > 0) Text(formatNumber(max(1, likeCount)), textAlign: TextAlign.right, style: h.currentTextTheme.bodySmall,),
            if (likeCount > 0) Text(formatNumber(likeCount), textAlign: TextAlign.right, style: h.currentTextTheme.bodySmall,),
            SizedBox(width: 4,),
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

class _FeedSummarizer extends StatelessWidget {
  final String provider;

  const _FeedSummarizer(this.provider);

  @override
  Widget build(BuildContext context) {
    final providerLabel = provider.toCapitalized();
    return MyBadge(
      text: 'Summarizer: $providerLabel',
      description: 'AI-generated summary by $providerLabel',
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
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
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Source site name
            Text(
              feedItem.sourceLabel,
              style: h.currentTextTheme.bodySmall,
            ),

            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 14, color: h.currentTheme.colorScheme.tertiary),
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

  String get _labelCapitalized => _badgeLabel.unslugTitleCase();
  String get _valueCapitalized => _badgeValue.unslugTitleCase();

  static const Map<String, String> _badgeMappings = {
    'topic:quran': 'Qur’an',
    'topic:dua': 'Duʿa',
    'topic:news': 'Muslim world',
    'topic:muslimworld': 'Muslim world',
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
  };

  String get _badgeText {
    // Check exact mappings first
    final mappedText = _badgeMappings[badge];
    if (mappedText != null) return mappedText;
    
    // Handle dynamic patterns
    if (_badgeLabel == 'madhhab') return '$_valueCapitalized Fiqh';
    if (_badgeLabel == 'content_type' || _badgeLabel == 'topic') return _valueCapitalized;
    
    // Default fallback
    return '$_labelCapitalized: $_valueCapitalized';
  }

  String? get _badgeDescription {
    // Check exact mappings first
    final mappedDescription = _badgeDescriptions[badge];
    if (mappedDescription != null) return mappedDescription;
    
    // Handle dynamic patterns
    if (_badgeLabel == 'madhhab') return 'Based on $_valueCapitalized fiqh';
    
    return null;
  }

  MaterialColor get _badgeColor {
    // Handle dynamic patterns for all badges
    if (_badgeLabel == 'scholars') return Colors.deepPurple;
    if (_badgeLabel == 'madhhab') return Colors.indigo;
    if (_badgeLabel == 'image') return Colors.cyan;
    if (_badgeLabel == 'content_type') return Colors.blue;
    if (_badgeLabel == 'coverage') return Colors.teal;

    switch (_badgeLabel) {
      case 'trust_level':
        switch (_badgeValue) {
          case 'high': return Colors.green;
          case 'medium': return Colors.blue;
          case 'basic': return Colors.cyan;
          case 'unverified': return Colors.blueGrey;
        }
        
      case 'topic':
        // Topic-specific colors
        switch (_badgeValue) {
          case 'quran': return Colors.teal;
          case 'dua': return Colors.lightGreen;
          case 'news': case 'muslimworld': return Colors.cyan;
          case 'fiqh': return Colors.indigo;
          case 'hadith': return Colors.teal;
          case 'seerah': return Colors.brown;
          case 'history': return Colors.brown;
        }
        
      default:
        // Fallback colors based on value
        switch (_badgeValue) {
          case 'high': return Colors.red;
          case 'medium': case 'requires_review': return Colors.orange;
          case 'low': case 'verified': case 'ok': return Colors.green;
          case 'unverified': return Colors.blueGrey;
        }
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _badgeDescription,
      tooltip: _badgeDescription,
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
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}