import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/services/api.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/animations/loader.dart';
import 'package:muslimdigest/widgets/components/cached_image.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';

abstract class FeedListBasePage extends ConsumerStatefulWidget {
  final String title;
  final String endpoint;
  final IconData actionIcon;
  final String actionTooltip;

  const FeedListBasePage({
    super.key,
    required this.title,
    required this.endpoint,
    required this.actionIcon,
    required this.actionTooltip,
  });

  @override
  ConsumerState<FeedListBasePage> createState() => _FeedListBasePageState();
}

class _FeedListBasePageState extends ConsumerState<FeedListBasePage> {
  final ScrollController _scrollController = ScrollController();
  final List<FeedItem> _feeds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _cursor;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isLoading && _hasMore) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 200) {
        _loadFeeds();
      }
    }
  }

  Future<void> _loadFeeds() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final queryParams = <String, String>{
        'limit': '8',
      };
      
      if (_cursor != null) {
        queryParams['cursor'] = _cursor!;
      }

      final response = await ApiService.get(widget.endpoint, queryParams: queryParams);
      
      if (response.successful && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final feedsData = data['feeds'] as List<dynamic>? ?? [];
        final newFeeds = feedsData.map((json) => FeedItem.fromJson(json)).toList();
        
        setState(() {
          _feeds.addAll(newFeeds);
          _hasMore = newFeeds.length == 8;
          _cursor = data['cursor'] as String?;
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onActionPressed(FeedItem feed) async {
    try {
      // Unlike/Unsave the feed
      final actionEndpoint = widget.endpoint.contains('liked') ? 'like' : 'save';
      final response = await ApiService.post('$actionEndpoint/${feed.id}', {});
      
      if (response.successful) {
        setState(() {
          _feeds.removeWhere((item) => item.id == feed.id);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppThemes.contentPadding),
              child: Row(
                children: [
                  MyIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    iconColor: AppColors.primary,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Text(
                      widget.title,
                      style: h.currentTextTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: _feeds.isEmpty && !_isLoading
                  ? _buildEmptyState(h)
                  : _buildFeedList(h),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(MyHelper h) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.actionIcon,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'No ${widget.title.toLowerCase()} yet',
            style: h.currentTextTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.actionTooltip,
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(MyHelper h) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppThemes.contentPadding),
      itemCount: _feeds.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _feeds.length) {
          return _buildLoadingIndicator();
        }
        
        return _buildFeedItem(h, _feeds[index]);
      },
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
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedImageWidget(
                imageUrl: feed.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Center: Title and Topic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feed.title,
                  style: h.currentTextTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                      feed.topic!,
                      style: h.currentTextTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
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
      // TODO: Navigate to feed detail
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
