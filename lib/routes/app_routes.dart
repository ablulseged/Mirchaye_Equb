import 'package:flutter/material.dart';
import '../presentation/dashboard_home/dashboard_home.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/browse_equb_groups/browse_equb_groups.dart';
import '../presentation/payment_processing/payment_processing.dart';
import '../presentation/create_group_screen/create_group_screen.dart';
import '../presentation/groups_screen/groups_screen.dart';

class AppRoutes {
  // Route names
  static const String initial = '/';
  static const String dashboardHome = '/dashboard-home';
  static const String userProfile = '/user-profile';
  static const String browseEqubGroups = '/browse-equb-groups';
  static const String paymentProcessing = '/payment-processing';
  static const String createEqub = '/create-equb';
  static const String groupsScreen = '/groups-screen';

  // Route map
  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const DashboardHome(),
    dashboardHome: (context) => const DashboardHome(),
    userProfile: (context) => const UserProfile(),
    browseEqubGroups: (context) => const BrowseEqubGroups(),
    paymentProcessing: (context) => const PaymentProcessing(),
    createEqub: (context) => const CreateGroupScreen(),
    groupsScreen: (context) => const GroupsScreen(), // Use const
  };
}
