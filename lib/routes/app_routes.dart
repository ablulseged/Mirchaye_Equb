import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/signup_screen/signup_screen.dart';
import '../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../presentation/verify_email_screen/verify_email_screen.dart';
import '../presentation/dashboard_home/dashboard_home.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/browse_equb_groups/browse_equb_groups.dart';
import '../presentation/payment_processing/payment_processing.dart';
import '../presentation/create_group_screen/create_group_screen.dart';
import '../presentation/groups_screen/groups_screen.dart';
import '../widgets/auth_gate.dart';

class AppRoutes {
  // Route names
  static const String initial = '/';
  static const String loginScreen = '/login-screen';
  static const String signupScreen = '/signup-screen';
  static const String forgotPasswordScreen = '/forgot-password-screen';
  static const String verifyEmailScreen = '/verify-email-screen';
  static const String dashboardHome = '/dashboard-home';
  static const String userProfile = '/user-profile';
  static const String browseEqubGroups = '/browse-equb-groups';
  static const String paymentProcessing = '/payment-processing';
  static const String createEqub = '/create-equb';
  static const String groupsScreen = '/groups-screen';

  // Route map
  static Map<String, WidgetBuilder> routes = {
    // 🔹 App starts with AuthGate to handle auth state
    initial: (context) => const AuthGate(),

    // 🔹 Authentication Screens
    loginScreen: (context) => const LoginScreen(),
    signupScreen: (context) => const SignupScreen(),
    forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
    verifyEmailScreen: (context) => const VerifyEmailScreen(),

    // 🔹 Main Screens (Accessible only after login)
    dashboardHome: (context) => const DashboardHome(),
    userProfile: (context) => const UserProfile(),
    browseEqubGroups: (context) => const BrowseEqubGroups(),
    paymentProcessing: (context) => const PaymentProcessing(),
    createEqub: (context) => const CreateGroupScreen(),
    groupsScreen: (context) => const GroupsScreen(),
  };
}
