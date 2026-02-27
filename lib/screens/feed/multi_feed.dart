import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/widgets/home/feed_swiper.dart';

/// Page to display a multiple feed items
class MultiFeedPage extends ConsumerStatefulWidget {
  final String feedId;
  final FeedType feedType;

  const MultiFeedPage({
    super.key,
    required this.feedId,
    required this.feedType,
  });

  @override
  ConsumerState<MultiFeedPage> createState() => _MultiFeedPageState();
}

class _MultiFeedPageState extends ConsumerState<MultiFeedPage> {
  late final int _initialIndex;

  @override
  void initState() {
    final feedItems = widget.feedType.readItems(ref);
    _initialIndex = feedItems.indexWhere((item) => item.id == widget.feedId);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Scaffold(
      backgroundColor: h.currentTheme.scaffoldBackgroundColor,
      appBar: MyAppBar(title: widget.feedType.label),
      body: FeedSwiper(
        onReload: () {},
        onSeeLatest: () {},
        onSeeHome: () {},
        feedType: widget.feedType,
        initialIndex: _initialIndex,
      ),
    );
  }
}
