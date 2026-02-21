import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'popup_menu_item.dart';

class MyPopupMenu extends StatelessWidget {
  final List<MyPopupMenuItem> items;
  final Widget icon;
  final void Function(String)? onSelected;

  const MyPopupMenu({
    super.key,
    required this.items,
    required this.icon,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return PopupMenuButton<String>(
      position: PopupMenuPosition.over,
      offset: Offset(0, -200),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      icon: icon,
      color: h.currentTheme.colorScheme.surface,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(h.currentTheme.colorScheme.surface),
      ),
      shape: h.popupShape,
      elevation: 0.0,
      shadowColor: Colors.transparent,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => items,
    );
  }
}
