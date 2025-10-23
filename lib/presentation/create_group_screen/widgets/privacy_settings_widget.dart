import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PrivacySettingsWidget extends StatelessWidget {
  final bool isPublic;
  final bool requireApproval;
  final Function(bool) onPublicChanged;
  final Function(bool) onApprovalChanged;

  const PrivacySettingsWidget({
    super.key,
    required this.isPublic,
    required this.requireApproval,
    required this.onPublicChanged,
    required this.onApprovalChanged,
  });

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
                  iconName: 'privacy_tip',
                  color: colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Privacy Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Group Visibility
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
                children: [
                  SwitchListTile(
                    value: isPublic,
                    onChanged: onPublicChanged,
                    title: Text(
                      'Public Group',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      isPublic
                          ? 'Anyone can discover and request to join'
                          : 'Only invited members can join',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    secondary: CustomIconWidget(
                      iconName: isPublic ? 'public' : 'lock',
                      color: colorScheme.primary,
                      size: 6.w,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isPublic) ...[
                    Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
                    SwitchListTile(
                      value: requireApproval,
                      onChanged: onApprovalChanged,
                      title: Text(
                        'Require Approval',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        requireApproval
                            ? 'Admin must approve new member requests'
                            : 'Members can join immediately',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      secondary: CustomIconWidget(
                        iconName: requireApproval
                            ? 'admin_panel_settings'
                            : 'how_to_reg',
                        color: colorScheme.primary,
                        size: 6.w,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Privacy Information
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        color: colorScheme.primary,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Privacy Information',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildPrivacyPoint(
                    context,
                    'Financial data is always encrypted and secure',
                    'security',
                  ),
                  SizedBox(height: 1.h),
                  _buildPrivacyPoint(
                    context,
                    'Only group members can see contribution details',
                    'visibility',
                  ),
                  SizedBox(height: 1.h),
                  _buildPrivacyPoint(
                    context,
                    'Personal information is never shared publicly',
                    'shield',
                  ),
                  SizedBox(height: 1.h),
                  _buildPrivacyPoint(
                    context,
                    'You can change privacy settings anytime',
                    'edit',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint(
    BuildContext context,
    String text,
    String iconName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: colorScheme.primary,
          size: 4.w,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
