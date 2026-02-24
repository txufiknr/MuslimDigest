import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';
import 'package:muslimdigest/widgets/home/feed_card.dart';

/// Page to display a single feed item
class SingleFeedPage extends ConsumerWidget {
  final String feedId;
  final FeedType feedType;

  const SingleFeedPage({
    super.key,
    required this.feedId,
    required this.feedType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    
    // Get the feed item from the provider
    final feedItem = feedType.readItem(ref, feedId);
    
    return Scaffold(
      backgroundColor: h.currentTheme.scaffoldBackgroundColor,
      appBar: MyAppBar(title: feedItem?.title ?? 'Article not found'),
      body: feedItem != null 
        ? FeedCard(feedType, feedItem: feedItem)
        : MyPlaceholder(
          'Article not found',
          footer: "The article you're looking for doesn't exist or has been removed.",
          icon: Icon(CupertinoIcons.news, size: 80, color: AppColors.accent),
          onRetry: context.pop,
          retryLabel: 'Go Back',
        ).center(),
    );
  }
}
