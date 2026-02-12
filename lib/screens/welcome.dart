import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:muslimdigest/models/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/functions.dart';
import 'package:muslimdigest/utils/variables.dart';
import 'package:uuid/uuid.dart';
import '../config/colors.dart';
import '../utils/helpers.dart';
import '../widgets/components/button.dart';
import '../services/api.dart';

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

  /// Complete the welcome process
  void _complete() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Crate and save user ID to shared preferences
    final userId = const Uuid().v7();
    debugPrint('[welcome] User ID: $userId');
    await prefs.setString('user_id', userId);

    // 2. Prepare user data and preferences
    final newUser = User(userId: userId, name: _userName, gender: _gender, ageGroup: _ageGroup);
    final newUserPreferences = UserPreferences(userId: userId, topics: _selectedTopics);

    // 3. Post user data and preferences to backend API
    debugPrint('[welcome] Registering user: $newUser');
    debugPrint('[welcome] Registering preferences: $newUserPreferences');
    final results = await Future.wait([
      ApiService.post('user', newUser.toJson()),
      ApiService.post('preferences', newUserPreferences.toJson()),
    ]);
    final successCount = results.where((result) => result.success).length;
    debugPrint('[welcome] Registration result: $successCount/${results.length} success');

    // 4. Check if all API calls were successful
    final isSuccess = successCount == results.length;
    if (isSuccess) {
      debugPrint('[welcome] User registered successfully');
    } else {
      debugPrint('[welcome] Registration failed');
    }

    // 5. Navigate to home screen
    if (!mounted) return;
    if (isSuccess) return context.go('/home');
    setState(() {
      _isLoading = false;
    });
  }

  /// Check if the current step can proceed
  bool _canProceed() {
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
                    _buildProgressIndicator(h).withPaddingHorizontal(32),
                    
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
                          _buildGenderStep(h),
                          _buildAgeStep(h),
                          _buildInterestsStep(h),
                          _buildNameStep(h),
                        ].map((widget) => Center(child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: widget,
                        ))).toList(),
                      ),
                    ),
                    
                    // Navigation buttons
                    _buildNavigationButtons(h).withPaddingHorizontal(32),
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

  /// Build name input step
  Widget _buildNameStep(MyHelper h) {
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
            readOnly: _isLoading,
            enableInteractiveSelection: !_isLoading,
          ),
        ),
      ],
    );
  }

  /// Build gender selection step
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

  /// Build gender option
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

  /// Build age selection step
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
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

  /// Build interests selection step
  Widget _buildInterestsStep(MyHelper h) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'What interests you?',
          style: h.currentTextTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Select all that apply',
          style: h.currentTextTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        if (_availableTopics.isEmpty)
          (_gender.isNotEmpty
              ? Lottie.asset('assets/lottie/${_gender == 'male' ? 'muslim' : 'muslimah'}.json', height: 200)
              : CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )).center()
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _availableTopics.map((topic) {
              final isSelected = _selectedTopics.contains(topic);
              return FilterChip(
                label: Text(
                  topic.toCapitalized(),
                  style: h.currentTextTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTopics.add(topic);
                    } else {
                      _selectedTopics.remove(topic);
                    }
                  });
                },
                backgroundColor: AppColors.accentLight.withValues(alpha: .9),
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                pressElevation: 0,
                selectedColor: Colors.white,
                selectedShadowColor: Colors.transparent,
                // checkmarkColor: AppColors.primary,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ).withPaddingHorizontal(16),
      ],
    );
  }

  Widget _buildNavigationButtons(MyHelper h) {
    return Column(
      children: [
        Row(
          children: [
            if (_currentStep > 0 && !_isLoading) ...[
              MyButton(
                text: 'Previous',
                onPressed: _previousStep,
                brightness: Brightness.dark,
                outlined: true,
              ).expand(),
              SizedBox(width: 16),
            ],
            
            MyButton(
              brightness: Brightness.dark,
              text: _isLastStep ? 'Complete' : _currentStep > 0 ? 'Next' : 'Continue',
              onPressed: _canProceed() ? _nextStep : null,
              isLoading: _isLoading,
            ).hero('primary-button').expand(),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Skip button
        TextButton(
          onPressed: _isLoading ? null : () {
            if (_currentStep == 0) {
              context.pop();
              return;
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
          },
          child: Text(
            _currentStep == 0 ? "Go back" : "I'd rather not say (Skip)",
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
