import 'package:flutter/material.dart';
import 'package:muslimdigest/config/constants.dart';

class Logo extends StatelessWidget {
  final double size;
  
  const Logo({
    super.key,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      APP_ASSETS_LOGO,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
