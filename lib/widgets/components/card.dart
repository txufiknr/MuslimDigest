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