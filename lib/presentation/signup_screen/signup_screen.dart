// import 'package:camera/camera.dart'; // TODO: Add camera package if needed
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/password_strength_widget.dart';
import './widgets/profile_photo_widget.dart';
import './widgets/terms_modal_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  // Form state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;
  // XFile? _profilePhoto; // TODO: Re-enable when camera package is added
  dynamic _profilePhoto;

  // Validation state
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;
  bool _fullNameValid = false;

  // Focus nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _fullNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupFormListeners();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _scrollController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fullNameFocus.dispose();
    super.dispose();
  }

  void _setupFormListeners() {
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    _fullNameController.addListener(_validateFullName);
  }

  void _validateEmail() {
    final email = _emailController.text;
    setState(() {
      _emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _passwordValid = password.length >= 8 &&
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[0-9]'));
    });
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    setState(() {
      _confirmPasswordValid =
          _confirmPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text == _passwordController.text;
    });
  }

  void _validateFullName() {
    setState(() {
      _fullNameValid = _fullNameController.text.trim().length >= 2;
    });
  }

  bool get _isFormValid {
    return _emailValid &&
        _passwordValid &&
        _confirmPasswordValid &&
        _fullNameValid &&
        _acceptTerms;
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TermsModalWidget(),
    );
  }

  Future<void> _createAccount() async {
    // Prevent multiple simultaneous executions
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();

      // Create Firebase account (includes email verification)
      print('🔐 Creating Firebase account for: $email');
      final result = await authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success message (like reference code)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Verification email sent! Please check your inbox.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );

          // Navigate to login screen (like reference code)
          Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'An error occurred',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      print('Signup error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An unexpected error occurred. Please try again.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),
                      _buildProfilePhotoSection(),
                      SizedBox(height: 4.h),
                      _buildFullNameField(),
                      SizedBox(height: 3.h),
                      _buildEmailField(),
                      SizedBox(height: 3.h),
                      _buildPasswordField(),
                      PasswordStrengthWidget(
                        password: _passwordController.text,
                      ),
                      SizedBox(height: 3.h),
                      _buildConfirmPasswordField(),
                      SizedBox(height: 4.h),
                      _buildTermsCheckbox(),
                      SizedBox(height: 4.h),
                      _buildCreateAccountButton(),
                      SizedBox(height: 3.h),
                      _buildLoginLink(),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Create Account',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          ProfilePhotoWidget(
            onPhotoSelected: (photo) {
              setState(() {
                _profilePhoto = photo;
              });
            },
          ),
          SizedBox(height: 2.h),
          Text(
            'Add Profile Photo (Optional)',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Full Name', style: AppTheme.lightTheme.textTheme.labelLarge),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _fullNameController,
          focusNode: _fullNameFocus,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            fillColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            suffixIcon: _fullNameValid
                ? CustomIconWidget(
                    iconName: 'check_circle',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  )
                : null,
          ),
          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Address', style: AppTheme.lightTheme.textTheme.labelLarge),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocus,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            fillColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            suffixIcon: _emailValid
                ? CustomIconWidget(
                    iconName: 'check_circle',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  )
                : null,
          ),
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        if (_emailController.text.isNotEmpty && !_emailValid)
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Text(
              'Please enter a valid email address',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: AppTheme.lightTheme.textTheme.labelLarge),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.next,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            fillColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_passwordValid)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  child: CustomIconWidget(
                    iconName: _isPasswordVisible
                        ? 'visibility_off'
                        : 'visibility',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 3.w),
              ],
            ),
          ),
          onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: AppTheme.lightTheme.textTheme.labelLarge,
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          textInputAction: TextInputAction.done,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            fillColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_confirmPasswordValid)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  child: CustomIconWidget(
                    iconName: _isConfirmPasswordVisible
                        ? 'visibility_off'
                        : 'visibility',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 3.w),
              ],
            ),
          ),
        ),
        if (_confirmPasswordController.text.isNotEmpty &&
            !_confirmPasswordValid)
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Text(
              'Passwords do not match',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: 2.w),
              child: RichText(
                text: TextSpan(
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _showTermsModal,
                        child: Text(
                          'Terms and Conditions',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _showTermsModal,
                        child: Text(
                          'Privacy Policy',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return Column(
      children: [
        // Validation status (for debugging)
        if (!_isFormValid)
          Container(
            padding: EdgeInsets.all(2.w),
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete all fields to enable signup:',
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildValidationItem('✓ Full name (2+ characters)', _fullNameValid),
                _buildValidationItem('✓ Valid email (from allowed list)', _emailValid),
                _buildValidationItem('✓ Password (8+ chars, A-Z, a-z, 0-9)', _passwordValid),
                _buildValidationItem('✓ Passwords match', _confirmPasswordValid),
                _buildValidationItem('✓ Accept terms & conditions', _acceptTerms),
              ],
            ),
          ),
        
        // Create Account Button
        SizedBox(
          width: double.infinity,
          height: 7.h,
          child: ElevatedButton(
            onPressed: _isFormValid && !_isLoading ? _createAccount : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
              foregroundColor: _isFormValid
                  ? AppTheme.lightTheme.colorScheme.onPrimary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: _isFormValid
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isValid ? 'check_circle' : 'cancel',
            size: 4.w,
            color: isValid
                ? AppTheme.lightTheme.colorScheme.secondary
                : AppTheme.lightTheme.colorScheme.error,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isValid
                    ? AppTheme.lightTheme.colorScheme.secondary
                    : AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.loginScreen),
        child: RichText(
          text: TextSpan(
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign In',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
