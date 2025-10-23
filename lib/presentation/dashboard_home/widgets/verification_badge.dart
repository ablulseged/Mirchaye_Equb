import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String universityName;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    required this.universityName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isVerified
            ? AppTheme.getSuccessColor(true).withValues(alpha: 0.1)
            : AppTheme.getWarningColor(true).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? AppTheme.getSuccessColor(true)
              : AppTheme.getWarningColor(true),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isVerified ? 'verified' : 'pending',
            color: isVerified
                ? AppTheme.getSuccessColor(true)
                : AppTheme.getWarningColor(true),
            size: 16,
          ),
          SizedBox(width: 1.w),
          Flexible(
            child: Text(
              isVerified ? '$universityName Verified' : 'Verification Pending',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isVerified
                    ? AppTheme.getSuccessColor(true)
                    : AppTheme.getWarningColor(true),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
