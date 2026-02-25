import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/helpers.dart';

class MyPopupMenuItem extends PopupMenuItem<String> {
  final IconData icon;
  final String text;

  MyPopupMenuItem({
    super.key,
    required String value,
    required this.icon,
    required this.text,
  }) : super(value: value, child: _PopupMenuItemContent(icon: icon, text: text));
}

class _PopupMenuItemContent extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PopupMenuItemContent({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Row(
      children: [
        Icon(icon, size: 16, color: h.currentTheme.colorScheme.onSurface),
        const SizedBox(width: 8),
        Text(text, style: h.currentTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal)),
      ],
    );
  }
}
