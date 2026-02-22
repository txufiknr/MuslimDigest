import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/providers/read_count.dart';
import '../../widgets/animations/progress_bar.dart';
import '../../config/feeds.dart';
import '../../utils/helpers.dart';

/// Footer widget displaying reading streak progress
class ReadingStreakFooter extends ConsumerWidget {
  const ReadingStreakFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final readCount = ref.watch(readCountProvider);
    final progress = readCount / DAILY_READ_TARGET;

    return AnimatedProgressBar(
      progress: progress,
      height: 6,
      backgroundColor: h.currentTheme.colorScheme.outline,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
