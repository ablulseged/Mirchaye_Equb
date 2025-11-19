import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _allowedEmails = [];

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Load allowed emails from JSON file
  Future<void> loadAllowedEmails() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/allowed_emails.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _allowedEmails = List<String>.from(jsonData['allowed_emails']);

      // Convert all to lowercase for case-insensitive comparison
      _allowedEmails = _allowedEmails.map((e) => e.toLowerCase()).toList();

      print('✅ Loaded ${_allowedEmails.length} allowed emails for signup');
    } catch (e) {
      print('❌ Error loading allowed emails: $e');
      _allowedEmails = [];
    }
  }

  // Check if email is in allowed list
  bool isEmailAllowed(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    return _allowedEmails.contains(normalizedEmail);
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if email is in allowed list
      if (!isEmailAllowed(email)) {
        return {
          'success': false,
          'message': 'You are not allowed to sign up. Please contact admin.',
        };
      }

      // Create user with Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Send email verification (like reference code)
      await userCredential.user!.sendEmailVerification();

      // Sign out immediately after signup (user must verify email first)
      await _auth.signOut();

      return {
        'success': true,
        'message':
            'Verification email sent! Please check your inbox and verify your email before logging in.',
        'needsVerification': true,
      };
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'An error occurred during signup';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        return {
          'success': false,
          'message':
              'Please verify your email address. Check your inbox for the verification link.',
          'needsVerification': true,
          'user': userCredential.user,
        };
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during login';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect password, please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please try again later.';
          break;
        default:
          message = e.message ?? message;
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Send password reset email
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      return {
        'success': true,
        'message':
            'Password reset link sent! Check your email to reset your password.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = e.message ?? message;
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Resend email verification
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in.'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email is already verified.'};
      }

      // Send verification with Firebase default handler
      await user.sendEmailVerification();

      return {
        'success': true,
        'message': 'Verification email sent! Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Failed to send verification email.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reload user data
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Check if user's email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }
}
