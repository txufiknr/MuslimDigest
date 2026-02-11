import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../config/colors.dart';
import '../utils/functions.dart';
import '../utils/helpers.dart';
import '../widgets/components/logo.dart';
import '../widgets/components/button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentLight,
              AppColors.primary,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(child: Transform.scale(
              scale: 1.2,
              child: Logo(size: h.screenWidth),
            )),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // App title
                    Text(
                      APP_NAME,
                      style: h.currentTextTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // App description
                    Text(
                      APP_DESCRIPTION,
                      style: h.currentTextTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // const SizedBox(height: 64),
                    Spacer(),
                    
                    // Get started button
                    MyButton(
                      text: 'Get Started',
                      onPressed: () => context.go('/welcome'),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Copyright and privacy policy
                    Column(
                      children: [
                        Text(
                          '© ${DateTime.now().year} $APP_COPYRIGHT',
                          style: h.currentTextTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => openUrl(APP_URL_PRIVACY),
                          child: Text(
                            'Privacy Policy',
                            style: h.currentTextTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
