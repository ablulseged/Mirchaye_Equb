import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/group_card_widget.dart';
import './widgets/group_creation_modal.dart';
import './widgets/search_bar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/equb_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearchExpanded = false;
  String _searchQuery = '';

  // My Equbs - now populated from Firestore
  final List<Map<String, dynamic>> _myEqubs = [];

  // Joined Equbs - now populated from Firestore
  final List<Map<String, dynamic>> _joinedEqubs = [];

  final List<Map<String, dynamic>> _systemGroups = [
    {
      'id': '7',
      'name': 'Auto-Generated Group #247',
      'description':
          'System created group when member limit reached in popular category',
      'amount': 4000.0,
      'maxMembers': 10,
      'currentMembers': 10,
      'status': 'Active',
      'frequency': 'Monthly',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      'isOwner': false,
      'isSystemGenerated': true,
    },
    {
      'id': '8',
      'name': 'Auto-Generated Group #248',
      'description':
          'Automatically created for overflow members from high-demand groups',
      'amount': 6000.0,
      'maxMembers': 12,
      'currentMembers': 7,
      'status': 'Active',
      'frequency': 'Monthly',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'isOwner': false,
      'isSystemGenerated': true,
    },
  ];

  // Constants for maximum limits
  static const int MAX_MY_EQUBS = 1;
  static const int MAX_JOINED_EQUBS = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredGroups(
    List<Map<String, dynamic>> groups,
  ) {
    if (_searchQuery.isEmpty) return groups;

    return groups.where((group) {
      final name = (group['name'] as String).toLowerCase();
      final description = (group['description'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || description.contains(query);
    }).toList();
  }

  bool get _canCreateNewGroup => true; // compute from stream in UI if needed
  bool get _canJoinNewGroup => true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              isExpanded: _isSearchExpanded,
              onToggle: () {
                setState(() {
                  _isSearchExpanded = !_isSearchExpanded;
                  if (!_isSearchExpanded) {
                    _searchQuery = '';
                  }
                });
              },
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'My Equb'),
                  Tab(text: 'Joined'),
                  Tab(text: 'System'),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyEqubsTab(),
                  _buildJoinedEqubsTab(),
                  _buildSystemGroupsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildMyEqubsTab() {
    final theme = Theme.of(context);
    final equbService = EqubService();

    return StreamBuilder(
      stream: equbService.streamOwnedEqubsByCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final groups = docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Untitled Equb',
            'description': data['description'] ?? '',
            'amount': (data['contributionAmount'] is num)
                ? (data['contributionAmount'] as num).toDouble()
                : 0.0,
            'maxMembers': data['maxMembers'] ?? 0,
            'currentMembers': data['currentMembers'] ?? 0,
            'status': 'Active',
            'frequency': data['paymentFrequency'] ?? 'Monthly',
            'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
            'isOwner': true,
            'owner': data['ownerEmail'] ?? '',
          };
        }).toList();

        final filteredGroups = _getFilteredGroups(groups);

        if (filteredGroups.isEmpty) {
          return EmptyStateWidget(
            title: 'Create Your Equb',
            description:
                'You can create one Equb group to start building your savings community. Invite friends and family to join your financial journey.',
            buttonText: 'Create New Equb',
            iconName: 'group_add',
            onButtonPressed: _showGroupCreationModal,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 10.h),
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            return GroupCardWidget(
              groupData: filteredGroups[index],
              groupType: 'my_equbs',
              onTap: () => _showGroupDetails(filteredGroups[index]),
              onLongPress: () => _showGroupOptions(filteredGroups[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildJoinedEqubsTab() {
    final equbService = EqubService();
    return StreamBuilder(
      stream: equbService.streamEqubsWhereMember(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final primaryGroups = docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Untitled Equb',
            'description': data['description'] ?? '',
            'amount': (data['contributionAmount'] is num)
                ? (data['contributionAmount'] as num).toDouble()
                : 0.0,
            'maxMembers': data['maxMembers'] ?? 0,
            'currentMembers': data['currentMembers'] ?? 0,
            'status': 'Active',
            'frequency': data['paymentFrequency'] ?? 'Monthly',
            'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
            'isOwner': (data['ownerUid'] == FirebaseAuth.instance.currentUser?.uid),
            'owner': data['ownerEmail'] ?? '',
          };
        }).toList();

        // If primary query returns results, show them
        if (primaryGroups.isNotEmpty) {
          final filteredGroups = _getFilteredGroups(primaryGroups);
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 10.h),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              return GroupCardWidget(
                groupData: filteredGroups[index],
                groupType: 'joined_equbs',
                onTap: () => _showGroupDetails(filteredGroups[index]),
                onLongPress: () => _showGroupOptions(filteredGroups[index]),
              );
            },
          );
        }

        // Fallback: scan equbs and check membership via members/{uid}
        return StreamBuilder(
          stream: equbService.streamJoinedEqubsByScan(),
          builder: (context, fallbackSnap) {
            if (fallbackSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs2 = fallbackSnap.data?.toList() ?? [];
            final groups = docs2.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Untitled Equb',
                'description': data['description'] ?? '',
                'amount': (data['contributionAmount'] is num)
                    ? (data['contributionAmount'] as num).toDouble()
                    : 0.0,
                'maxMembers': data['maxMembers'] ?? 0,
                'currentMembers': data['currentMembers'] ?? 0,
                'status': 'Active',
                'frequency': data['paymentFrequency'] ?? 'Monthly',
                'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
                'isOwner': (data['ownerUid'] == FirebaseAuth.instance.currentUser?.uid),
                'owner': data['ownerEmail'] ?? '',
              };
            }).toList();

            final filteredGroups = _getFilteredGroups(groups);

            if (filteredGroups.isEmpty) {
              return EmptyStateWidget(
                title: 'No Joined Groups',
                description:
                    'You haven\'t joined any groups yet or your requests are pending approval.',
                buttonText: 'Browse Groups',
                iconName: 'group',
                onButtonPressed: () {},
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(bottom: 10.h),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                return GroupCardWidget(
                  groupData: filteredGroups[index],
                  groupType: 'joined_equbs',
                  onTap: () => _showGroupDetails(filteredGroups[index]),
                  onLongPress: () => _showGroupOptions(filteredGroups[index]),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSystemGroupsTab() {
    final theme = Theme.of(context);
    final filteredGroups = _getFilteredGroups(_systemGroups);

    if (filteredGroups.isEmpty && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        title: 'No System Groups',
        description:
            'System-generated groups will appear here when member limits are reached in popular categories.',
        buttonText: 'Refresh',
        iconName: 'autorenew',
        onButtonPressed: () {
          setState(() {});
        },
      );
    }

    if (filteredGroups.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        title: 'No Groups Found',
        description:
            'No groups match your search criteria. Try adjusting your search terms.',
        buttonText: 'Clear Search',
        iconName: 'search_off',
        onButtonPressed: () {
          setState(() {
            _searchQuery = '';
            _isSearchExpanded = false;
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 10.h),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          return GroupCardWidget(
            groupData: filteredGroups[index],
            groupType: 'system_groups',
            onTap: () => _showGroupDetails(filteredGroups[index]),
            onLongPress: () => _showGroupOptions(filteredGroups[index]),
          );
        },
      ),
    );
  }

  void _showGroupCreationModal() {
    if (!_canCreateNewGroup) {
      _showLimitReachedDialog('create');
      return;
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupCreationModal(
        onGroupCreated: (groupData) {
          if (_myEqubs.length < MAX_MY_EQUBS) {
            setState(() {
              _myEqubs.insert(0, groupData);
            });
          }
        },
      ),
    );
  }

  void _showLimitReachedDialog(String action) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: theme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Limit Reached',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text(
          action == 'create'
              ? 'You can only create one Equb group. To create a new group, you must delete your existing group first.'
              : 'You can only join up to $MAX_JOINED_EQUBS groups. To join a new group, you must leave one of your current groups first.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Understand',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(Map<String, dynamic> groupData) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          groupData['name'] as String,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((groupData['description'] as String).isNotEmpty) ...[
                Text(
                  groupData['description'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
              ],
              _buildDetailRow(
                'Amount',
                'ETB ${(groupData['amount'] as double).toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Members',
                '${groupData['currentMembers']}/${groupData['maxMembers']}',
              ),
              _buildDetailRow('Status', groupData['status'] as String),
              _buildDetailRow('Frequency', groupData['frequency'] as String),
              if (groupData['owner'] != null)
                _buildDetailRow('Owner', groupData['owner'] as String),
              if (groupData['isSystemGenerated'] == true)
                _buildDetailRow('Type', 'System Generated'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          if (groupData['isOwner'] == true)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.groupManagement,
                  arguments: {
                    'equbId': groupData['id'],
                    'isOwner': true,
                  },
                );
              },
              child: Text(
                'Manage',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.groupManagement,
                  arguments: {
                    'equbId': groupData['id'],
                    'isOwner': false,
                  },
                );
              },
              child: Text(
                'Open',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupOptions(Map<String, dynamic> groupData) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'View Details',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                _showGroupDetails(groupData);
              },
            ),
            if (groupData['isOwner'] == true) ...[
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'people',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Member Management',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to member management
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Group Settings',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to group settings
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Delete Group',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(groupData);
                },
              ),
            ] else ...[
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'exit_to_app',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Leave Group',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveConfirmation(groupData);
                },
              ),
            ],
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'Share Group',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                // Share group functionality
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> groupData) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: theme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Delete Group',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${groupData['name']}"? This action cannot be undone and all group data will be permanently removed.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _myEqubs.removeWhere((group) => group['id'] == groupData['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Group "${groupData['name']}" deleted successfully',
                  ),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(Map<String, dynamic> groupData) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: theme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Leave Group',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${groupData['name']}"? You will need to request to join again if you change your mind.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _joinedEqubs.removeWhere(
                  (group) => group['id'] == groupData['id'],
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Left group "${groupData['name']}" successfully',
                  ),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(
              'Leave',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
