import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslimdigest/config/colors.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/config/user.dart';
import 'package:muslimdigest/providers/user/user.dart';
import 'package:muslimdigest/utils/dialogs.dart';
import 'package:muslimdigest/utils/extensions.dart';
import 'package:muslimdigest/utils/helpers.dart';
import 'package:muslimdigest/widgets/components/app_bar.dart';
import 'package:muslimdigest/variables/user.dart';
import 'package:muslimdigest/widgets/components/button.dart';

class GenderOption extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderOption({
    super.key,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = MyHelper(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : h.currentTheme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : h.currentTheme.colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            gender == Gender.male ? Icons.male : Icons.female,
            color: isSelected
                ? AppColors.primary
                : h.currentTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            gender.label,
            style: h.inputStyle?.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : h.currentTheme.colorScheme.onSurface,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    ).onTap(onTap).expand();
  }
}

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
      backgroundColor: h.currentTheme.scaffoldBackgroundColor,
      appBar: MyAppBar(
        title: 'Edit Profile',
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
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView(
              children: <Widget>[
                // Name Field
                Text('Name', style: h.currentTextTheme.labelMedium),
            
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: h.hintStyle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: h.currentTheme.colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: h.currentTheme.colorScheme.outline,
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
                    fillColor: h.currentTheme.colorScheme.surface,
                  ),
                  style: h.inputStyle,
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
                
                const SizedBox(height: 8),
                
                // Age Group Field
                Text('Age Group', style: h.currentTextTheme.labelMedium),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: h.currentTheme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: h.currentTheme.colorScheme.surface,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAgeGroup,
                      hint: Text('Select age group', style: h.hintStyle),
                      style: h.inputStyle,
                      items: [...USER_AGE_GROUPS, 'Prefer not to say'].map((ageGroup) {
                        return DropdownMenuItem<String>(
                          value: ageGroup,
                          child: Text(ageGroup),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAgeGroup = USER_AGE_GROUPS.contains(value) ? value : null;
                          _isDirty = true;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Gender Field
                Text('Gender', style: h.currentTextTheme.labelMedium),
                
                Row(
                  children: [
                    GenderOption(
                      gender: Gender.male,
                      isSelected: _isMale,
                      onTap: () {
                        setState(() {
                          _selectedGender = _isMale ? null : Gender.male;
                          _isDirty = true;
                        });
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    GenderOption(
                      gender: Gender.female,
                      isSelected: _isFemale,
                      onTap: () {
                        setState(() {
                          _selectedGender = _isFemale ? null : Gender.female;
                          _isDirty = true;
                        });
                      },
                    ),
                  ],
                ),
              ].addItemInBetween(SizedBox(height: 8)),
            ).expand(),
            
            // Buttons
            MyButton(text: 'Save Changes', onPressed: _isDirty ? _saveProfile : null),
            const SizedBox(height: 16),
            MyButton(text: 'Cancel', outlined: true, onPressed: Navigator.of(context).pop),
          ],
        ),
      ).withPaddingAll(AppThemes.contentPadding),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(userProvider);
    final name = _nameController.text.trim();
    final updatedUser = user.copyWith(
      name: name.isEmpty ? null : name,
      ageGroup: _selectedAgeGroup,
      gender: _selectedGender,
    );
    
    await ref.read(userProvider.notifier).setValue(updatedUser);
    
    if (!mounted) return;
    setState(() {
      _isDirty = false;
    });
    showSnackBarSuccess(context, 'Profile updated successfully');
  }
}
