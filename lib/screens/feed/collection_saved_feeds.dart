import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/feed_saved.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';
import 'package:muslimdigest/widgets/home/feed_card.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';

/// Collection-specific saved feeds page
/// 
/// Shows saved feeds filtered by a specific collection
class CollectionSavedFeedsPage extends ConsumerStatefulWidget {
  final String collection;
  
  const CollectionSavedFeedsPage({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<CollectionSavedFeedsPage> createState() => _CollectionSavedFeedsPageState();
}

class _CollectionSavedFeedsPageState extends ConsumerState<CollectionSavedFeedsPage> {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  late final String _collection;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
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
    final state = ref.read(feedSavedProvider);
    if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 200) {
        _loadMoreFeeds();
      }
    }
  }

  Future<void> _loadInitialFeeds() async {
    final state = ref.read(feedSavedProvider);

    // No cached data, or there might be more items - must load from backend
    if (state.isEmpty || state.hasMore) {
      final notifier = ref.read(feedSavedProvider.notifier);
      await notifier.loadFromEndpoint('feed/saved', queryParams: {
        'collection': _collection,
      });
    }
  }

  Future<void> _loadMoreFeeds() async {
    final notifier = ref.read(feedSavedProvider.notifier);
    await notifier.loadMore();
  }

  Future<void> _onRefresh() async {
    final notifier = ref.read(feedSavedProvider.notifier);
    await notifier.loadFromEndpoint('feed/saved', queryParams: {
      'collection': _collection,
    }, forceRefresh: true);
    
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedSavedProvider);
    final feeds = state.items ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MyAppBar(title: _collection),
      body: SafeArea(
        child: SmartRefresher(
          physics: state.isGetting ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: false,
          onRefresh: _onRefresh,
          header: CustomHeader(
            builder: (context, mode) {
              if (mode == RefreshStatus.canRefresh || mode == RefreshStatus.refreshing) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(animating: mode == RefreshStatus.refreshing),
                ).center();
              }
              return SizedBox.shrink();
            },
          ),
          child: feeds.isEmpty && !state.isGetting
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppThemes.contentPadding),
                itemCount: feeds.length + (feeds.isEmpty || state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // Empty state
                  if (state.isGetting) {
                    return _buildLoadingIndicator();
                  }
                  if (feeds.isEmpty) {
                    return _buildEmptyState();
                  }
            
                  // Loading more indicator
                  if (index == feeds.length) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      child: CupertinoActivityIndicator(),
                    ).center();
                  }
                  
                  return FeedCard(FeedType.saved, feedItem: feeds[index]);
                },
              ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: MyPlaceholder(
        'No feeds in "$_collection"',
        footer: 'Start saving feeds to this collection to see them here',
        padding: 48,
        icon: Icon(
          CupertinoIcons.bookmark,
          size: 64,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: MyLoader(),
    );
  }
}
