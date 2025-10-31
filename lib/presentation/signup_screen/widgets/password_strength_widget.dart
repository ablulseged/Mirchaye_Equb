import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PasswordStrengthWidget extends StatelessWidget {
  final String password;

  const PasswordStrengthWidget({Key? key, required this.password})
    : super(key: key);

  double _calculateStrength() {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    // Return normalized score (0.0 to 1.0)
    return (score / 6).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculateStrength();

    return Container(
      margin: EdgeInsets.only(top: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: AppTheme.lightTheme.textTheme.labelMedium,
              ),
              Text(
                _getStrengthText(strength),
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: _getStrengthColor(strength),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildStrengthBar(strength),
          SizedBox(height: 1.5.h),
          Text(
            'Requirements:',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          _buildRequirement('At least 8 characters', password.length >= 8),
          _buildRequirement(
            'Contains uppercase letter',
            password.contains(RegExp(r'[A-Z]')),
          ),
          _buildRequirement(
            'Contains lowercase letter',
            password.contains(RegExp(r'[a-z]')),
          ),
          _buildRequirement(
            'Contains number',
            password.contains(RegExp(r'[0-9]')),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(double score) {
    return Container(
      height: 0.8.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 0.5.w),
              decoration: BoxDecoration(
                color: index < (score * 4).round()
                    ? _getStrengthColor(score)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isMet ? 'check_circle' : 'radio_button_unchecked',
            size: 4.w,
            color: isMet
                ? AppTheme.lightTheme.colorScheme.secondary
                : AppTheme.lightTheme.colorScheme.outline,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isMet
                    ? AppTheme.lightTheme.colorScheme.onSurface
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStrengthText(double score) {
    if (score < 0.25) return 'Weak';
    if (score < 0.5) return 'Fair';
    if (score < 0.75) return 'Good';
    return 'Strong';
  }

  Color _getStrengthColor(double score) {
    if (score < 0.25) return AppTheme.lightTheme.colorScheme.error;
    if (score < 0.5) return AppTheme.lightTheme.colorScheme.tertiary;
    if (score < 0.75) return AppTheme.lightTheme.colorScheme.secondary;
    return AppTheme.lightTheme.colorScheme.secondary;
  }
}
