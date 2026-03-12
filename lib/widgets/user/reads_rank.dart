import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/helpers.dart';

class UserReadsRank extends ConsumerWidget {
  final Brightness brightness;
  const UserReadsRank({this.brightness = Brightness.light, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final user = ref.watch(userProvider);
    final color = brightness == Brightness.dark ? AppColors.surfaceLight : AppColors.surfaceDark;

    return Text.rich(
      TextSpan(
        children: user.totalReads == 0 ? [
          TextSpan(
            // text: "${user.totalReadsRank.badge}  You have read at least ",
            text: "Welcome to $APP_NAME! $APP_DESCRIPTION  🙏",
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ] : [
          TextSpan(
            // text: "${user.totalReadsRank.badge}  You have read at least ",
            text: "You have read at least ",
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.9),
            ),
          ),
          TextSpan(
            text: "${user.totalReads > 99 ? '99+' : user.totalReads}",
            style: h.currentTextTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: " articles in last 7 days  ${user.totalReadsRank.badge}",
            style: h.currentTextTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}