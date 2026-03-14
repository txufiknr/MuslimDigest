import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/providers/feed/feed.dart';
import 'package:muslimdigest/providers/user/preferences.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/widgets/onboarding/navigation_buttons.dart';
import '../../config/colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/onboarding/progress_indicator.dart';
import '../../widgets/onboarding/name_step.dart';
import '../../widgets/onboarding/gender_step.dart';
import '../../widgets/onboarding/age_step.dart';
import '../../widgets/onboarding/interests_step.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _pageController = PageController();
  final _steps = <String>['Gender', 'Age', 'Interests', 'Name'];
  var _currentStep = 0;

  bool get _isLastStep => _currentStep == _steps.length - 1;
  User get _newUser => ref.watch(userProvider);
  UserPreferences get _newPreferences => ref.watch(preferencesProvider);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Move to the next step or complete if last step
  void _nextStep() {
    if (_isLastStep) return _complete();

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep++;
    });
  }

  /// Move to the previous step
  void _previousStep() {
    if (_isLastStep) unfocus();
    if (_currentStep == 0) {
      return context.pop();
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep--;
    });
  }

  void _skipStep() {
    // Go back to previous screen if on first step
    if (_currentStep == 0) return context.pop();

    // Reset form data for current step when skipping
    final u = ref.read(userProvider.notifier);
    final p = ref.read(preferencesProvider.notifier);
    final currentUser = ref.read(userProvider);
    final currentPreferences = ref.read(preferencesProvider);
    switch (_currentStep) {
      case 0: u.setValue(currentUser.copyWith(gender: null)); break;
      case 1: u.setValue(currentUser.copyWith(ageGroup: '')); break;
      case 2: p.setValue(currentPreferences.copyWith(topics: {})); break;
      case 3: u.setValue(currentUser.copyWith(name: '')); break;
    }

    // Move to next step or complete if last step
    _nextStep();
  }

  /// Complete the welcome process
  void _complete() {
    ref.read(feedProvider.notifier).load(timeoutMs: 60000); // load digest feed immediately
    context.go('/home');
  }

  /// Check if the current step can proceed
  bool get _canProceed {
    switch (_currentStep) {
      case 0: return _newUser.gender != null;
      case 1: return _newUser.ageGroup?.isNotEmpty == true;
      case 2: return _newPreferences.topics.isNotEmpty;
      case 3: return _newUser.name?.trim().isNotEmpty == true;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      // Progress indicator
                      _buildProgressIndicator().withPaddingHorizontal(32),
                      
                      const SizedBox(height: 32),
                      
                      // Step title
                      Text(
                        'Step ${_currentStep + 1} of ${_steps.length}',
                        style: h.currentTextTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ).withPaddingHorizontal(32),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        _steps[_currentStep],
                        style: h.currentTextTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ).withPaddingHorizontal(32),
                      
                      // PageView for steps
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildGenderStep(),
                            _buildAgeStep(),
                            _buildInterestsStep(),
                            _buildNameStep(),
                          ].map((widget) => Center(child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                            child: widget,
                          ))).toList(),
                        ),
                      ),
                      
                      // Navigation buttons
                      OnboardingNavigationButtons(
                        currentStep: _currentStep,
                        totalSteps: _steps.length,
                        onPrevPressed: _previousStep,
                        onSkipPressed: _skipStep,
                        onNextPressed: _nextStep,
                        canProceed: _canProceed,
                      ).withPaddingHorizontal(32),
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

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    return OnboardingProgressIndicator(
      currentStep: _currentStep,
      totalSteps: _steps.length,
    );
  }

  /// Build name input step
  Widget _buildNameStep() {
    return OnboardingNameStep();
  }

  /// Build gender selection step
  Widget _buildGenderStep() {
    return OnboardingGenderStep();
  }

  /// Build age selection step
  Widget _buildAgeStep() {
    return OnboardingAgeStep();
  }

  /// Build interests step
  Widget _buildInterestsStep() {
    return OnboardingInterestsStep();
  }
}