import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_export.dart';
import './widgets/activity_item.dart';
import './widgets/empty_state_widget.dart';
import './widgets/quick_action_button.dart';
import './widgets/user_status_card.dart';
import '../../l10n/app_localizations.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isRefreshing = false;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
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

  void _navigateToProfile() =>
      Navigator.pushNamed(context, AppRoutes.userProfile);
  void _navigateToCreateEqub() =>
      Navigator.pushNamed(context, AppRoutes.createEqub);
  void _navigateToJoinEqub() =>
      Navigator.pushNamed(context, AppRoutes.browseEqubGroups);
  void _navigateToPaymentHistory() =>
      Navigator.pushNamed(context, AppRoutes.paymentProcessing);

  void _navigateToEqubDetails(Map<String, dynamic> equb) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${equb["title"]}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activity: ${activity["title"]}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showNewPaymentDialog() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n?.payment ?? 'New Payment', style: theme.textTheme.titleLarge),
          content: Text(
            l10n?.selectPaymentMethod ?? 'Select an Equb group to make a payment.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Cancel', style: theme.textTheme.bodyMedium),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, AppRoutes.paymentProcessing);
              },
              child: Text(l10n?.continueButton ?? 'Continue', style: theme.textTheme.bodyMedium),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEqubCards(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (userEqubs.isEmpty)
      return EmptyStateWidget(onCreateEqub: _navigateToCreateEqub);

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
                ? "${l10n?.owner ?? 'Owner'} • ${equb["memberCount"]} ${l10n?.members ?? 'members'}"
                : "${l10n?.members ?? 'Member'} • ${l10n?.round ?? 'Round'} ${equb["currentRound"]}/${equb["totalRounds"]}",
            amount: "${equb["totalAmount"]} ${l10n?.etb ?? 'ETB'}",
            progress: progress,
            progressColor: isOwner
                ? theme.colorScheme.primary
                : AppTheme.getSuccessColorFromContext(context),
            onTap: () => _navigateToEqubDetails(equb),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.quickActions ?? 'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  title: l10n?.createNewEqub ?? 'Create New Equb',
                  iconName: 'add_circle',
                  onTap: _navigateToCreateEqub,
                  isEnabled: true,
                ),
              ),
              Expanded(
                child: QuickActionButton(
                  title: l10n?.browseGroups ?? 'Browse Groups',
                  iconName: 'search',
                  onTap: _navigateToJoinEqub,
                  isEnabled: true,
                ),
              ),
              Expanded(
                child: QuickActionButton(
                  title: l10n?.paymentHistory ?? 'Payment History',
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

  Widget _buildRecentActivity(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.recentActivity ?? 'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 10,
        titleSpacing: 3,
        title: Row(
          children: [
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
            Expanded(
              child: Text(
                l10n?.appTitle ?? 'Mirchaye Equb',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n?.notifications ?? 'Notifications coming soon!'),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _navigateToProfile,
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                userData["name"].toString()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                print('🚪 User manually logged out');
                await FirebaseAuth.instance.signOut();
                // AuthGate will automatically redirect to login screen
              }
            },
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.error,
              size: 24,
            ),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              _buildEqubCards(theme),
              SizedBox(height: 2.h),
              _buildQuickActions(theme),
              SizedBox(height: 2.h),
              _buildRecentActivity(theme),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      floatingActionButton: userEqubs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.groupsScreen),
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.group, color: Colors.white, size: 24),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _selectedIndex == 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: l10n?.home ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'search',
              color: _selectedIndex == 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: l10n?.browse ?? 'Browse',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'payment',
              color: _selectedIndex == 2
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: l10n?.payments ?? 'Payments',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _selectedIndex == 3
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: l10n?.profile ?? 'Profile',
          ),
        ],
      ),
    );
  }
}
