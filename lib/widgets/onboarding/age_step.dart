import 'package:flutter/material.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/user.dart';
import '../../utils/helpers.dart';

/// Age selection step widget for onboarding
class OnboardingAgeStep extends StatefulWidget {
  const OnboardingAgeStep({super.key});

  static const List<Map<String, String>> _ageGroups = [
    {'label': '0-12', 'value': '0-12'},
    {'label': '13-20', 'value': '13-20'},
    {'label': '21-45', 'value': '21-45'},
    {'label': '46+', 'value': '46+'},
  ];

  @override
  State<OnboardingAgeStep> createState() => _OnboardingAgeStepState();
}

class _OnboardingAgeStepState extends State<OnboardingAgeStep> {
  /// Build individual age group option
  Widget _buildAgeGroupOption(
    MyHelper h,
    Map<String, String> group,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          group['label']!,
          style: h.currentTextTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ).onTap(() async {
      await setUser(user?.copyWith(ageGroup: group['value']!));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'How old are you?',
          style: h.currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: OnboardingAgeStep._ageGroups.length,
          itemBuilder: (context, index) {
            final group = OnboardingAgeStep._ageGroups[index];
            final isSelected = user?.ageGroup == group['value'];
            return _buildAgeGroupOption(h, group, isSelected);
          },
        ),
      ],
    );
  }
}
