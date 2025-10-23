import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TermsAgreementWidget extends StatelessWidget {
  final bool isAgreed;
  final Function(bool) onAgreementChanged;
  final double contributionAmount;
  final String paymentFrequency;
  final int groupSize;
  final double latePenaltyPercentage;
  final double emergencyFundPercentage;
  final bool allowEarlyExit;

  const TermsAgreementWidget({
    super.key,
    required this.isAgreed,
    required this.onAgreementChanged,
    required this.contributionAmount,
    required this.paymentFrequency,
    required this.groupSize,
    required this.latePenaltyPercentage,
    required this.emergencyFundPercentage,
    required this.allowEarlyExit,
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
                  iconName: 'gavel',
                  color: colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Group Agreement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Agreement Summary
            Container(
              width: double.infinity,
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
                    'Agreement Summary',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildAgreementItem(
                    context,
                    'Contribution Amount',
                    '\$${contributionAmount.toInt()} per ${paymentFrequency.substring(0, paymentFrequency.length - 2)}',
                    'payments',
                  ),
                  _buildAgreementItem(
                    context,
                    'Group Size',
                    '$groupSize members',
                    'people',
                  ),
                  _buildAgreementItem(
                    context,
                    'Total Payout',
                    '\$${(contributionAmount * groupSize).toInt()}',
                    'account_balance',
                  ),
                  _buildAgreementItem(
                    context,
                    'Cycle Duration',
                    paymentFrequency == 'weekly'
                        ? '$groupSize weeks'
                        : '$groupSize months',
                    'schedule',
                  ),
                  if (latePenaltyPercentage > 0)
                    _buildAgreementItem(
                      context,
                      'Late Penalty',
                      '${latePenaltyPercentage.toInt()}% of contribution',
                      'warning',
                    ),
                  if (emergencyFundPercentage > 0)
                    _buildAgreementItem(
                      context,
                      'Emergency Fund',
                      '${emergencyFundPercentage.toInt()}% of each contribution',
                      'security',
                    ),
                  _buildAgreementItem(
                    context,
                    'Early Exit',
                    allowEarlyExit ? 'Allowed with penalty' : 'Not allowed',
                    allowEarlyExit ? 'exit_to_app' : 'block',
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Terms and Conditions
            Container(
              width: double.infinity,
              height: 20.h,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms and Conditions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _generateTermsText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Agreement Checkbox
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isAgreed
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAgreed
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: CheckboxListTile(
                value: isAgreed,
                onChanged: (value) => onAgreementChanged(value ?? false),
                title: Text(
                  'I agree to the terms and conditions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'By checking this box, you agree to abide by all group rules and financial commitments outlined above.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!isAgreed) ...[
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: colorScheme.error,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'You must agree to the terms to create the group',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
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

  Widget _buildAgreementItem(
    BuildContext context,
    String label,
    String value,
    String iconName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: colorScheme.primary,
            size: 4.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _generateTermsText() {
    return '''1. MEMBERSHIP COMMITMENT
All members commit to making regular contributions of \$${contributionAmount.toInt()} every ${paymentFrequency.substring(0, paymentFrequency.length - 2)} for the duration of the Equb cycle.

2. PAYMENT SCHEDULE
Contributions are due on the agreed schedule. ${latePenaltyPercentage > 0 ? 'Late payments will incur a ${latePenaltyPercentage.toInt()}% penalty fee.' : 'Timely payments are expected from all members.'}

3. PAYOUT ROTATION
Each member will receive their payout turn of \$${(contributionAmount * groupSize).toInt()} according to the predetermined rotation schedule.

4. EMERGENCY FUND
${emergencyFundPercentage > 0 ? '${emergencyFundPercentage.toInt()}% of each contribution will be allocated to an emergency fund for group use.' : 'No emergency fund has been established for this group.'}

5. EARLY EXIT POLICY
${allowEarlyExit ? 'Members may exit early but will forfeit their payout and may be subject to penalties.' : 'Members must complete the full cycle and cannot exit early.'}

6. DISPUTE RESOLUTION
Any disputes will be resolved through group consensus or mediation. All financial records will be transparent and accessible to group members.

7. DATA PRIVACY
All personal and financial information will be kept confidential and used only for group management purposes.

8. MODIFICATION OF TERMS
These terms can only be modified with unanimous consent from all group members.

By creating this group, you acknowledge that you have read, understood, and agree to these terms and conditions.''';
  }
}
