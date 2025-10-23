import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GroupCardWidget extends StatelessWidget {
  final Map<String, dynamic> groupData;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String groupType;

  const GroupCardWidget({
    Key? key,
    required this.groupData,
    this.onTap,
    this.onLongPress,
    required this.groupType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String status = (groupData['status'] as String?) ?? 'Active';
    final int currentMembers = (groupData['currentMembers'] as int?) ?? 0;
    final int maxMembers = (groupData['maxMembers'] as int?) ?? 10;
    final double amount = (groupData['amount'] as double?) ?? 0.0;
    final String groupName = (groupData['name'] as String?) ?? 'Unnamed Group';
    final String description = (groupData['description'] as String?) ?? '';

    Color statusColor = _getStatusColor(status);
    double progress = maxMembers > 0 ? currentMembers / maxMembers : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        groupName,
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    description,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 2.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'account_balance_wallet',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'ETB ${amount.toStringAsFixed(2)}',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'group',
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '$currentMembers/$maxMembers members',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme.lightTheme.colorScheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
                if (groupType == 'my_equbs') ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMemberManagement(context),
                          icon: CustomIconWidget(
                            iconName: 'people',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 16,
                          ),
                          label: Text(
                            'Manage',
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                            side: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showGroupDetails(context),
                          icon: CustomIconWidget(
                            iconName: 'visibility',
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 16,
                          ),
                          label: Text(
                            'Details',
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.onPrimary,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'pending':
        return const Color(0xFFF57C00);
      case 'complete':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'inactive':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  void _showMemberManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Text(
                    'Member Management',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final List<Map<String, dynamic>> pendingMembers = [
                    {
                      'name': 'Almaz Tadesse',
                      'avatar':
                          'https://images.unsplash.com/photo-1618085219724-c59ba48e08cd',
                      'semanticLabel':
                          'Profile photo of a woman with curly black hair wearing a blue blouse',
                      'joinDate': '2 days ago',
                      'status': 'pending',
                    },
                    {
                      'name': 'Dawit Bekele',
                      'avatar':
                          'https://images.unsplash.com/photo-1633625763717-045645e9e739',
                      'semanticLabel':
                          'Profile photo of a man with short brown hair and a beard wearing a dark t-shirt',
                      'joinDate': '1 day ago',
                      'status': 'pending',
                    },
                    {
                      'name': 'Hanan Mohammed',
                      'avatar':
                          'https://images.unsplash.com/photo-1702346249859-34db7962e153',
                      'semanticLabel':
                          'Profile photo of a woman with long black hair wearing a white shirt',
                      'joinDate': '3 hours ago',
                      'status': 'pending',
                    },
                    {
                      'name': 'Yohannes Girma',
                      'avatar':
                          'https://images.unsplash.com/photo-1624491949737-a0ad51eca61c',
                      'semanticLabel':
                          'Profile photo of a man with short black hair wearing a green polo shirt',
                      'joinDate': '5 hours ago',
                      'status': 'approved',
                    },
                    {
                      'name': 'Meron Assefa',
                      'avatar':
                          'https://images.unsplash.com/photo-1589503000135-d7c95c396499',
                      'semanticLabel':
                          'Profile photo of a woman with shoulder-length black hair wearing a red dress',
                      'joinDate': '1 week ago',
                      'status': 'approved',
                    },
                  ];

                  if (index >= pendingMembers.length)
                    return const SizedBox.shrink();

                  final member = pendingMembers[index];
                  final bool isPending =
                      (member['status'] as String) == 'pending';

                  return Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 6.w,
                          child: CustomImageWidget(
                            imageUrl: member['avatar'] as String,
                            width: 12.w,
                            height: 12.w,
                            fit: BoxFit.cover,
                            semanticLabel: member['semanticLabel'] as String,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'] as String,
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Requested ${member['joinDate']}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isPending) ...[
                          IconButton(
                            onPressed: () {},
                            icon: CustomIconWidget(
                              iconName: 'close',
                              color: AppTheme.lightTheme.colorScheme.error,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: CustomIconWidget(
                              iconName: 'check',
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                              size: 20,
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.tertiary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Approved',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .tertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Group Details',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Name: ${groupData['name']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Amount: ETB ${(groupData['amount'] as double).toStringAsFixed(2)}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Members: ${groupData['currentMembers']}/${groupData['maxMembers']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Status: ${groupData['status']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
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
        ],
      ),
    );
  }
}
