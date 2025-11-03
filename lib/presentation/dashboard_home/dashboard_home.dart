import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_export.dart';
import './widgets/activity_item.dart';
import './widgets/empty_state_widget.dart';
import './widgets/quick_action_button.dart';
import './widgets/user_status_card.dart';
import '../../l10n/app_localizations.dart';
import '../../services/equb_service.dart';
import '../../services/payment_service.dart';
import '../../services/user_service.dart';

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
  final _userService = UserService();

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
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
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
      Navigator.pushNamed(context, AppRoutes.paymentHistory);

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
    final rootContext = context;
    String? selectedEqubId;
    String? selectedEqubName;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                l10n?.payment ?? 'New Payment',
                style: theme.textTheme.titleLarge,
              ),
              content: SizedBox(
                width: 400,
                child: StreamBuilder(
                  stream: EqubService().streamEqubsWhereMember(),
                  builder: (context, memberSnap) {
                    final memberDocs = (memberSnap.data as dynamic)?.docs ?? [];
                    final memberGroups = memberDocs.map<Map<String, dynamic>>((doc) {
                      final data = doc.data();
                      return {
                        'id': doc.id,
                        'name': data['name'] ?? 'Untitled Equb',
                      };
                    }).toList();

                    return StreamBuilder(
                      stream: EqubService().streamOwnedEqubsByCurrentUser(),
                      builder: (context, ownedSnap) {
                        final ownedDocs = (ownedSnap.data as dynamic)?.docs ?? [];
                        final ownedGroups = ownedDocs.map<Map<String, dynamic>>((doc) {
                          final data = doc.data();
                          return {
                            'id': doc.id,
                            'name': data['name'] ?? 'Untitled Equb',
                          };
                        }).toList();

                        final merged = <String, Map<String, dynamic>>{};
                        for (final g in [...memberGroups, ...ownedGroups]) {
                          merged[g['id'] as String] = g;
                        }
                        final groups = merged.values.toList();

                        if ((memberSnap.connectionState == ConnectionState.waiting) ||
                            (ownedSnap.connectionState == ConnectionState.waiting)) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (groups.isEmpty) {
                          // Fallback to scan membership in case rules/fields differ
                          return StreamBuilder(
                            stream: EqubService().streamJoinedEqubsByScan(),
                            builder: (context, scanSnap) {
                              final scanDocs = (scanSnap.data as List<dynamic>?) ?? [];
                              final scanGroups = scanDocs.map<Map<String, dynamic>>((doc) {
                                final data = doc.data();
                                return {
                                  'id': doc.id,
                                  'name': data['name'] ?? 'Untitled Equb',
                                };
                              }).toList();

                              if (scanSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (scanGroups.isEmpty) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You have no joined groups yet.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Browse and join a group first to make a payment.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 320),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: scanGroups.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final g = scanGroups[index];
                                    return ListTile(
                                      title: Text(g['name']?.toString() ?? 'Untitled Equb'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        selectedEqubId = g['id'] as String?;
                                        selectedEqubName = g['name']?.toString();
                                        Navigator.of(dialogContext).pop();
                                        showDialog(
                                          context: rootContext,
                                          builder: (methodContext) {
        return AlertDialog(
                                              title: Text(
                                                'Select Payment Method',
                                                style: theme.textTheme.titleLarge,
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      Navigator.of(methodContext).pop();
                                                      Navigator.pushNamed(
                                                        rootContext,
                                                        AppRoutes.paymentProcessing,
                                                        arguments: {
                                                          'equbId': selectedEqubId,
                                                          'equbName': selectedEqubName,
                                                          'method': 'Chapa',
                                                          'chapaPublicKey': PaymentService.chapaPublicKey,
                                                        },
                                                      );
                                                    },
                                                    icon: const Icon(Icons.payment),
                                                    label: const Text('Chapa'),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      Navigator.of(methodContext).pop();
                                                      Navigator.pushNamed(
                                                        rootContext,
                                                        AppRoutes.paymentProcessing,
                                                        arguments: {
                                                          'equbId': selectedEqubId,
                                                          'equbName': selectedEqubName,
                                                          'method': 'Screenshot',
                                                        },
                                                      );
                                                    },
                                                    icon: const Icon(Icons.image),
                                                    label: const Text('Screenshot'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
            l10n?.selectPaymentMethod ?? 'Select an Equb group to make a payment.',
            style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 320),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: groups.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final g = groups[index];
                                  return ListTile(
                                    title: Text(g['name']?.toString() ?? 'Untitled Equb'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      selectedEqubId = g['id'] as String?;
                                      selectedEqubName = g['name']?.toString();
                                      Navigator.of(dialogContext).pop();
                                      showDialog(
                                        context: rootContext,
                                        builder: (methodContext) {
                                          return AlertDialog(
                                            title: Text(
                                              'Select Payment Method',
                                              style: theme.textTheme.titleLarge,
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(methodContext).pop();
                                                    Navigator.pushNamed(
                                                      rootContext,
                                                      AppRoutes.paymentProcessing,
                                                      arguments: {
                                                        'equbId': selectedEqubId,
                                                        'equbName': selectedEqubName,
                                                        'method': 'Chapa',
                                                        'chapaPublicKey': PaymentService.chapaPublicKey,
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(Icons.payment),
                                                  label: const Text('Chapa'),
                                                ),
                                                const SizedBox(height: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(methodContext).pop();
                                                    Navigator.pushNamed(
                                                      rootContext,
                                                      AppRoutes.paymentProcessing,
                                                      arguments: {
                                                        'equbId': selectedEqubId,
                                                        'equbName': selectedEqubName,
                                                        'method': 'Screenshot',
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(Icons.image),
                                                  label: const Text('Screenshot'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        if (selectedEqubId == null) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: const Text('Please select a group'),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                          return;
                        }
                        Navigator.of(dialogContext).pop();

                        // Next: choose payment method (Chapa or Screenshot)
                        showDialog(
                          context: rootContext,
                          builder: (methodContext) {
                            return AlertDialog(
                              title: Text(
                                'Select Payment Method',
                                style: theme.textTheme.titleLarge,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(methodContext).pop();
                                      Navigator.pushNamed(
                                        rootContext,
                                        AppRoutes.paymentProcessing,
                                        arguments: {
                                          'equbId': selectedEqubId,
                                          'equbName': selectedEqubName,
                                          'method': 'Chapa',
                                          'chapaPublicKey': PaymentService.chapaPublicKey,
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Chapa'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
              onPressed: () {
                                      Navigator.of(methodContext).pop();
                                      Navigator.pushNamed(
                                        rootContext,
                                        AppRoutes.paymentProcessing,
                                        arguments: {
                                          'equbId': selectedEqubId,
                                          'equbName': selectedEqubName,
                                          'method': 'Screenshot',
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.image),
                                    label: const Text('Screenshot'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Text(
                        l10n?.continueButton ?? 'Continue',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEqubCards(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final equbService = EqubService();

    return StreamBuilder(
      stream: equbService.streamOwnedEqubsByCurrentUser(),
      builder: (context, ownedSnap) {
        final ownedDocs = (ownedSnap.data as dynamic)?.docs ?? [];
        final owned = ownedDocs.map<Map<String, dynamic>>((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'name': d['name'] ?? 'Untitled Equb',
            'contributionAmount': (d['contributionAmount'] is num)
                ? (d['contributionAmount'] as num).toDouble()
                : 0.0,
            'currentMembers': d['currentMembers'] ?? 0,
            'maxMembers': d['maxMembers'] ?? 0,
            'isOwner': true,
          };
        }).toList();

        return StreamBuilder(
          stream: equbService.streamEqubsWhereMember(),
          builder: (context, memberSnap) {
            final memberDocs = (memberSnap.data as dynamic)?.docs ?? [];
            final joined = memberDocs.map<Map<String, dynamic>>((doc) {
              final d = doc.data();
              return {
                'id': doc.id,
                'name': d['name'] ?? 'Untitled Equb',
                'contributionAmount': (d['contributionAmount'] is num)
                    ? (d['contributionAmount'] as num).toDouble()
                    : 0.0,
                'currentMembers': d['currentMembers'] ?? 0,
                'maxMembers': d['maxMembers'] ?? 0,
                'isOwner': false,
              };
            }).toList();

            if (ownedSnap.connectionState == ConnectionState.waiting ||
                memberSnap.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 20.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final merged = <String, Map<String, dynamic>>{};
            for (final g in [...owned, ...joined]) {
              merged[g['id'] as String] = g;
            }
            final groups = merged.values.toList();

            if (groups.isEmpty) {
              return EmptyStateWidget(onCreateEqub: _navigateToCreateEqub);
            }

            return SizedBox(
              height: 20.h,
              child: PageView.builder(
                controller: _pageController,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];
                  final current = (g['currentMembers'] as int?) ?? 0;
                  final max = (g['maxMembers'] as int?) ?? 0;
                  final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
                  final isOwner = (g['isOwner'] as bool?) ?? false;

                  return UserStatusCard(
                    title: g['name']?.toString() ?? 'Untitled Equb',
                    subtitle: isOwner
                        ? "${l10n?.owner ?? 'Owner'} • ${current}/${max} ${l10n?.members ?? 'members'}"
                        : "${l10n?.members ?? 'Member'} • ${current}/${max} ${l10n?.members ?? 'members'}",
                    amount: ((g['contributionAmount'] as double?) ?? 0.0).toStringAsFixed(2) + ' ' + (l10n?.etb ?? 'ETB'),
                    progress: progress,
                    progressColor: isOwner
                        ? theme.colorScheme.primary
                        : AppTheme.getSuccessColorFromContext(context),
                    onTap: () => _navigateToEqubDetails(g),
                  );
                },
              ),
            );
          },
        );
      },
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

    return StreamBuilder(
      stream: _userService.streamCurrentUser(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data != null) {
          final docData = snapshot.data!.data();
          if (docData != null) {
            photoUrl = docData['photoUrl'];
          }
        }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 10,
        titleSpacing: 3,
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.onSurface,
              size: 32,
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
              backgroundImage: photoUrl != null 
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null 
                  ? Text(
                      userData["name"].toString()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.groupsScreen),
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.group, color: Colors.white, size: 24),
      ),
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
      },
    );
  }
}
