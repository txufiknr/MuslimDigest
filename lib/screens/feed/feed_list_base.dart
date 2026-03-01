import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/feed.dart';
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

  const FeedListBasePage({
    super.key,
    required this.title,
    required this.actionIcon,
    required this.actionTooltip,
    required this.placeholderIcon,
    required this.placeholderTooltip,
    required this.feedType,
  });

  /// Get the appropriate provider for this feed type
  NotifierProvider<BaseFeedNotifier, BaseFeedState> get provider;

  @override
  ConsumerState<FeedListBasePage> createState() => _FeedListBasePageState();
}

class _FeedListBasePageState extends ConsumerState<FeedListBasePage> {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

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

    debugPrint('[init] state.isLoading: ${state.isLoading}');
    debugPrint('[init] state.isEmpty: ${state.isEmpty}');
    debugPrint('[init] state.isNone: ${state.isNone}');
    
    // For liked, saved, and history feeds, always force refresh to ensure latest data
    // For other feeds, only load if we have no cached data
    final shouldForceRefresh = widget.feedType == FeedType.liked || 
                              widget.feedType == FeedType.saved || 
                              widget.feedType == FeedType.history;
    
    if (state.isEmpty || shouldForceRefresh) {
      final notifier = ref.read(widget.provider.notifier);
      await notifier.loadFromEndpoint(
        widget.feedType.endpoint,
        forceRefresh: shouldForceRefresh,
      );
    }
  }

  Future<void> _loadMoreFeeds() async {
    final notifier = ref.read(widget.provider.notifier);
    await notifier.loadMore();
  }

  Future<void> _onRefresh() async {
    try {
      final notifier = ref.read(widget.provider.notifier);
      await notifier.loadFromEndpoint(
        widget.feedType.endpoint,
        forceRefresh: true,
      );
      
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _onActionPressed(FeedItem feed) async {
    try {
      if (widget.feedType == FeedType.history) {
        // Remove from history
        final deleted = await deleteHistory(feed.id);

        if (deleted) {
          // Remove from provider state
          final notifier = ref.read(widget.provider.notifier);
          final currentState = ref.read(widget.provider);
          final currentItems = currentState.items ?? [];
          final updatedItems = currentItems.where((item) => item.id != feed.id).toList();
          await notifier.setValue(updatedItems);
        }
      } else {
        // Unlike/Unsave the feed (for liked and saved feeds)
        final actionEndpoint = widget.feedType.endpoint.contains('liked') ? 'feed/like' : 'feed/save';
        final response = await ApiService.post(actionEndpoint, { 'clusterId': feed.id, 'value': false });
        
        if (response.successful) {
          // Remove from provider state
          final notifier = ref.read(widget.provider.notifier);
          final currentState = ref.read(widget.provider);
          final currentItems = currentState.items ?? [];
          final updatedItems = currentItems.where((item) => item.id != feed.id).toList();
          await notifier.setValue(updatedItems);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final state = ref.watch(widget.provider);

    debugPrint('[build] state.isLoading: ${state.isLoading}');
    debugPrint('[build] state.isEmpty: ${state.isEmpty}');
    debugPrint('[build] state.isNone: ${state.isNone}');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MyAppBar(title: widget.title),
      body: SafeArea(
        child: _buildFeedList(h, state),
      ),
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

    debugPrint('[build] feeds.length: ${feeds.length}');
    debugPrint('[build] state.isLoading: ${state.isLoading}');
    debugPrint('[build] state.isLoadingMore: ${state.isLoadingMore}');
    debugPrint('[build] state.hasMore: ${state.hasMore}');
    debugPrint('[build] state.isGetting: ${state.isGetting}');

    // Show loading indicator when initially loading
    // if (state.isGetting) {
    //   return _buildLoadingState();
    // }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        return SmartRefresher(
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
              if (feeds.isEmpty && !state.isGetting) {
                return _buildEmptyState(h).sized(height: maxHeight);
              }
        
              // Loading more indicator
              if (state.isGetting || index == feeds.length) {
                return _buildLoadingIndicator().sized(height: maxHeight);
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feed.topic!.toCapitalized(),
                    style: h.currentTextTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ).expand(),
          
          const SizedBox(width: 12),
          
          // Right: Action Button
          MyIconButton(
            icon: widget.actionIcon,
            onPressed: () => _onActionPressed(feed),
            tooltip: widget.actionTooltip,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            size: 40,
          ),
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
