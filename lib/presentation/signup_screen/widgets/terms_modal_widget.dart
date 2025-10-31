import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TermsModalWidget extends StatelessWidget {
  const TermsModalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Terms and Conditions',
                        style: AppTheme.lightTheme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'close',
                        size: 6.w,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Welcome to Equb App',
                    'By creating an account and using our services, you agree to be bound by these Terms and Conditions. Please read them carefully.',
                  ),
                  _buildSection(
                    '1. Equb Platform Services',
                    'Our platform digitizes traditional Ethiopian rotating savings and credit associations (Equb). We provide secure member management, financial transaction tracking, and community lending coordination services.',
                  ),
                  _buildSection(
                    '2. User Responsibilities',
                    '• Provide accurate and truthful information during registration\n• Maintain the confidentiality of your account credentials\n• Use biometric authentication responsibly\n• Report any suspicious activities immediately\n• Comply with all applicable Ethiopian financial regulations',
                  ),
                  _buildSection(
                    '3. Financial Compliance',
                    'This application complies with Ethiopian financial regulations and banking laws. All transactions are monitored for compliance with local financial authorities. Users must ensure their participation in Equb activities complies with local laws.',
                  ),
                  _buildSection(
                    '4. Data Security & Privacy',
                    '• Your personal and financial data is encrypted and stored securely\n• Biometric data is stored locally on your device only\n• We use SSL encryption for all data transmission\n• Your information will never be shared without consent\n• You can request data deletion at any time',
                  ),
                  _buildSection(
                    '5. Account Security',
                    '• Enable biometric authentication for enhanced security\n• Use strong passwords with mixed characters\n• Never share your login credentials\n• Log out from shared devices\n• Report compromised accounts immediately',
                  ),
                  _buildSection(
                    '6. Equb Group Participation',
                    'Participation in Equb groups involves financial commitments. Users are responsible for understanding the terms of each Equb group they join and fulfilling their financial obligations.',
                  ),
                  _buildSection(
                    '7. Limitation of Liability',
                    'While we strive to provide secure and reliable services, users participate in Equb activities at their own risk. The platform facilitates but does not guarantee financial outcomes.',
                  ),
                  _buildSection(
                    '8. Updates to Terms',
                    'These terms may be updated periodically. Users will be notified of significant changes and continued use constitutes acceptance of updated terms.',
                  ),
                  _buildSection(
                    '9. Contact Information',
                    'For questions about these terms or our services, please contact our support team through the app or visit our website.',
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'security',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'Your security and privacy are our top priorities. We are committed to protecting your financial information.',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
