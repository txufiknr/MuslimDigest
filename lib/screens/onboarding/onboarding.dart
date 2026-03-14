import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/variables/app.dart';
import 'package:muslimdigest/variables/user.dart';
import '../../config/constants.dart';
import '../../config/colors.dart';
import '../../utils/functions.dart';
import '../../utils/helpers.dart';
import '../../widgets/components/logo.dart';
import '../../widgets/components/button.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  /// Start reading as a guest (global)
  void _startReadingNow(BuildContext context, WidgetRef ref) async {
    await ref.read(userProvider.notifier).setValue(PrefData.user);
    ref.read(feedProvider.notifier).load(timeoutMs: 60000); // load digest feed immediately
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);

    return Theme(
      data: AppThemes.darkTheme,
      child: Scaffold(
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
                        height: 56,
                      ).hero('primary-button'),
                      SizedBox(height: 16),
      
                      Text("For more personalized experience\nor just:", textAlign: TextAlign.center, style: h.currentTextTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      )),
                      SizedBox(height: 12),
                      
                      // Get started button
                      MyButton(
                        text: 'Start reading now',
                        onPressed: () => _startReadingNow(context, ref),
                        brightness: Brightness.dark,
                        icon: Icon(CupertinoIcons.book),
                        height: 56,
                      ),
      
                      const SizedBox(height: 24),
                      
                      // Copyright and privacy policy
                      Column(
                        children: [
                          Text(
                            copyrightText,
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
      ),
    );
  }
}
