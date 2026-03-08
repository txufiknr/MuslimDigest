import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/feed/feed_history.dart';
import 'package:muslimdigest/providers/read_count.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

const _tourItemHeight = 36.0;

const _boxShadow = [BoxShadow(color: Colors.black12, blurRadius: 10)];

class Tour extends ConsumerWidget {
  const Tour({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyCount = ref.watch(feedHistoryProvider).total;
    final isTourEnded = historyCount >= 2;
    if (isTourEnded) return SizedBox.shrink();

    final h = MyHelper(context);
    // final invertColor = h.invertColor;
    final contrastColor = h.contrastColor;
    // final scrimColor = invertColor.withValues(alpha: .15);
    final scrimColor = contrastColor.withValues(alpha: .5);
    final scrimColorEnd = scrimColor.withValues(alpha: 0);

    final readCount = ref.watch(readCountProvider);
    final shouldNext = readCount == 0;
    final iconWidget = TourIcon(shouldNext: shouldNext);

    // TODO: according to settings
    final text = shouldNext ? "Swipe right to read next story" : "Swipe left to read previous story";
    final textWidget = TourText(text, shouldNext: shouldNext);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: shouldNext
                ? [scrimColorEnd, scrimColor]
                : [scrimColor, scrimColorEnd],
            ),
          ),
          padding: EdgeInsets.all(AppThemes.contentPadding).copyWith(top: h.screenHeight / 4),
          alignment: shouldNext
            ? Alignment.centerRight
            : Alignment.centerLeft,
          child: Row(
            children: (shouldNext ? [
              textWidget.flexible(),
              iconWidget
            ] : [
              iconWidget,
              textWidget.flexible(),
            ]).addItemInBetween(SizedBox(width: 16,)),
          ),
        )
      ],
    ).ignore();
  }
}

class TourIcon extends StatelessWidget {
  final bool shouldNext;
  const TourIcon({this.shouldNext = true, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final contrastColor = h.contrastColor;
    // TODO: according to settings
    final icon = shouldNext ? CupertinoIcons.chevron_right_circle : CupertinoIcons.chevron_left_circle;
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

class TourText extends StatelessWidget {
  final String text;
  final bool shouldNext;
  const TourText(this.text, {this.shouldNext = true, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final contrastColor = h.contrastColor;
    // TODO: according to settings
    final textAlign = shouldNext ? TextAlign.right : TextAlign.left;
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