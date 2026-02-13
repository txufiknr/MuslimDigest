import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/users.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/onboarding/navigation_buttons.dart';
import '../config/colors.dart';
import '../utils/helpers.dart';
import '../services/api.dart';
import '../widgets/onboarding/progress_indicator.dart';
import '../widgets/onboarding/name_step.dart';
import '../widgets/onboarding/gender_step.dart';
import '../widgets/onboarding/age_step.dart';
import '../widgets/onboarding/interests_step.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _pageController = PageController();
  final _steps = <String>['Gender', 'Age', 'Interests', 'Name'];
  var _currentStep = 0;
  var _isLoading = false;

  bool get _isLastStep => _currentStep == _steps.length - 1;
  
  // Form data
  var _userName = '';
  var _gender = ''; // male / female
  var _ageGroup = '';
  final _availableTopics = <String>[];
  final _selectedTopics = <String>[];

  Future<void> _initForm() async {
    final response = await ApiService.get('topics');
    if (response.success && response.data != null) {
      debugPrint('[welcome] Available topics: ${response.data}');
      setState(() {
        _availableTopics.addAll(List<String>.from(response.data));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Move to the next step
  void _nextStep() {
    if (_isLastStep) return unawaited(_complete());
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
    if (_currentStep == 0) {
      return context.pop();
    }

    // Reset form data for current step when skipping
    switch (_currentStep) {
      case 0: _gender = ''; break;
      case 1: _ageGroup = ''; break;
      case 2: _selectedTopics.clear(); break;
      case 3: _userName = ''; break;
    }
    if (_isLastStep) {
      _complete();
    } else {
      _nextStep();
    }
  }

  /// Complete the welcome process
  Future<void> _complete() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Prepare user data and preferences
    final newUser = User(userId: userId, name: _userName, gender: _gender, ageGroup: _ageGroup);
    final newUserPreferences = UserPreferences(userId: userId, topics: _selectedTopics);

    // 2. Post user data and preferences to backend API
    debugPrint('[welcome] Registering user: $newUser');
    debugPrint('[welcome] Registering preferences: $newUserPreferences');
    final responses = await Future.wait([
      ApiService.post('user', newUser.toJson()),
      ApiService.post('preferences', newUserPreferences.toJson()),
    ]);

    // 3. Process responses using the utility function
    await handleUserResponses(responses, newUser: newUser, newUserPreferences: newUserPreferences);

    // 4. Check if all API calls were successful
    final successCount = responses.where((result) => result.success).length;
    debugPrint('[welcome] Registration result: $successCount/${responses.length} success');
    final isSuccess = successCount == responses.length;
    if (isSuccess) {
      debugPrint('[welcome] User registered successfully');
    } else {
      debugPrint('[welcome] Registration failed');
      // Show bottom modal sheet with error details and retry options
      if (mounted) {
        final shouldRetry = await showRetryableError(
          context,
          title: 'Failed to save your data',
          message: 'Please check your internet connection and try again.',
          footer: 'We\'ll save your progress locally for now.',
        );
        if (shouldRetry && mounted) {
          return _complete();
        }
      }
    }

    // 5. Navigate to home screen
    if (mounted) context.go('/home');
    // if (!mounted) return;
    // if (isSuccess) return context.go('/home');
    // setState(() {
    //   _isLoading = false;
    // });
  }

  /// Check if the current step can proceed
  bool get _canProceed {
    if (_isLoading) return false;
    switch (_currentStep) {
      case 0: return _gender.isNotEmpty;
      case 1: return _ageGroup.isNotEmpty;
      case 2: return _selectedTopics.isNotEmpty;
      case 3: return _userName.trim().isNotEmpty;
      default: return false;
    }
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
                          padding: const EdgeInsets.symmetric(vertical: 32),
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
                      isLoading: _isLoading,
                    ).withPaddingHorizontal(32),
                  ],
                ),
              ),
            ),
          ],
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
    return OnboardingNameStep(
      userName: _userName,
      onNameChanged: (value) {
        setState(() {
          _userName = value;
        });
      },
      isLoading: _isLoading,
    );
  }

  /// Build gender selection step
  Widget _buildGenderStep() {
    return OnboardingGenderStep(
      selectedGender: _gender,
      onGenderChanged: (value) {
        setState(() {
          _gender = value;
        });
      },
    );
  }

  /// Build age selection step
  Widget _buildAgeStep() {
    return OnboardingAgeStep(
      selectedAgeGroup: _ageGroup,
      onAgeGroupChanged: (value) {
        setState(() {
          _ageGroup = value;
        });
      },
    );
  }

  /// Build interests step
  Widget _buildInterestsStep() {
    return OnboardingInterestsStep(
      availableTopics: _availableTopics,
      selectedTopics: _selectedTopics,
      onTopicsChanged: (value) {
        setState(() {
          _selectedTopics..clear()..addAll(value);
        });
      },
    );
  }
}