import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/mock/users.dart';
import 'package:muslimdigest/providers/user.dart';
import '../../utils/helpers.dart';

/// Name input step widget for onboarding
class OnboardingNameStep extends ConsumerWidget {
  const OnboardingNameStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MyHelper(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "What's your name?",
          style: h.currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            onChanged: (name) {
              final user = ref.read(userProvider) ?? newUser;
              ref.read(userProvider.notifier).setValue(user.copyWith(name: name));
            },
            style: h.currentTextTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: h.currentTextTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
