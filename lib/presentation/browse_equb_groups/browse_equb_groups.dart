import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/category_tab_widget.dart';
import './widgets/empty_browse_state.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/group_card.dart';
import './widgets/search_bar_widget.dart';

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

  final List<String> locations = ['All', 'IS', 'Software Engineering', 'IT'];

  final List<String> groupSizes = [
    'All',
    '5-10 members',
    '10-15 members',
    '15+ members',
  ];

  // Mock equb groups data
  final List<Map<String, dynamic>> allGroups = [
    {
      "id": 1,
      "name": "Computer Science Students Equb",
      "contributionAmount": "4,500.00",
      "duration": "12 months",
      "currentMembers": 8,
      "maxMembers": 12,
      "adminName": "Almaz Tadesse",
      "adminAvatar":
          "https://images.unsplash.com/photo-1644128283874-ed27887734ec",
      "university": "Wachemo University",
      "trustRating": 4.8,
      "category": "student",
      "description":
          "Monthly savings group for CS students to support academic expenses",
      "nextCycleStart": "2025-11-01",
      "paymentFrequency": "Monthly",
      "isBookmarked": false,
    },
    {
      "id": 2,
      "name": "Dormitory Block A Equb",
      "contributionAmount": "2,000.00",
      "duration": "6 months",
      "currentMembers": 6,
      "maxMembers": 8,
      "adminName": "Dawit Haile",
      "adminAvatar":
          "https://images.unsplash.com/photo-1659430752005-6ea1ba732745",
      "university": "Wachemo University",
      "trustRating": 4.5,
      "category": "student",
      "description":
          "Dormitory residents saving for room improvements and events",
      "nextCycleStart": "2025-10-30",
      "paymentFrequency": "Monthly",
      "isBookmarked": true,
    },
    {
      "id": 3,
      "name": "Women Entrepreneurs Network",
      "contributionAmount": "8,000.00",
      "duration": "18 months",
      "currentMembers": 12,
      "maxMembers": 15,
      "adminName": "Hanan Mohammed",
      "adminAvatar":
          "https://images.unsplash.com/photo-1496725288175-64caa3b2e9f6",
      "university": "WCU University",
      "trustRating": 4.9,
      "category": "professional",
      "description":
          "Professional network for women entrepreneurs and business owners",
      "nextCycleStart": "2025-11-15",
      "paymentFrequency": "Monthly",
      "isBookmarked": false,
    },
    {
      "id": 4,
      "name": "Community Health Initiative",
      "contributionAmount": "1,500.00",
      "duration": "9 months",
      "currentMembers": 10,
      "maxMembers": 20,
      "adminName": "Dr. Kebede Assefa",
      "adminAvatar":
          "https://images.unsplash.com/photo-1727782383174-c498f69acc5c",
      "university": "WCU University",
      "trustRating": 4.7,
      "category": "community",
      "description":
          "Community-focused group supporting local health initiatives",
      "nextCycleStart": "2025-12-01",
      "paymentFrequency": "Monthly",
      "isBookmarked": false,
    },
  ];

  final List<String> _favoriteGroups = [];

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

  List<Map<String, dynamic>> get _filteredGroups {
    List<Map<String, dynamic>> filtered = allGroups;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((group) {
        return group["name"].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            group["university"].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    // Filter by category tab
    String categoryFilter = '';
    switch (_tabController.index) {
      case 0:
        categoryFilter = 'student';
        break;
      case 1:
        categoryFilter = 'professional';
        break;
      case 2:
        categoryFilter = 'community';
        break;
    }

    if (categoryFilter.isNotEmpty) {
      filtered = filtered
          .where((group) => group["category"] == categoryFilter)
          .toList();
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
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _showAdvancedFilters() {
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
                        style: AppTheme.lightTheme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                            'Department',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
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

  void _toggleFavorite(int groupId) {
    setState(() {
      final index = allGroups.indexWhere((group) => group["id"] == groupId);
      if (index != -1) {
        allGroups[index]["isBookmarked"] = !allGroups[index]["isBookmarked"];
      }
    });
  }

  void _showGroupDetails(Map<String, dynamic> group) {
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
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
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
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        group["description"],
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
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
                      _buildDetailRow(
                        'Trust Rating',
                        '${group["trustRating"]}/5.0',
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Join Equb Group',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are requesting to join:',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                group["name"],
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
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
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Join request sent to ${group["adminName"]}'),
                    backgroundColor: AppTheme.getSuccessColor(true),
                  ),
                );
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Browse Equb Groups',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
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
                        color: AppTheme.lightTheme.colorScheme.primary,
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

          // Category Tabs
          Container(
            child: TabBar(
              controller: _tabController,
              onTap: (index) => setState(() {}),
              tabs: [
                CategoryTabWidget(title: 'Student Groups'),
                CategoryTabWidget(title: 'Professional'),
                CategoryTabWidget(title: 'Community'),
              ],
            ),
          ),

          // Groups List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppTheme.lightTheme.colorScheme.primary,
              child: _filteredGroups.isEmpty
                  ? EmptyBrowseState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = _filteredGroups[index];
                        return GroupCard(
                          group: group,
                          onTap: () => _showGroupDetails(group),
                          onFavorite: () => _toggleFavorite(group["id"]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
