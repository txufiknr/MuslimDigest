import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/helpers.dart';

class MyDivider extends StatelessWidget {
  const MyDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Divider(height: 1, thickness: 1, color: h.currentTheme.colorScheme.outline);
  }
}