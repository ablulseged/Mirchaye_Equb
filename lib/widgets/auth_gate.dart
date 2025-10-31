import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/verify_email_screen/verify_email_screen.dart';
import '../presentation/dashboard_home/dashboard_home.dart';

/// AuthGate - Handles authentication state and routing
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // User is authenticated
        if (snapshot.hasData) {
          final user = snapshot.data!;
          print('👤 User authenticated: ${user.email} (verified: ${user.emailVerified})');
          
          if (user.emailVerified) {
            return const DashboardHome();
          } else {
            return const VerifyEmailScreen();
          }
        }
        
        // No user - show login
        print('🚪 No authenticated user, showing login screen');
        return const LoginScreen();
      },
    );
  }
}

