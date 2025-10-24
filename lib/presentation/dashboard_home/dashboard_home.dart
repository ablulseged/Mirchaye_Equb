import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/activity_item.dart';
import './widgets/empty_state_widget.dart';
import './widgets/quick_action_button.dart';
import './widgets/user_status_card.dart';
import './widgets/verification_badge.dart';
import '/presentation/groups_screen/groups_screen.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  late PageController _pageController;

  // Mock user data
  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "Abebe Kebede",
    "email": "abebe.kebede@wcu.edu.et",
    "university": "Wachemo University",
    "isVerified": true,
    "activeEqubOwnership": 1,
    "equbMemberships": 2,
    "maxEqubOwnership": 1,
    "maxEqubMemberships": 2,
  };

  // Mock Equb data
  final List<Map<String, dynamic>> userEqubs = [
    {
      "id": 1,
      "title": "Computer Science Students Equb",
      "type": "owner",
      "totalAmount": "50,000.00",
      "currentRound": 3,
      "totalRounds": 12,
      "nextPaymentDate": "2025-11-05",
      "memberCount": 12,
      "monthlyContribution": "4,166.67",
    },
    {
      "id": 2,
      "title": "Dormitory Block A Equb",
      "type": "member",
      "totalAmount": "24,000.00",
      "currentRound": 7,
      "totalRounds": 8,
      "nextPaymentDate": "2025-10-28",
      "memberCount": 8,
      "monthlyContribution": "3,000.00",
    },
  ];

  // Mock activity data
  final List<Map<String, dynamic>> recentActivities = [
    {
      "id": 1,
      "title": "Payment Received",
      "description": "Received 4,166.67 ETB from Almaz Tadesse",
      "time": "2 hours ago",
      "iconName": "payment",
      "iconColor": Color(0xFF2E7D32),
      "timestamp": DateTime.now().subtract(Duration(hours: 2)),
    },
    {
      "id": 2,
      "title": "Payment Due Reminder",
      "description": "Dormitory Block A Equb payment due in 3 days",
      "time": "5 hours ago",
      "iconName": "schedule",
      "iconColor": Color(0xFFF57C00),
      "timestamp": DateTime.now().subtract(Duration(hours: 5)),
    },
    {
      "id": 3,
      "title": "New Member Joined",
      "description": "Dawit Haile joined Computer Science Students Equb",
      "time": "1 day ago",
      "iconName": "person_add",
      "iconColor": Color(0xFF6F35A5),
      "timestamp": DateTime.now().subtract(Duration(days: 1)),
    },
    {
      "id": 4,
      "title": "Equb Round Completed",
      "description": "Round 2 completed for Computer Science Students Equb",
      "time": "3 days ago",
      "iconName": "check_circle",
      "iconColor": Color(0xFF2E7D32),
      "timestamp": DateTime.now().subtract(Duration(days: 3)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to different screens based on tab selection
    switch (index) {
      case 0:
        // Already on Home - no navigation needed
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.browseEqubGroups);
        break;
      case 2:
        _showNewPaymentDialog();
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.userProfile);
        break;
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, AppRoutes.userProfile);
  }

  void _navigateToCreateEqub() {
    Navigator.pushNamed(context, AppRoutes.createEqub);
  }

  void _navigateToJoinEqub() {
    Navigator.pushNamed(context, AppRoutes.browseEqubGroups);
  }

  void _navigateToPaymentHistory() {
    Navigator.pushNamed(context, AppRoutes.paymentProcessing);
  }

  void _navigateToEqubDetails(Map<String, dynamic> equb) {
    // Navigation logic would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${equb["title"]}'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    // Handle activity item tap
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activity: ${activity["title"]}'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _showNewPaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'New Payment',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Select an Equb group to make a payment.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, AppRoutes.paymentProcessing);
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEqubCards() {
    if (userEqubs.isEmpty) {
      return EmptyStateWidget(onCreateEqub: _navigateToCreateEqub);
    }

    return SizedBox(
      height: 20.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: userEqubs.length,
        itemBuilder: (context, index) {
          final equb = userEqubs[index];
          final progress =
              (equb["currentRound"] as int) / (equb["totalRounds"] as int);
          final isOwner = equb["type"] == "owner";

          return UserStatusCard(
            title: equb["title"] as String,
            subtitle: isOwner
                ? "You own this Equb • ${equb["memberCount"]} members"
                : "Member • Round ${equb["currentRound"]}/${equb["totalRounds"]}",
            amount: "${equb["totalAmount"]} ETB",
            progress: progress,
            progressColor: isOwner
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.getSuccessColor(true),
            onTap: () => _navigateToEqubDetails(equb),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  title: 'Create New Equb',
                  iconName: 'add_circle',
                  onTap: _navigateToCreateEqub,
                  isEnabled: true, // always enabled
                ),
              ),
              Expanded(
                child: QuickActionButton(
                  title: 'Browse Groups',
                  iconName: 'search',
                  onTap: _navigateToJoinEqub,
                  isEnabled: true,
                ),
              ),
              Expanded(
                child: QuickActionButton(
                  title: 'Payment History',
                  iconName: 'history',
                  onTap: _navigateToPaymentHistory,
                  isEnabled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentActivities.length,
            itemBuilder: (context, index) {
              final activity = recentActivities[index];
              return ActivityItem(
                title: activity["title"] as String,
                description: activity["description"] as String,
                time: activity["time"] as String,
                iconName: activity["iconName"] as String,
                iconColor: activity["iconColor"] as Color,
                onTap: () => _handleActivityTap(activity),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 10,
        titleSpacing: 3,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Circular logo placeholder
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: Icon(Icons.account_balance, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 10),

            // Title with custom font
            Expanded(
              child: Text(
                'Mirchaye Equb',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Roboto', // uses the family you defined
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications feature coming soon!'),
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                ),
              );
            },
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _navigateToProfile,
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              child: Text(
                userData["name"].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              _buildEqubCards(),
              SizedBox(height: 2.h),
              _buildQuickActions(),
              SizedBox(height: 2.h),
              _buildRecentActivity(),
              SizedBox(height: 10.h), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: userEqubs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.groupsScreen);
              },
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              child: Icon(
                Icons
                    .group, // <-- This changes the icon to the standard groups icon
                color: Colors.white,
                size: 24,
              ),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.unselectedItemColor,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _selectedIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'search',
              color: _selectedIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'payment',
              color: _selectedIndex == 2
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _selectedIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
