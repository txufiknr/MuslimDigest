import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import '../../models/feed.dart';

/// Feed swiper widget for displaying news cards with vertical swipe navigation
class FeedSwiper extends StatelessWidget {
  final List<FeedItem> feedItems;
  final Function(String) onSwipeUp;
  final VoidCallback onSwipeDown;

  const FeedSwiper({
    super.key,
    required this.feedItems,
    required this.onSwipeUp,
    required this.onSwipeDown,
  });

  @override
  Widget build(BuildContext context) {
    if (feedItems.isEmpty) {
      return const Center(
        child: Text(
          'No articles available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return CardSwiper(
      allowedSwipeDirection: AllowedSwipeDirection.symmetric(vertical: true),
      cardsCount: feedItems.length,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return FeedCard(feedItem: feedItems[index]);
      },
      isDisabled: false,
      onSwipe: (previousIndex, currentIndex, direction) async {
        log('[feed] Swipe direction: $direction, previousIndex: $previousIndex, currentIndex: $currentIndex');
        if (direction == CardSwiperDirection.top) {
          final swipedItem = feedItems[previousIndex];
          log('[feed] Swiped item: $swipedItem');
          onSwipeUp(swipedItem.cluster.id);
        } else if (direction == CardSwiperDirection.bottom) {
          onSwipeDown();
        }
        return true;
      },
    );
  }
}

/// Individual feed card widget
class FeedCard extends StatelessWidget {
  final FeedItem feedItem;

  const FeedCard({
    super.key,
    required this.feedItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and title
          _FeedHeader(feedItem: feedItem),
          
          // Content with article text and badges
          _FeedContent(feedItem: feedItem).expand(),
          
          // Footer with source and summarizer info
          _FeedFooter(feedItem: feedItem),
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
          feedItem.image != null
              ? CachedNetworkImage(
                  imageUrl: feedItem.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.article,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
          
          // Title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                style: h.currentTextTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
                // style: const TextStyle(
                //   color: Colors.white,
                //   fontSize: 18,
                //   fontWeight: FontWeight.bold,
                // ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article text
          Text(
            feedItem.summary,
            style: h.currentTextTheme.bodyMedium
          ),
          const SizedBox(height: 16),
          
          // Badges
          if (feedItem.badges.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: feedItem.badges.map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Source site icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: feedItem.source.siteIcon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      feedItem.source.siteIcon!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.public,
                          size: 16,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.public,
                    size: 16,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(width: 8),
          
          // Source site name
          Expanded(
            child: Text(
              feedItem.source.siteName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Summarizer info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              feedItem.summaryProvider,
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
