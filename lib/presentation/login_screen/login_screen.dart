import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_export.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_theme.dart';
import './widgets/app_logo_widget.dart';
import './widgets/biometric_auth_widget.dart';
import './widgets/login_form_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  void _checkBiometricAvailability() {
    // Check device support and user preference
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supported = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.getBiometricEnabled();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = supported && enabled;
        });
      }
    });
  }

  void _handleLogin(String email, String password) async {
    setState(() => _isLoading = true);

    try {
      // Use Firebase authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Check if email is verified
        if (!user.emailVerified) {
          // Sign out and show message
          await _auth.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Please verify your email before logging in. Check your inbox.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
          return;
        }

        // Provide success haptic feedback
        HapticFeedback.lightImpact();

        // AuthGate will handle navigation automatically
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password, please try again.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      _showErrorMessage(message);
    } catch (e) {
      _showErrorMessage(
        'Login failed. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleBiometricLogin() async {
    try {
      // Provide success haptic feedback
      HapticFeedback.lightImpact();

      // Navigate to dashboard only if there's an active Firebase session
      await Future.delayed(const Duration(milliseconds: 300));

      // If there's already a Firebase session, go ahead.
      final user = _auth.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
        return;
      }

      // Otherwise, try to retrieve locally stored credentials (kept only on device)
      final creds = await _biometricService.getStoredCredentials();
      if (creds != null) {
        try {
          final email = creds['email']!;
          final password = creds['password']!;
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password.trim(),
          );
          if (userCredential.user != null) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
            return;
          }
        } on FirebaseAuthException catch (e) {
          // If stored credentials are invalid (password changed) or wrong password,
          // clear them and show a concise message for wrong password.
          await _biometricService.clearStoredCredentials();
          if (mounted) {
            if (e.code == 'wrong-password') {
              _showErrorMessage('Incorrect password, please try again.');
            } else {
              _showErrorMessage(
                'Stored credentials are no longer valid. Please sign in manually.',
              );
            }
          }
          return;
        } catch (e) {
          if (mounted)
            _showErrorMessage(
              'Automatic sign-in failed. Please sign in manually.',
            );
          return;
        }
      }

      // No stored credentials available — ask the user to sign in with email/password.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No active session found and no device credentials are stored. Please sign in with email and password.',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Biometric authentication failed. Please try again.');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToSignup() {
    Navigator.pushNamed(context, AppRoutes.signupScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 8.h),

                // App Logo Section
                const AppLogoWidget(),

                SizedBox(height: 6.h),

                // Welcome Text
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 1.h),

                Text(
                  'Sign in to continue to your Equb account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 4.h),

                // Login Form
                LoginFormWidget(onLogin: _handleLogin, isLoading: _isLoading),

                // Biometric Authentication
                BiometricAuthWidget(
                  onBiometricLogin: _handleBiometricLogin,
                  isAvailable: _isBiometricAvailable,
                ),

                SizedBox(height: 6.h),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Equb? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToSignup,
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
