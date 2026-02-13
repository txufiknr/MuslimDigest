import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import '../components/button.dart';

/// Navigation buttons widget for onboarding steps
class OnboardingNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onPrevPressed;
  final VoidCallback? onSkipPressed;
  final VoidCallback? onNextPressed;
  final bool canProceed;
  final bool isLoading;

  const OnboardingNavigationButtons({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onPrevPressed,
    this.onSkipPressed,
    this.onNextPressed,
    this.canProceed = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    final isLastStep = currentStep == totalSteps - 1;

    return Column(
      children: [
        Row(
          children: [
            if (currentStep > 0 && !isLoading) ...[
              MyButton(
                text: 'Previous',
                onPressed: onPrevPressed,
                brightness: Brightness.dark,
                outlined: true,
              ).expand(),
              SizedBox(width: 16),
            ],
            
            MyButton(
              brightness: Brightness.dark,
              text: isLastStep ? 'Complete' : currentStep > 0 ? 'Next' : 'Continue',
              onPressed: canProceed && !isLoading ? onNextPressed : null,
              isLoading: isLoading,
            ).hero('primary-button').expand(),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Skip button
        TextButton(
          onPressed: isLoading ? null : onSkipPressed,
          child: Text(
            currentStep == 0 ? "Go back" : "I'd rather not say (Skip)",
            style: h.currentTextTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
