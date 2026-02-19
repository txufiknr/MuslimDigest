import 'package:flutter/material.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';

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

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App logo
        const Logo(size: 180).pulseIt(duration: 3000, scaleEnd: 1.1),
        
        const SizedBox(height: 32),
        
        // App title
        Text(
          APP_NAME,
          style: h.currentTextTheme.headlineLarge?.copyWith(
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // App subtitle
        Text(
          APP_TAGLINE,
          style: h.currentTextTheme.bodyMedium?.copyWith(
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}