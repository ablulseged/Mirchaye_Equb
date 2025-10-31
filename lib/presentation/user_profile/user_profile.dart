import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import './widgets/profile_completion_bar.dart';
import './widgets/profile_section_card.dart';
import '../../appearance_section_widget.dart';
import '../../locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../login_screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

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
  bool showAppearance = false;
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
    final l10n = AppLocalizations.of(context);
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
                l10n?.edit ?? 'Change Profile Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: 'photo_camera',
                    title: l10n?.edit ?? 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.edit ?? 'Camera feature coming soon!',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildImageOption(
                    icon: 'photo_library',
                    title: l10n?.edit ?? 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.edit ?? 'Gallery feature coming soon!',
                          ),
                        ),
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
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          SizedBox(height: 1.h),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
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
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Choose an option to manage your security PIN.',
            style: Theme.of(context).textTheme.bodyMedium,
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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLocale = localeProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String selectedLocale = currentLocale;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context)?.selectLanguage ??
                    'Select Language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: selectedLocale,
                    onChanged: (value) {
                      setState(() => selectedLocale = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('አማርኛ (Amharic)'),
                    value: 'am',
                    groupValue: selectedLocale,
                    onChanged: (value) {
                      setState(() => selectedLocale = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    localeProvider.setLocale(Locale(selectedLocale));
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          selectedLocale == 'en'
                              ? 'Language changed to English'
                              : 'ቋንቋ ወደ አማርኛ ተቀይሯል',
                        ),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
                Navigator.pop(dialogContext);

                // Redirect to login and clear navigation stack
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.loginScreen,
                  (route) => false,
                );

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Logout successful'),
                    backgroundColor: AppTheme.getSuccessColorFromContext(
                      context,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getErrorColorFromContext(context),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          l10n?.profile ?? 'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleEditMode,
            icon: CustomIconWidget(
              iconName: _isEditMode ? 'check' : 'edit',
              color: theme.colorScheme.primary,
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
                                color: theme.colorScheme.primary,
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
                                color: AppTheme.getSuccessColorFromContext(
                                  context,
                                ),
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    userProfile["university"],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (userProfile["isVerified"])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'school',
                          color: AppTheme.getSuccessColorFromContext(context),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          l10n?.universityVerified ?? 'University Verified',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.getSuccessColorFromContext(context),
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
              title: l10n?.personalInformation ?? 'Personal Information',
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
              title: l10n?.universityDetails ?? 'University Details',
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
                      ? AppTheme.getSuccessColorFromContext(context)
                      : AppTheme.getWarningColorFromContext(context),
                ),
              ],
            ),

            // Equb Preferences Section
            ProfileSectionCard(
              title: l10n?.equbPreferences ?? 'Equb Preferences',
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
              title: l10n?.security ?? 'Security',
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
              title: l10n?.settings ?? 'Settings',
              children: [
                _buildActionRow(
                  l10n?.language ?? 'Language',
                  context.watch<LocaleProvider>().locale.languageCode == 'am'
                      ? 'አማርኛ'
                      : 'English',
                  'language',
                  _showLanguageDialog,
                ),
                _buildActionRow(
                  'Privacy Policy',
                  'View our privacy policy',
                  'privacy_tip',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy Policy coming soon!'),
                      ),
                    );
                  },
                ),
                _buildActionRow(
                  'Help & Support',
                  'Get help or contact support',
                  'help',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support feature coming soon!'),
                      ),
                    );
                  },
                ),

                // Appearance section (button + toggle)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            showAppearance = !showAppearance;
                          });
                        },
                        icon: const Icon(Icons.palette_outlined),
                        label: Text(
                          showAppearance
                              ? 'Hide Appearance'
                              : 'Show Appearance',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (showAppearance)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AppearanceSectionWidget(), // <- NOT const
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Logout Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context), // ✅ Pass context
                icon: CustomIconWidget(
                  iconName: 'logout',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(l10n?.logout ?? 'Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getErrorColorFromContext(context),
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
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: valueColor ?? theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
          if (isEditable && !_isEditMode)
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
