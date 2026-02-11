import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  final double size;
  
  const Logo({
    super.key,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icons/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
