import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/mock/users.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import '../config/constants.dart';
import '../config/colors.dart';
import '../utils/functions.dart';
import '../utils/helpers.dart';
import '../widgets/components/logo.dart';
import '../widgets/components/button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _startReadingNow(BuildContext context) async {
    prefs.setString('user', jsonEncode(anonymousUser.toJson()));
    context.go('/home');
  }

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
            Center(child: Logo(size: h.screenWidth).scale(1.2)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    SizedBox(height: 16,),

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
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    Spacer(),
                    
                    // Get started button
                    MyButton(
                      variant: MyButtonVariant.success,
                      text: 'Select interests',
                      onPressed: () => context.push('/welcome'),
                      icon: Icon(CupertinoIcons.square_grid_2x2),
                    ).hero('primary-button'),
                    SizedBox(height: 16),

                    Text("For more personalized experience\nor just:", textAlign: TextAlign.center, style: h.currentTextTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    )),
                    SizedBox(height: 12),
                    
                    // Get started button
                    MyButton(
                      text: 'Start reading now',
                      onPressed: () => _startReadingNow(context),
                      brightness: Brightness.dark,
                      icon: Icon(CupertinoIcons.book),
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
                        TextButton(
                          child: Text(
                            'Privacy Policy',
                            style: h.currentTextTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onPressed: () => openUrl(APP_URL_PRIVACY),
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
