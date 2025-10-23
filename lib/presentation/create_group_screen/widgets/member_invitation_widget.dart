import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MemberInvitationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> invitedMembers;
  final Function(Map<String, dynamic>) onMemberAdded;
  final Function(int) onMemberRemoved;

  const MemberInvitationWidget({
    super.key,
    required this.invitedMembers,
    required this.onMemberAdded,
    required this.onMemberRemoved,
  });

  @override
  State<MemberInvitationWidget> createState() => _MemberInvitationWidgetState();
}

class _MemberInvitationWidgetState extends State<MemberInvitationWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'person_add',
                  color: colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Invite Members',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Add Member Form
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Member',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Member Name',
                      hintText: 'Enter member\'s full name',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: colorScheme.primary,
                          size: 5.w,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'phone',
                          color: colorScheme.primary,
                          size: 5.w,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showContactPicker,
                          icon: CustomIconWidget(
                            iconName: 'contacts',
                            color: colorScheme.primary,
                            size: 4.w,
                          ),
                          label: const Text('From Contacts'),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addMember,
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: colorScheme.onPrimary,
                            size: 4.w,
                          ),
                          label: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Invited Members List
            if (widget.invitedMembers.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invited Members (${widget.invitedMembers.length})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _shareGroupCode,
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: colorScheme.primary,
                      size: 4.w,
                    ),
                    label: const Text('Share Code'),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.invitedMembers.length,
                separatorBuilder: (context, index) => SizedBox(height: 1.h),
                itemBuilder: (context, index) {
                  final member = widget.invitedMembers[index];
                  return Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            (member['name'] as String)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                member['phone'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: member['status'] == 'pending'
                                ? colorScheme.secondary.withValues(alpha: 0.1)
                                : colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member['status'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: member['status'] == 'pending'
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        IconButton(
                          onPressed: () => widget.onMemberRemoved(index),
                          icon: CustomIconWidget(
                            iconName: 'remove_circle_outline',
                            color: colorScheme.error,
                            size: 5.w,
                          ),
                          tooltip: 'Remove member',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CustomIconWidget(
                      iconName: 'people_outline',
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 12.w,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No members invited yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'Add members to start your Equb group',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addMember() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and phone number'),
        ),
      );
      return;
    }

    final member = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'status': 'pending',
      'invitedAt': DateTime.now(),
    };

    widget.onMemberAdded(member);
    _nameController.clear();
    _phoneController.clear();
  }

  void _showContactPicker() {
    // Mock contact selection
    final mockContacts = [
      {'name': 'Sarah Johnson', 'phone': '+1 (555) 123-4567'},
      {'name': 'Michael Chen', 'phone': '+1 (555) 234-5678'},
      {'name': 'Fatima Al-Rashid', 'phone': '+1 (555) 345-6789'},
      {'name': 'David Rodriguez', 'phone': '+1 (555) 456-7890'},
      {'name': 'Aisha Okonkwo', 'phone': '+1 (555) 567-8901'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Select Contact',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: mockContacts.length,
                itemBuilder: (context, index) {
                  final contact = mockContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        (contact['name'] as String).substring(0, 1),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(contact['name'] as String),
                    subtitle: Text(contact['phone'] as String),
                    onTap: () {
                      _nameController.text = contact['name'] as String;
                      _phoneController.text = contact['phone'] as String;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareGroupCode() {
    final groupCode =
        'EQUB${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Group Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code with members to join your Equb group:'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                groupCode,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group code copied to clipboard')),
              );
            },
            child: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }
}
