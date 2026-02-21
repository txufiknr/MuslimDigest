import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/config/user.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/button.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedAgeGroup;
  Gender? _selectedGender;
  bool _isDirty = false;

  bool get _isMale => _selectedGender == Gender.male;
  bool get _isFemale => _selectedGender == Gender.female;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.name);
    _selectedAgeGroup = user.ageGroup;
    _selectedGender = user.gender;
    
    _nameController.addListener(() {
      setState(() {
        _isDirty = true;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: h.currentTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_isDirty)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: h.currentTextTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).withPadding(right: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppThemes.contentPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              Text(
                'Name',
                style: h.currentTextTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: h.currentTextTheme.bodyMedium,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Age Group Field
              Text(
                'Age Group',
                style: h.currentTextTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAgeGroup,
                    hint: Text(
                      'Select age group',
                      style: h.currentTextTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    style: h.currentTextTheme.bodyMedium,
                    items: USER_AGE_GROUPS.map((ageGroup) {
                      return DropdownMenuItem<String>(
                        value: ageGroup,
                        child: Text(ageGroup),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAgeGroup = value;
                        _isDirty = true;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Gender Field
              Text(
                'Gender',
                style: h.currentTextTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isMale
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.outline,
                        width: _isMale ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _isMale
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male,
                          color: _isMale
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Gender.male.label,
                          style: h.currentTextTheme.bodyMedium?.copyWith(
                            color: _isMale
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: _isMale
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ).onTap(() {
                    setState(() {
                      _selectedGender = Gender.male;
                      _isDirty = true;
                    });
                  }).expand(),
                  
                  const SizedBox(width: 12),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isFemale
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.outline,
                        width: _isFemale ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _isFemale
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          color: _isFemale
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Gender.female.label,
                          style: h.currentTextTheme.bodyMedium?.copyWith(
                            color: _isFemale
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: _isFemale
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ).onTap(() {
                    setState(() {
                      _selectedGender = Gender.female;
                      _isDirty = true;
                    });
                  }).expand(),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Buttons
              MyButton(text: 'Save Changes', onPressed: _isDirty ? _saveProfile : null),
              const SizedBox(height: 16),
              MyButton(text: 'Cancel', outlined: true, onPressed: Navigator.of(context).pop),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(userProvider);
    final updatedUser = user.copyWith(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      ageGroup: _selectedAgeGroup,
      gender: _selectedGender,
    );
    
    await ref.read(userProvider.notifier).setValue(updatedUser);
    
    setState(() {
      _isDirty = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
      Navigator.of(context).pop();
    }
  }
}
