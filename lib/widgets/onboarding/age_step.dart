import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/user.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import '../../utils/helpers.dart';

/// Age selection step widget for onboarding
class OnboardingAgeStep extends ConsumerWidget {
  const OnboardingAgeStep({super.key});

  /// Build individual age group option
  Widget _buildAgeGroupOption(
    MyHelper h,
    String ageGroup,
    bool isSelected,
    WidgetRef ref,
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
          ageGroup,
          style: h.currentTextTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ).onTap(() async {
      final user = ref.read(userProvider);
      await ref.read(userProvider.notifier).setValue(user.copyWith(ageGroup: ageGroup));
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    final user = ref.watch(userProvider);

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
          itemCount: USER_AGE_GROUPS.length,
          itemBuilder: (context, index) {
            final ageGroup = USER_AGE_GROUPS[index];
            final isSelected = user.ageGroup == ageGroup;
            return _buildAgeGroupOption(h, ageGroup, isSelected, ref);
          },
        ),
      ],
    );
  }
}
