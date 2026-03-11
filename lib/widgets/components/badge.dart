import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

class MyBadge extends StatelessWidget {
  final MaterialColor? color;
  final String text;
  final String? description;
  final double fontSize;
  const MyBadge({this.color, required this.text, this.description, this.fontSize = 11.0, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final badgeColor = color ?? Colors.green;

    return Tooltip(
      message: description ?? text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: h.useColor(badgeColor, 50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: h.useColor(badgeColor, 700),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class ChipBadge extends StatelessWidget {
  final String text;
  final String? description;
  final MaterialColor color;
  final IconData? icon;
  const ChipBadge(this.text, {this.icon, this.description, this.color = Colors.teal, super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Semantics(
      label: description,
      tooltip: description,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: h.useColor(color, 50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: h.useColor(color, 200)!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 14, color: h.useColor(color, 800),).withPadding(right: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: h.useColor(color, 700),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}