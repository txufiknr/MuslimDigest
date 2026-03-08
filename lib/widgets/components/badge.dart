import 'package:flutter/material.dart';
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