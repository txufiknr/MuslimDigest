import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/helpers.dart';

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
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}
