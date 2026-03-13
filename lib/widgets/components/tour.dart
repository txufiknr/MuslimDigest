import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/feed/feed_history.dart';
import 'package:muslimdigest/providers/feed_type.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/providers/user/settings.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

const _tourItemHeight = 36.0;

const _boxShadow = [BoxShadow(color: Colors.black12, blurRadius: 10)];

class Tour extends ConsumerWidget {
  const Tour({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyCount = ref.watch(feedHistoryProvider).total;
    final isTourExited = historyCount >= 5;

    if (isTourExited) return SizedBox.shrink();

    final isLoading = !ref.watch(feedTypeProvider).watch(ref).isAvailable;
    final isTourEnded = historyCount >= 2;
    final shouldDismiss = isLoading || isTourEnded;

    final h = MyHelper(context);
    final accentColor = h.accentColor;
    final scrimColor = accentColor.withValues(alpha: .15);
    final scrimColorEnd = scrimColor.withValues(alpha: 0);

    final readCount = ref.watch(readCountProvider);
    final shouldNext = readCount == 0;
    final iconWidget = TourIcon(shouldNext: shouldNext);

    final swipeDirection = ref.read(settingsProvider).swipeDirection;
    final nextDirection = swipeDirection;
    final prevDirection = swipeDirection.opposite;
    final text = shouldNext ? "Swipe ${nextDirection.name} to read next story" : "Swipe ${prevDirection.name} to read previous story";
    final textWidget = TourText(text, shouldNext: shouldNext);
    final mainAxisAlignment = shouldNext && nextDirection.isLeft ? MainAxisAlignment.start : MainAxisAlignment.end;

    return AnimatedOpacity(
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 1000),
      opacity: shouldDismiss ? 0 : 1,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: shouldNext
                  ? [scrimColor, scrimColorEnd]
                  : [scrimColorEnd, scrimColor]
              ),
            ),
            padding: EdgeInsets.all(AppThemes.contentPadding).copyWith(top: h.screenHeight / 4),
            alignment: shouldNext
              ? Alignment.centerRight
              : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: mainAxisAlignment,
              children: (shouldNext && nextDirection.isLeft ? [
                iconWidget,
                textWidget.flexible(),
              ] : [
                textWidget.flexible(),
                iconWidget,
              ]).addItemInBetween(SizedBox(width: 16,)),
            ),
          )
        ],
      ).ignore(),
    );
  }
}

class TourIcon extends ConsumerWidget {
  final bool shouldNext;
  const TourIcon({this.shouldNext = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final contrastColor = h.contrastColor;

    final swipeDirection = ref.read(settingsProvider).swipeDirection;
    final nextDirection = swipeDirection;
    final icon = shouldNext && nextDirection.isLeft ? CupertinoIcons.chevron_left_circle : CupertinoIcons.chevron_right_circle;

    return Container(
      decoration: BoxDecoration(
        color: contrastColor,
        shape: BoxShape.circle,
        boxShadow: _boxShadow
      ),
      alignment: Alignment.center,
      width: _tourItemHeight,
      height: _tourItemHeight,
      child: Icon(icon, size: 30, color: AppColors.primary)
    ).arrowIt(offset: 10);
  }
}

class TourText extends ConsumerWidget {
  final String text;
  final bool shouldNext;
  const TourText(this.text, {this.shouldNext = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final contrastColor = h.contrastColor;

    final swipeDirection = ref.read(settingsProvider).swipeDirection;
    final nextDirection = swipeDirection;
    final textAlign = shouldNext && nextDirection.isLeft ? TextAlign.left : TextAlign.right;

    return Container(
      decoration: BoxDecoration(
        color: contrastColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _boxShadow
      ),
      height: _tourItemHeight,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(text, textAlign: textAlign, maxLines: 1, softWrap: false, style: h.currentTextTheme.bodySmall?.copyWith(
        fontSize: 16,
        height: 1.6
      ),)
    );
  }
}