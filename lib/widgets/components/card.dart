import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/user/streaks.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/format.dart';
import 'package:muslimdigest/utils/helpers.dart';

class MyCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double? paddingHorizontal;
  final double? paddingVertical;
  final double? margin;
  const MyCard({this.onTap, this.margin, this.paddingHorizontal, this.paddingVertical, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Container(
      margin: EdgeInsets.all(margin ?? AppThemes.contentPadding),
      decoration: BoxDecoration(
        color: h.currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: h.currentTheme.colorScheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: child.withPadding(
            horizontal: paddingHorizontal ?? AppThemes.contentPadding,
            vertical: paddingVertical ?? AppThemes.contentPadding,
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final int total;
  final String label;
  const StatCard({required this.total, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return MyCard(margin: 8, child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatNumber(total), textAlign: TextAlign.center, style: h.currentTextTheme.titleMedium, maxLines: 1, softWrap: false,),
        Text(label, textAlign: TextAlign.center, maxLines: 1, softWrap: false,),
      ],
    ));
  }
}

class StreaksCard extends ConsumerWidget {
  const StreaksCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.read(streaksProvider);
    final currentStreak = streaks.currentStreak;
    final longestStreak = streaks.longestStreak;
    return Row(
      children: [
        StatCard(
          total: currentStreak,
          label: 'Current Streak'
        ).expand(),
        StatCard(
          total: longestStreak,
          label: 'Longest Streak'
        ).expand(),
      ],
    );
  }
}

class HookCard extends StatelessWidget {
  final String text;
  final double? fontSize;
  final TextStyle? textStyle;
  final MaterialColor color;
  const HookCard(this.text, {this.color = Colors.teal, this.textStyle, this.fontSize, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: h.useColor(color, 50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: h.useColor(color, 100)!, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: textStyle ?? h.currentTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: h.useColor(color, 800),
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class ContextCard extends StatelessWidget {
  final String text;
  final String? caption;
  final double? fontSize;
  final TextStyle? textStyle;
  final MaterialColor color;
  const ContextCard(this.text, {this.caption, this.color = Colors.teal, this.textStyle, this.fontSize, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: h.useColor(color, 50),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: h.useColor(color, 200)!, width: 4),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.lightbulb, color: color, size: 16,),
              SizedBox(width: 4,),
              Text(caption ?? "Context", style: h.currentTextTheme.titleSmall?.copyWith(fontSize: 15),).expand(),
            ],
          ),
          SizedBox(height: 4,),
          Text(
            text,
            style: textStyle ?? h.currentTextTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}