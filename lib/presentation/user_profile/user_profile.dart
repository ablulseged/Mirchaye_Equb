import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
// import './widgets/achievement_badge.dart';
import 'widgets/balance_display_card.dart';
import './widgets/profile_completion_bar.dart';
import './widgets/profile_section_card.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isEditMode = false;
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;
  bool _paymentReminders = true;

  // Mock user profile data
  final Map<String, dynamic> userProfile = {
    "id": 1,
    "name": "Abebe Kebede",
    "phone": "+251912345678",
    "email": "abebe.kebede@wcu.edu.et",
    "university": "Wachemo University",
    "studentId": "WCU/CSE/2023/001",
    "isVerified": true,
    "profileCompleteness": 85,
    "balance": "12,450.00",
    "avatarUrl":
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
    "joinDate": "2023-09-15",
    "totalEqubs": 3,
    "completedEqubs": 1,
  };

  // Mock achievements data
  final List<Map<String, dynamic>> achievements = [
    {
      "id": 1,
      "title": "First Timer",
      "description": "Joined your first Equb group",
      "iconName": "star",
      "color": Color(0xFFFFD700),
      "earned": true,
    },
    {
      "id": 2,
      "title": "Trustworthy",
      "description": "Perfect payment record for 6 months",
      "iconName": "verified",
      "color": Color(0xFF2E7D32),
      "earned": true,
    },
    {
      "id": 3,
      "title": "Leader",
      "description": "Successfully managed an Equb group",
      "iconName": "groups",
      "color": Color(0xFF6F35A5),
      "earned": false,
    },
  ];

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: 'photo_camera',
                    title: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Camera feature coming soon!')),
                      );
                    },
                  ),
                  _buildImageOption(
                    icon: 'photo_library',
                    title: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gallery feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 3.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 32,
            ),
          ),
          SizedBox(height: 1.h),
          Text(title, style: AppTheme.lightTheme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showPinManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'PIN Management',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Choose an option to manage your security PIN.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Change PIN'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Reset PIN'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Language',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                leading: Radio(value: 'en', groupValue: 'en', onChanged: null),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: Text('አማርኛ (Amharic)'),
                leading: Radio(value: 'am', groupValue: 'en', onChanged: null),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout successful'),
                    backgroundColor: AppTheme.getSuccessColor(true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getErrorColor(true),
              ),
              child: Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleEditMode,
            icon: CustomIconWidget(
              iconName: _isEditMode ? 'check' : 'edit',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditMode ? _showImagePicker : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            userProfile["avatarUrl"],
                          ),
                        ),
                        if (_isEditMode)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'edit',
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        if (userProfile["isVerified"])
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.getSuccessColor(true),
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'verified',
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    userProfile["name"],
                    style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    userProfile["university"],
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (userProfile["isVerified"])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'school',
                          color: AppTheme.getSuccessColor(true),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'University Verified',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.getSuccessColor(true),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Profile Completion
            ProfileCompletionBar(
              completionPercentage: userProfile["profileCompleteness"],
            ),

            // Balance Display
            // BalanceDisplayCard(balance: userProfile["balance"]),

            // Personal Information Section
            ProfileSectionCard(
              title: 'Personal Information',
              children: [
                _buildInfoRow(
                  'Full Name',
                  userProfile["name"],
                  'person',
                  isEditable: true,
                ),
                _buildInfoRow(
                  'Phone Number',
                  userProfile["phone"],
                  'phone',
                  isEditable: true,
                ),
                _buildInfoRow(
                  'Email Address',
                  userProfile["email"],
                  'email',
                  isEditable: true,
                ),
              ],
            ),

            // University Details Section
            ProfileSectionCard(
              title: 'University Details',
              children: [
                _buildInfoRow(
                  'Institution',
                  userProfile["university"],
                  'school',
                  isEditable: false,
                ),
                _buildInfoRow(
                  'Student ID',
                  userProfile["studentId"],
                  'badge',
                  isEditable: false,
                ),
                _buildInfoRow(
                  'Verification Status',
                  userProfile["isVerified"] ? 'Verified' : 'Pending',
                  'verified',
                  isEditable: false,
                  valueColor: userProfile["isVerified"]
                      ? AppTheme.getSuccessColor(true)
                      : AppTheme.getWarningColor(true),
                ),
              ],
            ),

            // Equb Preferences Section
            ProfileSectionCard(
              title: 'Equb Preferences',
              children: [
                _buildSwitchRow(
                  'Notifications',
                  'Get notified about Equb activities',
                  'notifications',
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildSwitchRow(
                  'Payment Reminders',
                  'Receive payment due reminders',
                  'schedule',
                  _paymentReminders,
                  (value) => setState(() => _paymentReminders = value),
                ),
              ],
            ),

            // Security Section
            ProfileSectionCard(
              title: 'Security',
              children: [
                _buildActionRow(
                  'PIN Management',
                  'Change or reset your security PIN',
                  'lock',
                  _showPinManagementDialog,
                ),
                _buildSwitchRow(
                  'Biometric Authentication',
                  'Use fingerprint or face unlock',
                  'fingerprint',
                  _biometricEnabled,
                  (value) => setState(() => _biometricEnabled = value),
                ),
              ],
            ),

            // Achievement Badges Section

            // Settings Section
            ProfileSectionCard(
              title: 'Settings',
              children: [
                _buildActionRow(
                  'Language',
                  'አማርኛ / English',
                  'language',
                  _showLanguageDialog,
                ),
                _buildActionRow(
                  'Privacy Policy',
                  'View our privacy policy',
                  'privacy_tip',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privacy Policy coming soon!')),
                    );
                  },
                ),
                _buildActionRow(
                  'Help & Support',
                  'Get help or contact support',
                  'help',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Support feature coming soon!')),
                    );
                  },
                ),
              ],
            ),

            // Logout Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: CustomIconWidget(
                  iconName: 'logout',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getErrorColor(true),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
    String iconName, {
    bool isEditable = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                _isEditMode && isEditable
                    ? TextFormField(
                        initialValue: value,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color:
                                  valueColor ??
                                  AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
              ],
            ),
          ),
          if (isEditable && !_isEditMode)
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String description,
    String iconName,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String title,
    String description,
    String iconName,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
