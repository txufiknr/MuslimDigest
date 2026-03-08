import 'dart:developer' show log;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/strategies/feed_action_strategies.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/utils/app_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/format.dart';
import 'package:muslimdigest/widgets/components/logo.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/cached_image.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';

abstract class FeedListBasePage extends ConsumerStatefulWidget {
  final String title;
  final IconData actionIcon;
  final String actionTooltip;
  final IconData placeholderIcon;
  final String placeholderTooltip;
  final FeedType feedType;
  final bool useScaffold;

  const FeedListBasePage({
    super.key,
    required this.title,
    required this.actionIcon,
    required this.actionTooltip,
    required this.placeholderIcon,
    required this.placeholderTooltip,
    required this.feedType,
    this.useScaffold = true,
  });

  /// Get the appropriate provider for this feed type
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider;

  @override
  ConsumerState<FeedListBasePage> createState() => _FeedListBasePageState();
}

class _FeedListBasePageState extends ConsumerState<FeedListBasePage> {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  // Request cancellation tracking
  String? _currentFeedRequestId;
  static int _requestCounter = 0;
  
  AppRepository get r => ref.read(appRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Delay the initial load to avoid modifying provider during build cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFeeds();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(widget.provider);
    if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 200) {
        _loadMoreFeeds();
      }
    }
  }

  Future<void> _loadInitialFeeds() async {
    final state = ref.read(widget.provider);

    // No cached data, or there might be more items - must load from backend
    if (state.isEmpty || state.hasMore) {
      final notifier = ref.read(widget.provider.notifier);
      await notifier.loadFromEndpoint(widget.feedType.endpoint);
    }
  }

  Future<void> _loadMoreFeeds() async {
    final notifier = ref.read(widget.provider.notifier);
    await notifier.loadMore();
  }

  Future<void> _onRefresh() async {
    // Cancel previous request and create new request ID
    _currentFeedRequestId = 'feed_${++_requestCounter}_${widget.feedType.name}_refresh';
    
    log('[FeedListBase] Starting refresh with request ID: $_currentFeedRequestId');
    
    final success = await r.loadFeed(
      feedType: widget.feedType,
      force: true,
      requestId: _currentFeedRequestId,
    );
    
    // Only show error if this is still the current request
    if (mounted && !success && _currentFeedRequestId != null) {
      return _showLoadFeedFailed(() => _onRefresh());
    }
    
    _refreshController.refreshCompleted();
  }
  
  Future<void> _showLoadFeedFailed(Future<void> Function() onRetry) async {
    final shouldRetry = await showRetryableError(
      context,
      title: 'Failed to fetch feed items.',
      message: 'Failed to load your feed. Would you like to retry?',
      footer: 'Or try checking your internet connection first.',
    );
    if (shouldRetry) {
      return onRetry();
    }
  }

  Future<void> _onActionPressed(FeedItem feed) async {
    // Get the appropriate strategy for this feed type
    final strategy = FeedActionStrategyFactory.getStrategy(widget.feedType);
    
    if (strategy == null) {
      log('[FeedListBase] No action strategy found for feed type: ${widget.feedType.name}');
      return;
    }
    
    try {
      // Execute the strategy
      await strategy.execute(ref, feed);
      
      // For history feed type, also remove from current provider state
      if (widget.feedType == FeedType.history) {
        await _removeFromCurrentFeed(feed);
      }
      
      // For other feed types, remove from current provider state after strategy execution
      if (widget.feedType != FeedType.notInterested) {
        await _removeFromCurrentFeed(feed);
      }
      
    } catch (e) {
      log('[FeedListBase] Error executing action strategy: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${strategy.actionLabel.toLowerCase()} feed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Helper method to remove feed from current provider state
  Future<void> _removeFromCurrentFeed(FeedItem feed) async {
    final notifier = ref.read(widget.provider.notifier);
    final currentState = ref.read(widget.provider);
    final currentItems = currentState.items ?? [];
    final updatedItems = currentItems.where((item) => item.id != feed.id).toList();
    await notifier.setValue(updatedItems);
  }
  
  /// Build action button using strategy pattern
  Widget _buildActionButton(FeedItem feed) {
    final strategy = FeedActionStrategyFactory.getStrategy(widget.feedType);
    
    // Fallback to default action if no strategy found
    if (strategy == null) {
      return MyIconButton(
        icon: widget.actionIcon,
        onPressed: () => _onActionPressed(feed),
        tooltip: widget.actionTooltip,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        iconColor: AppColors.primary,
        iconSize: 18,
        size: 40,
      );
    }
    
    // Use strategy-based action button
    final iconColor = _getActionButtonIconColor(widget.feedType);
    return MyIconButton(
      icon: strategy.actionIcon,
      onPressed: () => _onActionPressed(feed),
      tooltip: strategy.actionTooltip,
      backgroundColor: iconColor.withValues(alpha: .1),
      iconColor: iconColor,
      iconSize: 18,
      size: 40,
    );
  }
  
  /// Get action button icon color based on feed type
  Color _getActionButtonIconColor(FeedType feedType) {
    switch (feedType) {
      case FeedType.liked: return Colors.red;
      case FeedType.notInterested: return Colors.green;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final state = ref.watch(widget.provider);
    final list = _buildFeedList(h, state);

    if (!widget.useScaffold) return list;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MyAppBar(title: widget.title),
      body: SafeArea(child: list),
    );
  }

  Widget _buildEmptyState(MyHelper h) {
    return MyPlaceholder(
      'No ${widget.title.toLowerCase()} yet',
      footer: widget.placeholderTooltip,
      padding: 48,
      icon: Icon(
        widget.placeholderIcon,
        size: 64,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    ).center();
  }

  Widget _buildFeedList(MyHelper h, BaseFeedState state) {
    final feeds = state.items ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        return SmartRefresher(
          physics: state.isGetting ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: false,
          onRefresh: _onRefresh,
          header: CustomHeader(
            builder: (context, mode) {
              if (mode == RefreshStatus.canRefresh || mode == RefreshStatus.refreshing) {
                return CupertinoActivityIndicator(animating: mode == RefreshStatus.refreshing).squared(24).center();
              }
              return SizedBox.shrink();
            },
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppThemes.contentPadding),
            itemCount: feeds.length + (feeds.isEmpty || state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Empty state
              if (state.isGetting) {
                return _buildLoadingIndicator().sized(height: maxHeight);
              }
              if (feeds.isEmpty) {
                return _buildEmptyState(h).sized(height: maxHeight);
              }
        
              // Loading more indicator
              if (index == feeds.length) {
                return CupertinoActivityIndicator().squared(24).center();
              }
              
              return _buildFeedItem(h, feeds[index]);
            },
          ),
        );
      }
    );
  }

  Widget _buildFeedItem(MyHelper h, FeedItem feed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: CachedImageWidget(
              imageUrl: feed.imageUrl,
              fit: BoxFit.cover,
              errorColor: h.currentTheme.colorScheme.secondary,
              errorChild: Logo(),
            ),
          ).clipRadius(12),
          
          const SizedBox(width: 12),
          
          // Center: Title and Topic
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feed.title,
                style: h.currentTextTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              if (feed.topic != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feed.topic!.toCapitalized(),
                        style: h.currentTextTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Not interested reason badge (only show for not interested feeds)
                    if (feed.feedbackCategory != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: feed.feedbackCategory!.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          feed.feedbackCategory!.label,
                          style: h.currentTextTheme.bodySmall?.copyWith(
                            color: feed.feedbackCategory!.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    Spacer(),

                    if (feed.createdAt != null) Text(
                      formatDateTime(feed.createdAt!),
                      textAlign: TextAlign.right,
                      style: h.currentTextTheme.bodySmall?.copyWith(
                        color: h.currentTheme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
            ],
          ).expand(),
          
          const SizedBox(width: 12),
          
          // Right: Action Button
          _buildActionButton(feed),
        ],
      ),
    ).onTap(() {
      context.push('/feeds/${feed.id}?feedType=${widget.feedType.name}');
    });
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: MyLoader(color: AppColors.primary),
    );
  }
}
