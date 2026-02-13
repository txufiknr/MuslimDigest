import 'package:flutter/material.dart';

class MyLoader extends StatelessWidget {
  final Color? color;
  const MyLoader({this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      valueColor: color == null ? null : AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }
}