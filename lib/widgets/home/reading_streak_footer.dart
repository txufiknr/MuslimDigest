import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/variables/feed.dart';
import 'package:muslimdigest/widgets/animations/loading_indicator_bar.dart';
import '../../widgets/animations/progress_bar.dart';
import '../../config/feeds.dart';
import '../../utils/helpers.dart';

/// Footer widget displaying reading streak progress
class ReadingStreakFooter extends ConsumerWidget {
  const ReadingStreakFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedType = ref.watch(feedTypeProvider);
    final isFeedLoading = feedType.watch(ref).isLoading;

    // Loading indicator at the bottom
    if (isFeedLoading) return LoadingIndicatorBar();
    final isStreakToday = ref.watch(streaksProvider.notifier).isStreakToday;
    if (isStreakToday || feedType != FeedType.digest) return SizedBox.shrink();

    // Reading streak progress
    final readCount = ref.watch(readCountProvider);
    final readTarget = ref.watch(feedProvider).items?.length ?? DAILY_READ_TARGET;
    final progress = readCount / readTarget;
    final h = MyHelper(context);
    return AnimatedProgressBar(
      progress: progress,
      height: 6,
      backgroundColor: h.currentTheme.colorScheme.surfaceContainerHighest,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
