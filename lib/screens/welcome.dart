import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/variables.dart';
import 'package:uuid/uuid.dart';
import '../config/colors.dart';
import '../utils/helpers.dart';
import '../widgets/components/button.dart';
import '../services/api_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _pageController = PageController();
  final _steps = <String>['Gender', 'Age', 'Name'];
  int _currentStep = 0;
  
  // Form data
  String _userName = '';
  String _gender = '';
  String _ageGroup = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _complete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _complete() async {
    // TODO: loading state, handle error

    // Save user ID to shared preferences
    final userId = const Uuid().v7();
    debugPrint('[welcome] User ID: $userId');
    await prefs.setString('user_id', userId);

    // Post user data to backend API
    debugPrint('[welcome] Registering user...');
    final result = await ApiService.registerUser(userId, _userName, _gender, _ageGroup);
    debugPrint('[welcome] Registration result: $result');
    
    if (result['success']) {
      debugPrint('[welcome] User registered successfully: ${result['data']}');
    } else {
      debugPrint('[welcome] Registration failed: ${result['error']}');
    }

    // Navigate to home screen
    if (mounted) {
      context.go('/home');
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _gender.isNotEmpty;
      case 1:
        return _ageGroup.isNotEmpty;
      case 2:
        return _userName.trim().isNotEmpty;
      default:
        return false;
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
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(h),
                    
                    const SizedBox(height: 32),
                    
                    // Step title
                    Text(
                      'Step ${_currentStep + 1} of ${_steps.length}',
                      style: h.currentTextTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _steps[_currentStep],
                      style: h.currentTextTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // PageView for steps
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildGenderStep(h),
                          _buildAgeStep(h),
                          _buildNameStep(h),
                        ].map((widget) => Center(child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: widget,
                        ))).toList(),
                      ),
                    ),
                    
                    // Navigation buttons
                    _buildNavigationButtons(h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(MyHelper h) {
    return Row(
      children: List.generate(
        _steps.length,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              color: index <= _currentStep 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep(MyHelper h) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'What\'s your name?',
          style: h.currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _userName = value;
              });
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

  Widget _buildGenderStep(MyHelper h) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select your gender',
          style: h.currentTextTheme.labelLarge?.copyWith(
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
              () => setState(() => _gender = 'male'),
              _gender == 'male',
            ),
            _buildGenderOption(
              h,
              'female',
              () => setState(() => _gender = 'female'),
              _gender == 'female',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    MyHelper h,
    String gender,
    VoidCallback onTap,
    bool isSelected,
  ) {
    final label = gender == 'male' ? 'muslim' : 'muslimah';
    final lottiePath = 'assets/lottie/$label.json';
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

  Widget _buildAgeStep(MyHelper h) {
    final ageGroups = [
      {'label': '0-12', 'value': '0-12'},
      {'label': '13-20', 'value': '13-20'},
      {'label': '21-45', 'value': '21-45'},
      {'label': '46+', 'value': '46+'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select your age',
          style: h.currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
          ),
          itemCount: ageGroups.length,
          itemBuilder: (context, index) {
            final group = ageGroups[index];
            final isSelected = _ageGroup == group['value'];
            
            return GestureDetector(
              onTap: () => setState(() => _ageGroup = group['value']!),
              child: Container(
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(MyHelper h) {
    return Column(
      children: [
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: MyOutlinedButton(
                  text: 'Previous',
                  onPressed: _previousStep,
                  brightness: Brightness.dark,
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),
            
            Expanded(
              child: MyButton(
                brightness: Brightness.dark,
                text: _currentStep == _steps.length - 1 ? 'Complete' : _currentStep > 0 ? 'Next' : 'Continue',
                onPressed: _canProceed() ? _nextStep : null,
              ).hero('primary-button'),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Skip button
        TextButton(
          child: Text(
            _currentStep == 0 ? "Go back" : "I'd rather not say (Skip)",
            style: h.currentTextTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
          onPressed: () {
            if (_currentStep == 0) {
              context.pop();
              return;
            }

            // Reset form data for current step when skipping
            switch (_currentStep) {
              case 0: _gender = ''; break;
              case 1: _ageGroup = ''; break;
              case 2: _userName = ''; break;
            }
            if (_currentStep < _steps.length - 1) {
              _nextStep();
            } else {
              _complete();
            }
          },
        ),
      ],
    );
  }
}
