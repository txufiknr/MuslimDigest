import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/utils/extensions.dart';
import '../../utils/helpers.dart';

/// Gender selection step widget for onboarding
class OnboardingGenderStep extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const OnboardingGenderStep({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  /// Build individual gender option
  Widget _buildGenderOption(
    MyHelper h,
    String gender,
    VoidCallback onTap,
    bool isSelected,
  ) {
    final label = gender == 'male' ? 'muslim' : 'muslimah';
    final lottiePath = 'assets/lottie/$gender.json';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected 
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: isSelected 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: 0.3),
                width: isSelected ? 3 : 2,
              ),
            ),
            child: Lottie.asset(lottiePath).scale(gender == 'male' ? 2.2 : 2).moveX(gender == 'male' ? 0 : 15).clipRadius(120),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toCapitalized(),
          style: h.currentTextTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select your gender',
          style: MyHelper(context).currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGenderOption(
              h,
              'male',
              () => onGenderChanged('male'),
              selectedGender == 'male',
            ),
            _buildGenderOption(
              h,
              'female',
              () => onGenderChanged('female'),
              selectedGender == 'female',
            ),
          ],
        ),
      ],
    );
  }
}
