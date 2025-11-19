import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_export.dart';
import './widgets/activity_item.dart';
import './widgets/empty_state_widget.dart';
import './widgets/quick_action_button.dart';
import './widgets/user_status_card.dart';
import '../../l10n/app_localizations.dart';
import '../../services/equb_service.dart';
import '../../services/payment_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../services/messaging_service.dart' show showLocalNotification;

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
  final _notificationService = NotificationService();
  String? _lastNotificationId;

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
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setupNotificationListener() {
    // Listen for new notifications and show popup
    _notificationService.streamNotifications().listen((snapshot) {
      if (!mounted) return;

      final notifications = snapshot.docs;
      if (notifications.isEmpty) return;

      // Sort notifications by createdAt to get the most recent
      final sortedNotifications = List.from(notifications);
      sortedNotifications.sort((a, b) {
        final createdAtA = a.data()['createdAt'] as Timestamp?;
        final createdAtB = b.data()['createdAt'] as Timestamp?;
        if (createdAtA == null && createdAtB == null) return 0;
        if (createdAtA == null) return 1;
        if (createdAtB == null) return -1;
        return createdAtB.compareTo(createdAtA);
      });

      // Get the most recent notification
      final latestNotification = sortedNotifications.first;
      final latestId = latestNotification.id;

      // Only show popup if this is a new notification (different from last one)
      if (_lastNotificationId == null || _lastNotificationId != latestId) {
        _lastNotificationId = latestId;
        final data = latestNotification.data();
        final isRead = data['isRead'] as bool? ?? false;

        // Only show popup for unread notifications
        if (!isRead && mounted) {
          _showNotificationPopup(data);
        }
      }
    });
  }

  void _showNotificationPopup(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'New Notification';
    final message = data['message'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final showHeadsUp = data['showHeadsUp'] as bool? ?? false;

    // Show heads-up (overlay) notification only if flag is set
    // Payment notifications: only for group owner
    // Announcement notifications: for all members
    if (showHeadsUp) {
      try {
        showLocalNotification(title, message, {
          'type': type,
          'equbId': data['equbId'] as String? ?? '',
          'equbName': data['equbName'] as String? ?? '',
          ...?data['data'] as Map<String, dynamic>?,
        });
      } catch (e) {
        print('Error showing heads-up notification: $e');
      }
    }

    // Always show in-app SnackBar popup
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(fontSize: 14)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          action: SnackBarAction(
            label: 'View',
            textColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notificationsScreen);
            },
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                    final memberGroups = memberDocs
                        .map<Map<String, dynamic>>((doc) {
                          final data = doc.data();
                          return {
                            'id': doc.id,
                            'name': data['name'] ?? 'Untitled Equb',
                            'isSystemGenerated':
                                data['isSystemGenerated'] ?? false,
                            'isMirchayeGroup': data['isMirchayeGroup'] ?? false,
                            'ownerUid': data['ownerUid'] ?? '',
                          };
                        })
                        .where((group) {
                          // Filter out system-generated groups
                          final isSystem =
                              group['isSystemGenerated'] as bool? ?? false;
                          final isMirchaye =
                              group['isMirchayeGroup'] as bool? ?? false;
                          final ownerUid = group['ownerUid'] as String? ?? '';
                          return !isSystem &&
                              !isMirchaye &&
                              ownerUid != 'system';
                        })
                        .toList();

                    return StreamBuilder(
                      stream: EqubService().streamOwnedEqubsByCurrentUser(),
                      builder: (context, ownedSnap) {
                        final ownedDocs =
                            (ownedSnap.data as dynamic)?.docs ?? [];
                        final ownedGroups = ownedDocs
                            .map<Map<String, dynamic>>((doc) {
                              final data = doc.data();
                              return {
                                'id': doc.id,
                                'name': data['name'] ?? 'Untitled Equb',
                                'isSystemGenerated':
                                    data['isSystemGenerated'] ?? false,
                                'isMirchayeGroup':
                                    data['isMirchayeGroup'] ?? false,
                                'ownerUid': data['ownerUid'] ?? '',
                              };
                            })
                            .where((group) {
                              // Filter out system-generated groups
                              final isSystem =
                                  group['isSystemGenerated'] as bool? ?? false;
                              final isMirchaye =
                                  group['isMirchayeGroup'] as bool? ?? false;
                              final ownerUid =
                                  group['ownerUid'] as String? ?? '';
                              return !isSystem &&
                                  !isMirchaye &&
                                  ownerUid != 'system';
                            })
                            .toList();

                        final merged = <String, Map<String, dynamic>>{};
                        for (final g in [...memberGroups, ...ownedGroups]) {
                          merged[g['id'] as String] = g;
                        }
                        final groups = merged.values.toList();

                        if ((memberSnap.connectionState ==
                                ConnectionState.waiting) ||
                            (ownedSnap.connectionState ==
                                ConnectionState.waiting)) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (groups.isEmpty) {
                          // Fallback to scan membership in case rules/fields differ
                          return StreamBuilder(
                            stream: EqubService().streamJoinedEqubsByScan(),
                            builder: (context, scanSnap) {
                              final scanDocs =
                                  (scanSnap.data as List<dynamic>?) ?? [];
                              final scanGroups = scanDocs
                                  .map<Map<String, dynamic>>((doc) {
                                    final data = doc.data();
                                    return {
                                      'id': doc.id,
                                      'name': data['name'] ?? 'Untitled Equb',
                                      'isSystemGenerated':
                                          data['isSystemGenerated'] ?? false,
                                      'isMirchayeGroup':
                                          data['isMirchayeGroup'] ?? false,
                                      'ownerUid': data['ownerUid'] ?? '',
                                    };
                                  })
                                  .where((group) {
                                    // Filter out system-generated groups
                                    final isSystem =
                                        group['isSystemGenerated'] as bool? ??
                                        false;
                                    final isMirchaye =
                                        group['isMirchayeGroup'] as bool? ??
                                        false;
                                    final ownerUid =
                                        group['ownerUid'] as String? ?? '';
                                    return !isSystem &&
                                        !isMirchaye &&
                                        ownerUid != 'system';
                                  })
                                  .toList();

                              if (scanSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                );
                              }

                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 320,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: scanGroups.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final g = scanGroups[index];
                                    return ListTile(
                                      title: Text(
                                        g['name']?.toString() ??
                                            'Untitled Equb',
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        selectedEqubId = g['id'] as String?;
                                        selectedEqubName = g['name']
                                            ?.toString();
                                        Navigator.of(dialogContext).pop();
                                        showDialog(
                                          context: rootContext,
                                          builder: (methodContext) {
                                            return AlertDialog(
                                              title: Text(
                                                'Select Payment Method',
                                                style:
                                                    theme.textTheme.titleLarge,
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        methodContext,
                                                      ).pop();
                                                      Navigator.pushNamed(
                                                        rootContext,
                                                        AppRoutes
                                                            .paymentProcessing,
                                                        arguments: {
                                                          'equbId':
                                                              selectedEqubId,
                                                          'equbName':
                                                              selectedEqubName,
                                                          'method': 'Chapa',
                                                          'chapaPublicKey':
                                                              PaymentService
                                                                  .chapaPublicKey,
                                                        },
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.payment,
                                                    ),
                                                    label: const Text('Chapa'),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        methodContext,
                                                      ).pop();
                                                      Navigator.pushNamed(
                                                        rootContext,
                                                        AppRoutes
                                                            .paymentProcessing,
                                                        arguments: {
                                                          'equbId':
                                                              selectedEqubId,
                                                          'equbName':
                                                              selectedEqubName,
                                                          'method':
                                                              'Screenshot',
                                                        },
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.image,
                                                    ),
                                                    label: const Text(
                                                      'Screenshot',
                                                    ),
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
                              l10n?.selectPaymentMethod ??
                                  'Select an Equb group to make a payment.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 320),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: groups.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final g = groups[index];
                                  return ListTile(
                                    title: Text(
                                      g['name']?.toString() ?? 'Untitled Equb',
                                    ),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(
                                                      methodContext,
                                                    ).pop();
                                                    Navigator.pushNamed(
                                                      rootContext,
                                                      AppRoutes
                                                          .paymentProcessing,
                                                      arguments: {
                                                        'equbId':
                                                            selectedEqubId,
                                                        'equbName':
                                                            selectedEqubName,
                                                        'method': 'Chapa',
                                                        'chapaPublicKey':
                                                            PaymentService
                                                                .chapaPublicKey,
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.payment,
                                                  ),
                                                  label: const Text('Chapa'),
                                                ),
                                                const SizedBox(height: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(
                                                      methodContext,
                                                    ).pop();
                                                    Navigator.pushNamed(
                                                      rootContext,
                                                      AppRoutes
                                                          .paymentProcessing,
                                                      arguments: {
                                                        'equbId':
                                                            selectedEqubId,
                                                        'equbName':
                                                            selectedEqubName,
                                                        'method': 'Screenshot',
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(Icons.image),
                                                  label: const Text(
                                                    'Screenshot',
                                                  ),
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
                                          'chapaPublicKey':
                                              PaymentService.chapaPublicKey,
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
        final owned = ownedDocs
            .map<Map<String, dynamic>>((doc) {
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
                'isSystemGenerated': d['isSystemGenerated'] ?? false,
                'isMirchayeGroup': d['isMirchayeGroup'] ?? false,
                'ownerUid': d['ownerUid'] ?? '',
              };
            })
            .where((group) {
              // Filter out system-generated groups
              final isSystem = group['isSystemGenerated'] as bool? ?? false;
              final isMirchaye = group['isMirchayeGroup'] as bool? ?? false;
              final ownerUid = group['ownerUid'] as String? ?? '';
              return !isSystem && !isMirchaye && ownerUid != 'system';
            })
            .toList();

        return StreamBuilder(
          stream: equbService.streamEqubsWhereMember(),
          builder: (context, memberSnap) {
            final memberDocs = (memberSnap.data as dynamic)?.docs ?? [];
            final joined = memberDocs
                .map<Map<String, dynamic>>((doc) {
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
                    'isSystemGenerated': d['isSystemGenerated'] ?? false,
                    'isMirchayeGroup': d['isMirchayeGroup'] ?? false,
                    'ownerUid': d['ownerUid'] ?? '',
                  };
                })
                .where((group) {
                  // Filter out system-generated groups
                  final isSystem = group['isSystemGenerated'] as bool? ?? false;
                  final isMirchaye = group['isMirchayeGroup'] as bool? ?? false;
                  final ownerUid = group['ownerUid'] as String? ?? '';
                  return !isSystem && !isMirchaye && ownerUid != 'system';
                })
                .toList();

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
                  final progress = max > 0
                      ? (current / max).clamp(0.0, 1.0)
                      : 0.0;
                  final isOwner = (g['isOwner'] as bool?) ?? false;

                  return UserStatusCard(
                    title: g['name']?.toString() ?? 'Untitled Equb',
                    subtitle: isOwner
                        ? "${l10n?.owner ?? 'Owner'} • ${current}/${max} ${l10n?.members ?? 'members'}"
                        : "${l10n?.members ?? 'Member'} • ${current}/${max} ${l10n?.members ?? 'members'}",
                    amount:
                        ((g['contributionAmount'] as double?) ?? 0.0)
                            .toStringAsFixed(2) +
                        ' ' +
                        (l10n?.etb ?? 'ETB'),
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

  Widget _buildSavedAndFavoritesSection(ThemeData theme) {
    final userService = UserService();
    final equbService = EqubService();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved & Favorites',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          // Tabs: Saved / Favorites
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurface,
                  tabs: const [
                    Tab(text: 'Saved'),
                    Tab(text: 'Favorite'),
                  ],
                ),
                SizedBox(
                  height: 18.h,
                  child: TabBarView(
                    children: [
                      // Saved tab
                      StreamBuilder<List<String>>(
                        stream: userService.streamSavedEqubIds(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final ids = snap.data ?? [];
                          if (ids.isEmpty) {
                            return Center(
                              child: Text(
                                'No saved equbs',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.all(3.w),
                            itemBuilder: (context, index) {
                              final id = ids[index];
                              return StreamBuilder(
                                stream: equbService.streamEqub(id),
                                builder: (context, equbSnap) {
                                  if (!equbSnap.hasData)
                                    return SizedBox(
                                      width: 40.w,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  final data =
                                      (equbSnap.data as dynamic).data()
                                          as Map<String, dynamic>?;
                                  final name = data?['name'] ?? 'Untitled';
                                  final avatar =
                                      data?['coverImageUrl'] ??
                                      data?['ownerPhotoUrl'] ??
                                      'https://i.pravatar.cc/100?u=$id';
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.groupManagement,
                                        arguments: {
                                          'equbId': id,
                                          'isOwner': false,
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: 40.w,
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(
                                              avatar,
                                            ),
                                          ),
                                          SizedBox(height: 1.h),
                                          Text(
                                            name.toString(),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            separatorBuilder: (_, __) => SizedBox(width: 2.w),
                            itemCount: ids.length,
                          );
                        },
                      ),
                      // Favorites tab
                      StreamBuilder<List<String>>(
                        stream: userService.streamFavoriteEqubIds(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final ids = snap.data ?? [];
                          if (ids.isEmpty) {
                            return Center(
                              child: Text(
                                'No favorite equbs',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.all(3.w),
                            itemBuilder: (context, index) {
                              final id = ids[index];
                              return StreamBuilder(
                                stream: equbService.streamEqub(id),
                                builder: (context, equbSnap) {
                                  if (!equbSnap.hasData)
                                    return SizedBox(
                                      width: 40.w,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  final data =
                                      (equbSnap.data as dynamic).data()
                                          as Map<String, dynamic>?;
                                  final name = data?['name'] ?? 'Untitled';
                                  final avatar =
                                      data?['coverImageUrl'] ??
                                      data?['ownerPhotoUrl'] ??
                                      'https://i.pravatar.cc/100?u=$id';
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.groupManagement,
                                        arguments: {
                                          'equbId': id,
                                          'isOwner': false,
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: 40.w,
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(
                                              avatar,
                                            ),
                                          ),
                                          SizedBox(height: 1.h),
                                          Text(
                                            name.toString(),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            separatorBuilder: (_, __) => SizedBox(width: 2.w),
                            itemCount: ids.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final equbService = EqubService();

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
          // Get all user's groups
          StreamBuilder(
            stream: equbService.streamOwnedEqubsByCurrentUser(),
            builder: (context, ownedSnap) {
              return StreamBuilder(
                stream: equbService.streamEqubsWhereMember(),
                builder: (context, memberSnap) {
                  // Combine both streams to get all groups
                  if (ownedSnap.connectionState == ConnectionState.waiting ||
                      memberSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ownedDocs = ownedSnap.data?.docs ?? [];
                  final memberDocs = memberSnap.data?.docs ?? [];

                  // Filter out system-generated groups
                  final allGroups = [...ownedDocs, ...memberDocs].where((doc) {
                    final data = doc.data();
                    final isSystem = data['isSystemGenerated'] ?? false;
                    final isMirchaye = data['isMirchayeGroup'] ?? false;
                    final ownerUid = data['ownerUid'] ?? '';
                    return !isSystem && !isMirchaye && ownerUid != 'system';
                  }).toList();

                  if (allGroups.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          CustomIconWidget(
                            iconName: 'notifications_none',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'No recent activity',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final equbIds = allGroups.map((d) => d.id).toList();

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: equbService.streamAllGroupAnnouncements(equbIds),
                    builder: (context, announcementsSnap) {
                      if (announcementsSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final announcements = announcementsSnap.data ?? [];

                      // Limit to 5 most recent
                      final displayAnnouncements = announcements
                          .take(5)
                          .toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayAnnouncements.length,
                        itemBuilder: (context, index) {
                          final announcement = displayAnnouncements[index];
                          return ActivityItem(
                            title: announcement['title'] as String,
                            description: announcement['description'] as String,
                            time: announcement['time'] as String,
                            iconName: announcement['iconName'] as String,
                            iconColor: announcement['iconColor'] as Color,
                            onTap: () {
                              if (announcement['equbId'] != null) {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.groupManagement,
                                  arguments: {
                                    'equbId': announcement['equbId'],
                                    'isOwner': false,
                                  },
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
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
              StreamBuilder<int>(
                stream: NotificationService().streamUnreadCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.notificationsScreen,
                          );
                        },
                        icon: CustomIconWidget(
                          iconName: 'notifications',
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                onPressed: _navigateToProfile,
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
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
                  _buildSavedAndFavoritesSection(theme),
                  SizedBox(height: 2.h),
                  _buildRecentActivity(theme),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.groupsScreen),
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.group, color: Colors.white, size: 24),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onBottomNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
            selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
            unselectedItemColor:
                theme.bottomNavigationBarTheme.unselectedItemColor,
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
