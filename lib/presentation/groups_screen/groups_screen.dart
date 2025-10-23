import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/group_card_widget.dart';
import './widgets/group_creation_modal.dart';
import './widgets/search_bar_widget.dart';

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

  // My Equbs - Limited to 1 group maximum
  final List<Map<String, dynamic>> _myEqubs = [
    {
      'id': 1,
      'name': 'Family Savings Circle',
      'description':
          'Monthly savings group for family members and close friends',
      'amount': 5000.0,
      'maxMembers': 12,
      'currentMembers': 8,
      'status': 'Active',
      'frequency': 'Monthly',
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      'isOwner': true,
    },
  ];

  // Joined Equbs - Limited to 2 groups maximum
  final List<Map<String, dynamic>> _joinedEqubs = [
    {
      'id': 4,
      'name': 'Neighborhood Support Group',
      'description': 'Supporting each other through monthly contributions',
      'amount': 2500.0,
      'maxMembers': 15,
      'currentMembers': 12,
      'status': 'Active',
      'frequency': 'Monthly',
      'createdAt': DateTime.now().subtract(const Duration(days: 45)),
      'isOwner': false,
      'owner': 'Almaz Tadesse',
    },
    {
      'id': 5,
      'name': 'Professional Network Equb',
      'description':
          'Career-focused professionals pooling resources for growth',
      'amount': 8000.0,
      'maxMembers': 10,
      'currentMembers': 9,
      'status': 'Active',
      'frequency': 'Monthly',
      'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      'isOwner': false,
      'owner': 'Dawit Bekele',
    },
  ];

  final List<Map<String, dynamic>> _systemGroups = [
    {
      'id': 7,
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
      'id': 8,
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

  bool get _canCreateNewGroup => _myEqubs.length < MAX_MY_EQUBS;
  bool get _canJoinNewGroup => _joinedEqubs.length < MAX_JOINED_EQUBS;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
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
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppTheme.lightTheme.colorScheme.onPrimary,
                unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
                labelStyle: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w400),
                tabs: [
                  Tab(text: 'My Equb (${_myEqubs.length}/$MAX_MY_EQUBS)'),
                  Tab(
                    text: 'Joined (${_joinedEqubs.length}/$MAX_JOINED_EQUBS)',
                  ),
                  const Tab(text: 'System'),
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
      floatingActionButton: _canCreateNewGroup
          ? FloatingActionButton.extended(
              onPressed: _showGroupCreationModal,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
              icon: CustomIconWidget(
                iconName: 'add',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 24,
              ),
              label: Text(
                'Create Equb',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showLimitReachedDialog('create'),
              backgroundColor: AppTheme.lightTheme.colorScheme.outline,
              foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
              icon: CustomIconWidget(
                iconName: 'block',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              label: Text(
                'Limit Reached',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildMyEqubsTab() {
    final filteredGroups = _getFilteredGroups(_myEqubs);

    if (filteredGroups.isEmpty && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        title: 'Create Your Equb',
        description:
            'You can create one Equb group to start building your savings community. Invite friends and family to join your financial journey.',
        buttonText: 'Create New Equb',
        iconName: 'group_add',
        onButtonPressed: _canCreateNewGroup
            ? _showGroupCreationModal
            : () => _showLimitReachedDialog('create'),
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
      child: Column(
        children: [
          // Limit status banner
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _myEqubs.length >= MAX_MY_EQUBS
                  ? AppTheme.lightTheme.colorScheme.errorContainer
                  : AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _myEqubs.length >= MAX_MY_EQUBS
                    ? AppTheme.lightTheme.colorScheme.error.withValues(
                        alpha: 0.3,
                      )
                    : AppTheme.lightTheme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _myEqubs.length >= MAX_MY_EQUBS
                      ? 'warning'
                      : 'info',
                  color: _myEqubs.length >= MAX_MY_EQUBS
                      ? AppTheme.lightTheme.colorScheme.error
                      : AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _myEqubs.length >= MAX_MY_EQUBS
                        ? 'You have reached the maximum limit of $MAX_MY_EQUBS Equb group.'
                        : 'You can create ${MAX_MY_EQUBS - _myEqubs.length} more Equb group.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _myEqubs.length >= MAX_MY_EQUBS
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedEqubsTab() {
    final filteredGroups = _getFilteredGroups(_joinedEqubs);

    if (filteredGroups.isEmpty && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        title: 'Join Equb Groups',
        description:
            'You can join up to $MAX_JOINED_EQUBS existing Equb groups in your community. Connect with others and start saving together.',
        buttonText: 'Browse Groups',
        iconName: 'group',
        onButtonPressed: () {
          // Navigate to browse groups screen
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
      child: Column(
        children: [
          // Limit status banner
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _joinedEqubs.length >= MAX_JOINED_EQUBS
                  ? AppTheme.lightTheme.colorScheme.errorContainer
                  : AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _joinedEqubs.length >= MAX_JOINED_EQUBS
                    ? AppTheme.lightTheme.colorScheme.error.withValues(
                        alpha: 0.3,
                      )
                    : AppTheme.lightTheme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _joinedEqubs.length >= MAX_JOINED_EQUBS
                      ? 'warning'
                      : 'info',
                  color: _joinedEqubs.length >= MAX_JOINED_EQUBS
                      ? AppTheme.lightTheme.colorScheme.error
                      : AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _joinedEqubs.length >= MAX_JOINED_EQUBS
                        ? 'You have reached the maximum limit of $MAX_JOINED_EQUBS joined groups.'
                        : 'You can join ${MAX_JOINED_EQUBS - _joinedEqubs.length} more groups.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _joinedEqubs.length >= MAX_JOINED_EQUBS
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemGroupsTab() {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Limit Reached',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text(
          action == 'create'
              ? 'You can only create one Equb group. To create a new group, you must delete your existing group first.'
              : 'You can only join up to $MAX_JOINED_EQUBS groups. To join a new group, you must leave one of your current groups first.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Understand',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(Map<String, dynamic> groupData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          groupData['name'] as String,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
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
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
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
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          if (groupData['isOwner'] == true)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to group management
              },
              child: Text(
                'Manage',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              '$label:',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupOptions(Map<String, dynamic> groupData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
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
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'View Details',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
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
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Member Management',
                  style: AppTheme.lightTheme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to member management
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'settings',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Group Settings',
                  style: AppTheme.lightTheme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to group settings
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Delete Group',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
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
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Leave Group',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
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
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'Share Group',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Delete Group',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${groupData['name']}"? This action cannot be undone and all group data will be permanently removed.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
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
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(Map<String, dynamic> groupData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Leave Group',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${groupData['name']}"? You will need to request to join again if you change your mind.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
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
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text(
              'Leave',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
