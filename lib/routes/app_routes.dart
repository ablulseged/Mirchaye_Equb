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
import '../presentation/group_management/group_management_screen.dart';
import '../presentation/announcements_screen/announcements_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../widgets/auth_gate.dart';
import '../spin/spin_wheel_screen.dart';
import '../presentation/payment_history/payment_history.dart';

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
  static const String groupManagement = '/group-management';
  static const String announcementsScreen = '/announcements-screen';
  static const String notificationsScreen = '/notifications-screen';
  static const String spinWheel = '/spin-wheel';
  static const String paymentHistory = '/payment-history';

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
    userProfile: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return UserProfile(userId: args?['userId'] as String?);
    },
    browseEqubGroups: (context) => const BrowseEqubGroups(),
    paymentProcessing: (context) => const PaymentProcessing(),
    createEqub: (context) => const CreateGroupScreen(),
    groupsScreen: (context) => const GroupsScreen(),
    groupManagement: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return GroupManagementScreen(
        equbId: args['equbId'] as String,
        isOwnerForced: args['isOwner'] as bool?,
      );
    },
    announcementsScreen: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return AnnouncementsScreen(equbId: args['equbId'] as String);
    },
    notificationsScreen: (context) => const NotificationsScreen(),
    spinWheel: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return SpinWheelScreen(equbId: args['equbId'] as String);
    },
    paymentHistory: (context) => const PaymentHistoryScreen(),
  };
}
