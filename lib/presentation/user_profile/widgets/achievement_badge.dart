// import 'package:flutter/material.dart';
// import 'package:sizer/sizer.dart';

// import '../../../core/app_export.dart';

// class AchievementBadge extends StatelessWidget {
//   final String title;
//   final String description;
//   final String iconName;
//   final Color color;
//   final bool isEarned;

//   const AchievementBadge({
//     Key? key,
//     required this.title,
//     required this.description,
//     required this.iconName,
//     required this.color,
//     required this.isEarned,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 30.w,
//       margin: EdgeInsets.only(right: 3.w),
//       padding: EdgeInsets.all(3.w),
//       decoration: BoxDecoration(
//         color: isEarned
//             ? color.withValues(alpha: 0.1)
//             : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isEarned
//               ? color.withValues(alpha: 0.3)
//               : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(2.w),
//             decoration: BoxDecoration(
//               color: isEarned ? color : AppTheme.lightTheme.colorScheme.outline,
//               shape: BoxShape.circle,
//             ),
//             child: CustomIconWidget(
//               iconName: iconName,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//           SizedBox(height: 1.h),
//           Text(
//             title,
//             style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
//               fontWeight: FontWeight.w600,
//               color: isEarned
//                   ? AppTheme.lightTheme.colorScheme.onSurface
//                   : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           SizedBox(height: 0.5.h),
//           Text(
//             description,
//             style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
//               fontSize: 9,
//               color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }
