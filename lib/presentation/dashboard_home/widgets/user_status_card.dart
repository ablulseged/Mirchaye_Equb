import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UserStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final double progress;
  final Color progressColor;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeAction;

  const UserStatusCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.progress,
    required this.progressColor,
    this.onTap,
    this.onSwipeAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85.w,
        margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withOpacity(
                0.5,
              ), // lighter shadow
              blurRadius: 4, // smaller blur
              offset: const Offset(0, 2), // optional: move shadow closer
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        subtitle,
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme
                                  .lightTheme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
