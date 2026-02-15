import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MyLoader extends StatelessWidget {
  final Color? color;
  const MyLoader({this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final loader = Lottie.asset('assets/lottie/loader.json');
    if (color == null) return loader;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        color!,
        BlendMode.srcATop,
      ),
      child: loader,
    );
  }
}