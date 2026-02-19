import 'package:flutter/material.dart';

class MyBadge extends StatelessWidget {
  final MaterialColor color;
  final String text;
  final String? description;
  const MyBadge({this.color = Colors.green, required this.text, this.description, super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description ?? text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color[700],
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}