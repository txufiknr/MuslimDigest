import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/icon_button.dart';

/// Reusable page AppBar widget with consistent styling
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final TabBar? bottom;
  final bool showBackButton;

  const MyAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return AppBar(
      title: Text(title, style: h.currentTextTheme.titleMedium),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      // automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? MyIconButton(
        icon: CupertinoIcons.arrow_left,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        onPressed: () => Navigator.pop(context),
        size: 40,
        iconSize: 24,
      ).squared(40).moveX(12).center() : null,
      leadingWidth: 56,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}
