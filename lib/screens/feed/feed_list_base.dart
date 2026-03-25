import 'dart:developer' show log;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/strategies/feed_action_strategies.dart';
import 'package:muslimdigest/utils/contents.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/providers/feed/base_feed_notifier.dart';
import 'package:muslimdigest/providers/feed/feed_cache.dart';
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
import 'package:muslimdigest/widgets/collections/collection_search.dart';

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

  /// Get query parameters for API calls (override in subclasses if needed)
  Map<String, String>? get queryParams => null;

  @override
  ConsumerState<FeedListBasePage> createState() => _FeedListBasePageState();
}

class _FeedListBasePageState extends ConsumerState<FeedListBasePage> {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  
  // Request cancellation tracking
  String? _currentFeedRequestId;
  static int _requestCounter = 0;
  
  // Search state
  List<FeedItem> _allFeeds = [];
  List<FeedItem> _filteredFeeds = [];
  String _searchQuery = '';
  
  // Track content switching to prevent FOUC
  bool _isContentSwitching = false;
  Map<String, String>? _lastQueryParams;
  
  AppRepository get r => ref.read(appRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    
    // Delay the initial load to avoid modifying provider during build cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFeeds();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
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

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _filteredFeeds = _performSearch(_allFeeds, query);
    });
  }

  List<FeedItem> _performSearch(List<FeedItem> feeds, String query) {
    if (query.isEmpty) return feeds;
    
    return feeds.where((feed) => feed.matchSearchTerm(query)).toList();
  }

  Future<void> _loadInitialFeeds() async {
    final state = ref.read(widget.provider);
    final cache = ref.read(feedCacheProvider);
    
    log('[FeedListBase] _loadInitialFeeds called. State isEmpty: ${state.isEmpty}, hasMore: ${state.hasMore}');
    log('[FeedListBase] _loadInitialFeeds queryParams: ${widget.queryParams}');

    // Check if we're switching between different queryParams
    final queryParamsChanged = !MapEquality().equals(_lastQueryParams, widget.queryParams);
    if (queryParamsChanged && state.items?.isNotEmpty == true) {
      setState(() {
        _isContentSwitching = true;
      });
    }

    // Check if we have cached data for these queryParams
    final cachedItems = await cache.getFeedItems(widget.feedType.endpoint, queryParams: widget.queryParams);
    final hasCachedData = cachedItems != null;
    
    log('[FeedListBase] Cache check: hasCachedData=$hasCachedData, cachedItems=${cachedItems?.length}');
    
    // If we have cached data and state is empty or different, use cached data
    if (hasCachedData && (state.isEmpty || state.items?.length != cachedItems.length)) {
      log('[FeedListBase] Using cached data - setting ${cachedItems.length} items');
      final notifier = ref.read(widget.provider.notifier);
      await notifier.setValue(cachedItems, skipCache: true); // Skip cache to avoid double caching
    }
    // Load if: no state, has more data, or no cached data for current queryParams
    else if (state.isEmpty || state.hasMore || !hasCachedData) {
      log('[FeedListBase] Loading from API - state empty: ${state.isEmpty}, hasMore: ${state.hasMore}, noCache: ${!hasCachedData}');
      final notifier = ref.read(widget.provider.notifier);
      await notifier.loadFromEndpoint(
        widget.feedType.endpoint,
        queryParams: widget.queryParams,
      );
    } else {
      log('[FeedListBase] Using existing state - state has items: ${state.items?.length}');
    }
    
    // Update tracking and stop switching indicator
    _lastQueryParams = widget.queryParams;
    if (mounted) {
      setState(() {
        _isContentSwitching = false;
      });
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
      queryParams: widget.queryParams,
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
      
      // For saved and liked feeds, remove from current provider state to update UI immediately
      // Note: We use skipCache=true to avoid double cache update since strategy already updated cache via FeedStateService
      if (widget.feedType == FeedType.saved || widget.feedType == FeedType.liked) {
        await _removeFromCurrentFeed(feed, skipCache: true);
      }
      // For other feed types (except notInterested), remove from current provider state after strategy execution (no cache skip needed)
      else if (widget.feedType != FeedType.notInterested) {
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
  Future<void> _removeFromCurrentFeed(FeedItem feed, {bool skipCache = false}) async {
    final notifier = ref.read(widget.provider.notifier);
    final currentState = ref.read(widget.provider);
    final currentItems = currentState.items ?? [];
    final updatedItems = currentItems.where((item) => item.id != feed.id).toList();
    await notifier.setValue(updatedItems, skipCache: skipCache);
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
    
    // Update search data when provider state changes
    final currentFeeds = state.items ?? [];
    if (currentFeeds != _allFeeds) {
      _allFeeds = currentFeeds;
      _filteredFeeds = _performSearch(_allFeeds, _searchQuery);
    }
    
    final list = _buildFeedList(h, state, _filteredFeeds);

    if (!widget.useScaffold) return list;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MyAppBar(title: widget.title),
      body: SafeArea(child: list),
    );
  }

  Widget _buildEmptyState(MyHelper h, {bool isSearchResult = false}) {
    final title = isSearchResult 
      ? 'No feeds found for "$_searchQuery"' 
      : 'No ${widget.title.toLowerCase()} yet';
    final footer = isSearchResult 
      ? 'Try a different search term' 
      : widget.placeholderTooltip;
    
    return MyPlaceholder(
      title,
      footer: footer,
      padding: 48,
      icon: Icon(
        isSearchResult ? CupertinoIcons.search : widget.placeholderIcon,
        size: 64,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    ).center();
  }

  Widget _buildFeedList(MyHelper h, BaseFeedState state, List<FeedItem> feeds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        return Column(
          children: [
            // Search widget
            CollectionSearchWidget(
              controller: _searchController,
              hintText: 'Search ${widget.title.toLowerCase()}...',
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  _filteredFeeds = _allFeeds;
                });
              },
              onChanged: (query) {
                // Real-time search is handled by _onSearchChanged listener
              },
            ).withPadding(
              horizontal: AppThemes.contentPadding,
              vertical: 8
            ),
            
            // Feed list
            Expanded(
              child: SmartRefresher(
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
                    // Show loader when switching content (FOUC prevention)
                    if (_isContentSwitching && index == 0) {
                      return _buildLoadingIndicator().sized(height: maxHeight);
                    }
                    // Empty state
                    if (state.isGetting) {
                      return _buildLoadingIndicator().sized(height: maxHeight);
                    }
                    if (feeds.isEmpty) {
                      return _buildEmptyState(h, isSearchResult: _searchQuery.isNotEmpty).sized(height: maxHeight);
                    }
              
                    // Loading more indicator
                    if (index == feeds.length) {
                      return CupertinoActivityIndicator().squared(24).center();
                    }
                    
                    // Adjust index when showing switching loader
                    final adjustedIndex = _isContentSwitching ? index - 1 : index;
                    return _buildFeedItem(h, feeds[adjustedIndex]);
                  },
                ),
              ),
            ),
          ],
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
                        getTopicLabel(feed.topic!),
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
