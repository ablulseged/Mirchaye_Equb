import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/category_tab_widget.dart';
import './widgets/empty_browse_state.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/group_card.dart';
import '../../services/equb_service.dart';
import '../../services/user_service.dart';
import './widgets/search_bar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrowseEqubGroups extends StatefulWidget {
  const BrowseEqubGroups({Key? key}) : super(key: key);

  @override
  State<BrowseEqubGroups> createState() => _BrowseEqubGroupsState();
}

class _BrowseEqubGroupsState extends State<BrowseEqubGroups>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isRefreshing = false;

  // Filter state
  String _selectedAmountRange = 'All';
  String _selectedDuration = 'All';
  String _selectedLocation = 'All';
  String _selectedGroupSize = 'All';

  final List<String> amountRanges = [
    'All',
    '500-2,000 ETB',
    '2,000-5,000 ETB',
    '5,000+ ETB',
  ];

  final List<String> durations = [
    'All',
    '3-6 months',
    '6-12 months',
    '12+ months',
  ];

  final List<String> locations = ['All', 'Addis Ababa', 'Hawassa', 'Bahir Dar'];

  final List<String> groupSizes = [
    'All',
    '5-10 members',
    '10-15 members',
    '15+ members',
  ];

  final EqubService _equbService = EqubService();

  // Category list for filter chips
  final List<String> categories = [
    'All',
    'family',
    'friends',
    'work',
    'college',
    'savings',
    'general',
    'emergency',
    'education',
    'health',
    'business',
  ];

  String? _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedCategory = 'All';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> input) {
    List<Map<String, dynamic>> filtered = input;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((group) {
        final name = (group["name"] ?? '').toString().toLowerCase();
        final university = (group["university"] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || university.contains(query);
      }).toList();
    }

    // Filter by selected category chip
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((group) {
        final groupCategory = (group["category"] ?? '')
            .toString()
            .toLowerCase();
        return groupCategory == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Apply additional filters
    if (_selectedAmountRange != 'All') {
      filtered = filtered.where((group) {
        double amount = double.parse(
          group["contributionAmount"].replaceAll(',', ''),
        );
        switch (_selectedAmountRange) {
          case '500-2,000 ETB':
            return amount >= 500 && amount <= 2000;
          case '2,000-5,000 ETB':
            return amount > 2000 && amount <= 5000;
          case '5,000+ ETB':
            return amount > 5000;
          default:
            return true;
        }
      }).toList();
    }

    if (_selectedDuration != 'All') {
      filtered = filtered.where((group) {
        String duration = group["duration"];
        switch (_selectedDuration) {
          case '3-6 months':
            return duration.contains('3') || duration.contains('6');
          case '6-12 months':
            return duration.contains('9') || duration.contains('12');
          case '12+ months':
            return duration.contains('18') || duration.contains('24');
          default:
            return true;
        }
      }).toList();
    }

    if (_selectedLocation != 'All') {
      filtered = filtered
          .where((group) => group["university"] == _selectedLocation)
          .toList();
    }

    if (_selectedGroupSize != 'All') {
      filtered = filtered.where((group) {
        int maxMembers = group["maxMembers"];
        switch (_selectedGroupSize) {
          case '5-10 members':
            return maxMembers >= 5 && maxMembers <= 10;
          case '10-15 members':
            return maxMembers > 10 && maxMembers <= 15;
          case '15+ members':
            return maxMembers > 15;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    setState(() => _searchQuery = query);
  }

  void _showAdvancedFilters() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 70.h,
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Advanced Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedAmountRange = 'All';
                            _selectedDuration = 'All';
                            _selectedLocation = 'All';
                            _selectedGroupSize = 'All';
                          });
                          setState(() {});
                        },
                        child: Text('Reset'),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection(
                            'Contribution Amount',
                            amountRanges,
                            _selectedAmountRange,
                            (value) => setModalState(
                              () => _selectedAmountRange = value,
                            ),
                          ),
                          _buildFilterSection(
                            'Duration',
                            durations,
                            _selectedDuration,
                            (value) =>
                                setModalState(() => _selectedDuration = value),
                          ),
                          _buildFilterSection(
                            'Category',
                            locations,
                            _selectedLocation,
                            (value) =>
                                setModalState(() => _selectedLocation = value),
                          ),
                          _buildFilterSection(
                            'Group Size',
                            groupSizes,
                            _selectedGroupSize,
                            (value) =>
                                setModalState(() => _selectedGroupSize = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onChanged,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return FilterChipWidget(
              label: option,
              isSelected: isSelected,
              onTap: () => onChanged(option),
            );
          }).toList(),
        ),
        SizedBox(height: 3.h),
      ],
    );
  }

  void _toggleSaved(String groupId) async {
    try {
      await UserService().toggleSavedEqub(groupId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update saved: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleFavorite(String groupId) async {
    try {
      await UserService().toggleFavoriteEqub(groupId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Favorite updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
        );
      }
    }
  }

  void _showGroupDetails(Map<String, dynamic> group) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 70.h,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group["name"],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(group["id"]),
                    icon: CustomIconWidget(
                      iconName: group["isBookmarked"]
                          ? 'bookmark'
                          : 'bookmark_border',
                      color: group["isBookmarked"]
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        group["description"],
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 2.h),
                      _buildDetailRow(
                        'Contribution Amount',
                        '${group["contributionAmount"]} ETB',
                      ),
                      _buildDetailRow('Duration', group["duration"]),
                      _buildDetailRow(
                        'Payment Frequency',
                        group["paymentFrequency"],
                      ),
                      _buildDetailRow(
                        'Next Cycle Start',
                        group["nextCycleStart"],
                      ),
                      _buildDetailRow(
                        'Current Members',
                        '${group["currentMembers"]}/${group["maxMembers"]}',
                      ),
                      _buildDetailRow('University', group["university"]),
                      _buildDetailRow('Admin', group["adminName"]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showJoinDialog(group);
                      },
                      child: Text('Request to Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(Map<String, dynamic> group) {
    final theme = Theme.of(context);
    final parentContext = context;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join Equb Group', style: theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are requesting to join:',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                group["name"],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Monthly Contribution:'),
                        Text(
                          '${group["contributionAmount"]} ETB',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Commitment Period:'),
                        Text(
                          group["duration"],
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the dialog first
                Navigator.pop(context);
                // Show a loading overlay while sending request
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  await _equbService.requestToJoin(equbId: group['id']);
                  Navigator.of(parentContext, rootNavigator: true).pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Request sent to ${group["adminName"]}'),
                      backgroundColor: AppTheme.getSuccessColorFromContext(
                        parentContext,
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.of(parentContext, rootNavigator: true).pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Request not sent: ${e.toString()}'),
                      backgroundColor: Theme.of(
                        parentContext,
                      ).colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Browse Equb Groups',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          SearchBarWidget(onSearchChanged: _onSearchChanged),

          // Filter Chips
          Container(
            height: 6.h,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      FilterChipWidget(
                        label: _selectedAmountRange == 'All'
                            ? 'Amount'
                            : _selectedAmountRange,
                        isSelected: _selectedAmountRange != 'All',
                        onTap: _showAdvancedFilters,
                        showIcon: true,
                      ),
                      SizedBox(width: 2.w),
                      FilterChipWidget(
                        label: _selectedDuration == 'All'
                            ? 'Duration'
                            : _selectedDuration,
                        isSelected: _selectedDuration != 'All',
                        onTap: _showAdvancedFilters,
                        showIcon: true,
                      ),
                      SizedBox(width: 2.w),
                      FilterChipWidget(
                        label: _selectedLocation == 'All'
                            ? 'Department'
                            : _selectedLocation.split(' ').first,
                        isSelected: _selectedLocation != 'All',
                        onTap: _showAdvancedFilters,
                        showIcon: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 4.w),
                  child: IconButton(
                    onPressed: _showAdvancedFilters,
                    icon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'tune',
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          Container(
            height: 5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return Container(
                  margin: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(
                      category == 'All'
                          ? 'All'
                          : category[0].toUpperCase() + category.substring(1),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12.sp,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                  ),
                );
              },
            ),
          ),

          // Groups List - Show only regular groups
          Expanded(
            child: StreamBuilder(
              stream: _equbService.streamPublicEqubs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Only regular groups
                final List<Map<String, dynamic>> allGroups = [];

                // Add regular groups (exclude system-generated groups)
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final docs = snapshot.data!.docs;
                  for (final doc in docs) {
                    final data = doc.data();
                    // Filter out system-generated groups
                    final isSystem = data['isSystemGenerated'] ?? false;
                    final isMirchaye = data['isMirchayeGroup'] ?? false;
                    final ownerUid = data['ownerUid'] ?? '';
                    if (isSystem == true ||
                        isMirchaye == true ||
                        ownerUid == 'system') {
                      continue; // Skip system groups
                    }

                    final rawCategory = (data['category'] ?? 'general')
                        .toString()
                        .toLowerCase();
                    allGroups.add({
                      'id': doc.id,
                      'name': data['name'] ?? 'Untitled Equb',
                      'description': data['description'] ?? '',
                      'contributionAmount': (data['contributionAmount'] is num)
                          ? (data['contributionAmount'] as num).toStringAsFixed(
                              2,
                            )
                          : (data['contributionAmount']?.toString() ?? '0'),
                      'duration': data['paymentFrequency'] ?? 'Monthly',
                      'currentMembers': data['currentMembers'] ?? 0,
                      'maxMembers': data['maxMembers'] ?? 0,
                      'adminName': data['ownerEmail'] ?? 'Admin',
                      'ownerUid': data['ownerUid'],
                      'adminAvatar':
                          data['ownerPhotoUrl'] ??
                          data['coverImageUrl'] ??
                          'https://i.pravatar.cc/150?u=${data['ownerEmail'] ?? 'fallback'}',
                      'university': rawCategory,
                      'category': rawCategory,
                      'nextCycleStart': (data['startDate'] != null)
                          ? (data['startDate'] as Timestamp)
                                .toDate()
                                .toString()
                                .split(' ')
                                .first
                          : '-',
                      'paymentFrequency': data['paymentFrequency'] ?? 'Monthly',
                      'isBookmarked': false,
                      'isFavorited': false,
                      'isSystemGenerated': data['isSystemGenerated'] ?? false,
                      'createdAtTs': (data['createdAt'] != null)
                          ? (data['createdAt'] as Timestamp).toDate()
                          : null,
                    });
                  }
                }

                // Client-side sort by createdAt desc if present
                allGroups.sort((a, b) {
                  final DateTime? aTs = a['createdAtTs'] as DateTime?;
                  final DateTime? bTs = b['createdAtTs'] as DateTime?;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

                final filtered = _applyFilters(allGroups);

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: theme.colorScheme.primary,
                  child: filtered.isEmpty
                      ? EmptyBrowseState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final group = filtered[index];
                            return GroupCard(
                              group: group,
                              onTap: () => _showGroupDetails(group),
                              onSaved: () => _toggleSaved(group['id']),
                              onFavorite: () => _toggleFavorite(group['id']),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
