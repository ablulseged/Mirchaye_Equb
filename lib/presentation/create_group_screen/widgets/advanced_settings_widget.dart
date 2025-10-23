import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AdvancedSettingsWidget extends StatefulWidget {
  final double latePenaltyPercentage;
  final double emergencyFundPercentage;
  final bool allowEarlyExit;
  final Function(double) onLatePenaltyChanged;
  final Function(double) onEmergencyFundChanged;
  final Function(bool) onEarlyExitChanged;

  const AdvancedSettingsWidget({
    super.key,
    required this.latePenaltyPercentage,
    required this.emergencyFundPercentage,
    required this.allowEarlyExit,
    required this.onLatePenaltyChanged,
    required this.onEmergencyFundChanged,
    required this.onEarlyExitChanged,
  });

  @override
  State<AdvancedSettingsWidget> createState() => _AdvancedSettingsWidgetState();
}

class _AdvancedSettingsWidgetState extends State<AdvancedSettingsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          leading: CustomIconWidget(
            iconName: 'settings',
            color: colorScheme.primary,
            size: 6.w,
          ),
          title: Text(
            'Advanced Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Optional configurations for your Equb',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Late Payment Penalty
                  _buildSettingSection(
                    context,
                    title: 'Late Payment Penalty',
                    subtitle: 'Percentage penalty for late contributions',
                    icon: 'warning',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: widget.latePenaltyPercentage,
                                min: 0,
                                max: 20,
                                divisions: 20,
                                label:
                                    '${widget.latePenaltyPercentage.toInt()}%',
                                onChanged: widget.onLatePenaltyChanged,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.latePenaltyPercentage.toInt()}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.latePenaltyPercentage > 0)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Members will be charged ${widget.latePenaltyPercentage.toInt()}% penalty for late payments',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Emergency Fund
                  _buildSettingSection(
                    context,
                    title: 'Emergency Fund',
                    subtitle: 'Percentage of contributions for emergency fund',
                    icon: 'security',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: widget.emergencyFundPercentage,
                                min: 0,
                                max: 15,
                                divisions: 15,
                                label:
                                    '${widget.emergencyFundPercentage.toInt()}%',
                                onChanged: widget.onEmergencyFundChanged,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.emergencyFundPercentage.toInt()}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.emergencyFundPercentage > 0)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.emergencyFundPercentage.toInt()}% of each contribution will go to emergency fund',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Early Exit Policy
                  _buildSettingSection(
                    context,
                    title: 'Early Exit Policy',
                    subtitle: 'Allow members to leave before their payout turn',
                    icon: 'exit_to_app',
                    child: SwitchListTile(
                      value: widget.allowEarlyExit,
                      onChanged: widget.onEarlyExitChanged,
                      title: Text(
                        widget.allowEarlyExit
                            ? 'Early exit allowed'
                            : 'Early exit not allowed',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        widget.allowEarlyExit
                            ? 'Members can leave with penalty'
                            : 'Members must complete full cycle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: colorScheme.primary,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        child,
      ],
    );
  }
}
