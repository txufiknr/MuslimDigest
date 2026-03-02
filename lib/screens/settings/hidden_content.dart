import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/api/feeds.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/models/feed.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/services/feed_state_service.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/components/cached_image.dart' show CachedImageWidget;
import 'package:muslimdigest/widgets/components/icon_button.dart';
import 'package:muslimdigest/widgets/components/placeholder.dart';
import 'package:muslimdigest/variables/feed.dart';

class HiddenContentPage extends ConsumerStatefulWidget {
  final int? initialTab;
  
  const HiddenContentPage({super.key, this.initialTab});

  @override
  ConsumerState<HiddenContentPage> createState() => _HiddenContentPageState();
}

class _HiddenContentPageState extends ConsumerState<HiddenContentPage> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, initialIndex: widget.initialTab ?? 0, vsync: this);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Scaffold(
      backgroundColor: h.currentTheme.scaffoldBackgroundColor,
      appBar: MyAppBar(
        title: 'Hidden Content',
        bottom: TabBar(
          controller: _tabController,
          dividerColor: h.currentTheme.colorScheme.outline,
          labelStyle: h.currentTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: const [
            // TODO: add number badge
            Tab(text: 'Avoided Sources'), // ref.read(preferencesProvider).avoidedSources.length
            Tab(text: 'Hidden Feeds'), // ref.read(userProvider).totalNotInterested
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvoidedSourcesTab(h),
          _buildHiddenFeedsTab(h),
        ],
      ),
    );
  }

  Widget _buildAvoidedSourcesTab(MyHelper h) {
    final preferences = ref.watch(preferencesProvider);
    final avoidedSources = preferences.avoidedSources;

    return Column(
      children: [
        // Sources list
        Expanded(
          child: avoidedSources.isEmpty
              ? _buildEmptySourcesState(h)
              : _buildSourcesList(h, avoidedSources.toList()),
        ),
      ],
    );
  }

  Widget _buildEmptySourcesState(MyHelper h) {
    return Center(
      child: MyPlaceholder(
        'No avoided sources yet',
        footer: 'Sources you avoid will appear here for management',
        padding: 48,
        icon: Icon(
          CupertinoIcons.eye_slash,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSourcesList(MyHelper h, List<Source> sources) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return _AvoidedSourceTile(
          source: source,
          onRestore: () => _restoreSource(source),
        );
      },
    );
  }

  Widget _buildHiddenFeedsTab(MyHelper h) {
    // Get all not interested feeds from all feed types using FeedStateService
    final allNotInterestedItems = FeedStateService.getAllNotInterestedFeeds(ref);

    return Column(
      children: [
        // Hidden feeds list
        Expanded(
          child: allNotInterestedItems.isEmpty
              ? _buildEmptyFeedsState(h)
              : _buildHiddenFeedsList(h, allNotInterestedItems),
        ),
      ],
    );
  }

  Widget _buildEmptyFeedsState(MyHelper h) {
    return Center(
      child: MyPlaceholder(
        'No hidden feeds yet',
        footer: 'Feeds you mark as not interested will appear here',
        padding: 48,
        icon: Icon(
          CupertinoIcons.hand_thumbsdown,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildHiddenFeedsList(
    MyHelper h,
    Map<String, FeedbackCategory?> hiddenFeedIds,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: hiddenFeedIds.length,
      itemBuilder: (context, index) {
        final entry = hiddenFeedIds.entries.elementAt(index);
        final feedId = entry.key;
        final reason = entry.value;
        return _HiddenFeedTile(
          feedId: feedId,
          reason: reason,
          onRestore: () => _restoreFeed(feedId),
        );
      },
    );
  }

  Future<bool> _restoreSource(Source source) {
    return restoreAvoidedSource(context, ref, source.id);
  }

  Future<bool> _restoreFeed(String feedId) {
    return unmarkNotInterested(feedId);
  }
}

class _AvoidedSourceTile extends StatelessWidget {
  final Source source;
  final VoidCallback onRestore;

  const _AvoidedSourceTile({
    required this.source,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final defaultImage = Icon(
      CupertinoIcons.eye_slash,
      color: AppColors.error,
      size: 20,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: h.currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: h.currentTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: source.siteIcon != null
              ? CachedImageWidget(
                  imageUrl: source.siteIcon!,
                  fit: BoxFit.contain,
                  errorChild: defaultImage,
                )
              : defaultImage,
        ),
        title: Text(
          source.siteName ?? source.id,
          style: h.currentTextTheme.bodyLarge,
        ),
        subtitle: Text(
          'Avoided source',
          style: h.currentTextTheme.bodySmall?.copyWith(
            color: h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: MyIconButton(
          icon: CupertinoIcons.refresh,
          tooltip: 'Restore source',
          onPressed: onRestore,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          iconColor: AppColors.success,
        ),
      ),
    );
  }
}

class _HiddenFeedTile extends StatelessWidget {
  final String feedId;
  final FeedbackCategory? reason;
  final VoidCallback onRestore;

  const _HiddenFeedTile({
    required this.feedId,
    this.reason,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: h.currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: h.currentTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            CupertinoIcons.hand_thumbsdown,
            color: AppColors.error,
            size: 20,
          ),
        ),
        title: Text(
          'Feed ID: ${feedId.substring(0, 8)}...',
          style: h.currentTextTheme.bodyLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marked as not interested',
              style: h.currentTextTheme.bodySmall?.copyWith(
                color: h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (reason != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReasonColor(reason).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getReasonText(reason),
                  style: h.currentTextTheme.bodySmall?.copyWith(
                    color: _getReasonColor(reason),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: MyIconButton(
          icon: CupertinoIcons.refresh,
          tooltip: 'Restore feed',
          onPressed: onRestore,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          iconColor: AppColors.success,
        ),
      ),
    );
  }

  Color _getReasonColor(FeedbackCategory? reason) {
    switch (reason) {
      case FeedbackCategory.suggestion:
        return AppColors.mutedLight;
      case FeedbackCategory.inappropriate_content:
        return AppColors.error;
      case FeedbackCategory.fake_news:
        return AppColors.error;
      case FeedbackCategory.bug_report:
        return AppColors.warning;
      case FeedbackCategory.other:
        return AppColors.mutedLight;
      default:
        return AppColors.mutedLight;
    }
  }

  String _getReasonText(FeedbackCategory? reason) {
    switch (reason) {
      case FeedbackCategory.suggestion:
        return 'Suggestion';
      case FeedbackCategory.inappropriate_content:
        return 'Inappropriate Content';
      case FeedbackCategory.fake_news:
        return 'Fake News';
      case FeedbackCategory.bug_report:
        return 'Bug Report';
      case FeedbackCategory.other:
        return 'Other';
      default:
        return 'No Reason';
    }
  }
}
