import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_export.dart';
import './widgets/profile_completion_bar.dart';
import './widgets/profile_section_card.dart';
import '../../appearance_section_widget.dart';
import '../../locale_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/biometric_service.dart';
import '../../services/password_service.dart';
import '../../routes/app_routes.dart';
import 'package:share_plus/share_plus.dart';

class UserProfile extends StatefulWidget {
  final String? userId;
  const UserProfile({Key? key, this.userId}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isEditMode = false;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _paymentReminders = true;
  bool showAppearance = false;
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  final _biometricService = BiometricService();
  final _passwordService = PasswordService();
  bool get _isViewingOwnProfile => widget.userId == null;
  bool get _isCurrentUserOwner =>
      _isViewingOwnProfile || widget.userId == _auth.currentUser?.uid;
  // Mock user profile data
  Map<String, dynamic> userProfile = {
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

  @override
  void initState() {
    super.initState();
    // Load biometric preference from secure storage
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enabled = await _biometricService.getBiometricEnabled();
      if (mounted) setState(() => _biometricEnabled = enabled);
    });
  }

  /// Handle enabling/disabling biometric sign-in. When enabling we ask the
  /// user for credentials which we store securely on-device (not uploaded
  /// to any server). When disabling we clear any stored credentials.
  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      // Prompt the user to enter credentials to store locally.
      final emailController = TextEditingController(
        text: _auth.currentUser?.email ?? '',
      );
      final passwordController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Enable Biometric Login'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                  enabled: false,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Enable'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        final email = emailController.text.trim();
        final password = passwordController.text;
        if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email and password are required')),
          );
          return;
        }

        // Store credentials on-device and enable preference
        await _biometricService.storeCredentials(
          email: email,
          password: password,
        );
        await _biometricService.setBiometricEnabled(true);
        if (mounted) setState(() => _biometricEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication enabled')),
        );
      }
    } else {
      // Disable biometric and clear stored credentials
      await _biometricService.setBiometricEnabled(false);
      await _biometricService.clearStoredCredentials();
      if (mounted) setState(() => _biometricEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication disabled')),
      );
    }
  }

  /// Flow to change existing password or set a new one if none exists
  Future<void> _changePasswordFlow() async {
    // Change password via Firebase (reauthenticate then updatePassword)
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to change your password.'),
        ),
      );
      return;
    }

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                obscureText: true,
              ),
              TextField(
                controller: newController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final currentPwd = currentController.text.trim();
    final newPassword = newController.text.trim();
    final confirmPassword = confirmController.text.trim();
    if (newPassword.isEmpty || newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPwd,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      // Clear any locally stored password since Firebase is authoritative
      await _passwordService.clearPassword();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to change password.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential')
        msg = 'Incorrect password, please try again.';
      if (e.code == 'requires-recent-login')
        msg = 'Please sign in again to change your password.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to change password. Please try again.'),
        ),
      );
    }
  }

  /// Reset Password: prefer biometric verification when available, otherwise
  /// reauthenticate using Firebase credentials. On success allow setting a new password.
  Future<void> _resetPasswordFlow() async {
    // Use Firebase 'forgot password' behavior: send a password reset email
    final user = _auth.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email available for this account.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send password reset email.')),
      );
    }
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
                      _pickImageFromCamera();
                    },
                  ),
                  _buildImageOption(
                    icon: 'photo_library',
                    title: l10n?.edit ?? 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
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

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImageToCloudinary(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImageToCloudinary(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImageToCloudinary(String filePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final userId = _auth.currentUser?.uid ?? 'unknown';

      // Upload to Cloudinary
      final imageUrl = await CloudinaryService.uploadImage(
        filePath: filePath,
        publicId: 'profile_$userId',
      );

      // Update Firestore
      await _userService.updatePhotoUrl(imageUrl);

      // Update local state
      setState(() {
        userProfile['avatarUrl'] = imageUrl;
      });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
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

  void _showPasswordManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Password Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Choose an option to manage your account password.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _changePasswordFlow();
              },
              child: Text('Change Password'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetPasswordFlow();
              },
              child: Text('Reset Password'),
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

  void _showPrivacyPolicyDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'privacy_tip',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              const Text('Privacy Policy'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'We respect your privacy and are committed to protecting your personal information. '
                  'Your data is securely stored and only used to provide you with the best experience.',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 3.h),
                Divider(),
                SizedBox(height: 2.h),
                Text(
                  'Data Management',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'You have full control over your account data. You can delete your account at any time, '
                  'which will permanently remove all your personal information from our servers.',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 3.h),
                // Delete Account Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 2.h),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showDeleteAccountConfirmation();
                    },
                    icon: CustomIconWidget(
                      iconName: 'delete_forever',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: theme.colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 2.w),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              const Text(
                'This action cannot be undone. All your data will be permanently deleted, including:',
              ),
              SizedBox(height: 1.h),
              const Text('• Your profile information'),
              const Text('• Your group memberships'),
              const Text('• Your payment history'),
              const Text('• Your notifications'),
              SizedBox(height: 2.h),
              Text(
                'You will be signed out and redirected to the login screen.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _handleDeleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    final theme = Theme.of(context);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete account
      await _userService.deleteAccount();

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your account has been deleted successfully'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    try {
      final shareText =
          'Check out Mirchaye Equb - A great app for managing Equb groups! '
          'Download it now and join our community.';

      await Share.share(shareText, subject: 'Mirchaye Equb - Download Now');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share app: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 80.h),
            padding: EdgeInsets.all(4.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'About Mirchaye Equb',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Divider(),
                  SizedBox(height: 2.h),

                  // App Version
                  Text(
                    'Version 1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // About App
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Mirchaye Equb is a comprehensive mobile application designed for managing Equb groups. '
                    'Equb is a traditional rotating savings and credit association where members contribute '
                    'money regularly and take turns receiving the pooled amount.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 3.h),

                  // How to Use
                  Text(
                    'How to Use the App',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildManualItem(
                    theme,
                    '1. Create or Join Groups',
                    'Create your own Equb group or browse and join existing groups. Set contribution amounts, member limits, and payment frequency.',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildManualItem(
                    theme,
                    '2. Manage Members',
                    'Invite members, approve join requests, and manage your group members. Track member contributions and participation.',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildManualItem(
                    theme,
                    '3. Make Payments',
                    'Record contributions and track payment history. Set up payment reminders and monitor due dates.',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildManualItem(
                    theme,
                    '4. Spin Wheel',
                    'Use the spin wheel feature to randomly select winners for the Equb round. Fair and transparent selection process.',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildManualItem(
                    theme,
                    '5. Announcements',
                    'Create announcements to communicate with group members. Share important updates and information.',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildManualItem(
                    theme,
                    '6. Notifications',
                    'Receive real-time notifications about group activities, payment reminders, and important updates.',
                  ),
                  SizedBox(height: 3.h),
                  Divider(),
                  SizedBox(height: 2.h),

                  // Developers
                  Text(
                    'Developed By',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildDeveloperCard(
                    theme,
                    'Daniel Lulseged',
                    'Lead Developer',
                    Icons.person,
                  ),
                  SizedBox(height: 1.5.h),
                  _buildDeveloperCard(
                    theme,
                    'Kidus Mathewos',
                    'Co-Developer',
                    Icons.person,
                  ),
                  SizedBox(height: 3.h),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualItem(ThemeData theme, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 0.5.h, right: 2.w),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(
    ThemeData theme,
    String name,
    String role,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          if (_isViewingOwnProfile)
            IconButton(
              onPressed: _toggleEditMode,
              icon: CustomIconWidget(
                iconName: _isEditMode ? 'check' : 'edit',
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          if (_isViewingOwnProfile) SizedBox(width: 2.w),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: widget.userId != null
            ? _userService.streamUser(widget.userId!)
            : _userService.streamCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final docData = snapshot.data!.data();
            if (docData != null) {
              userProfile["name"] =
                  docData['displayName'] ?? userProfile["name"];
              userProfile["phone"] = docData['phone'] ?? userProfile["phone"];
              userProfile["email"] =
                  docData['email'] ??
                  (widget.userId == null ? _auth.currentUser?.email : '') ??
                  userProfile["email"];
              userProfile["avatarUrl"] =
                  docData['photoUrl'] ?? userProfile["avatarUrl"];
              userProfile["university"] =
                  docData['university'] ?? userProfile["university"];
              userProfile["studentId"] =
                  docData['studentId'] ?? userProfile["studentId"];
            }
          }

          return SingleChildScrollView(
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
                              backgroundImage:
                                  (userProfile["avatarUrl"] != null &&
                                      userProfile["avatarUrl"]
                                          .toString()
                                          .isNotEmpty)
                                  ? NetworkImage(userProfile["avatarUrl"])
                                  : null,
                              child:
                                  (userProfile["avatarUrl"] == null ||
                                      userProfile["avatarUrl"]
                                          .toString()
                                          .isEmpty)
                                  ? Text(
                                      (userProfile["name"] ?? 'U')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    )
                                  : null,
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
                              color: AppTheme.getSuccessColorFromContext(
                                context,
                              ),
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              l10n?.universityVerified ?? 'University Verified',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.getSuccessColorFromContext(
                                  context,
                                ),
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
                      'Password Management',
                      'Change or reset your account password',
                      'lock',
                      _showPasswordManagementDialog,
                    ),
                    _buildSwitchRow(
                      'Biometric Authentication',
                      'Use fingerprint or face unlock',
                      'fingerprint',
                      _biometricEnabled,
                      (value) async {
                        await _handleBiometricToggle(value);
                      },
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
                      context.watch<LocaleProvider>().locale.languageCode ==
                              'am'
                          ? 'አማርኛ'
                          : 'English',
                      'language',
                      _showLanguageDialog,
                    ),
                    _buildActionRow(
                      'Privacy Policy',
                      'View our privacy policy',
                      'privacy_tip',
                      _showPrivacyPolicyDialog,
                    ),
                    _buildActionRow(
                      'Share App',
                      'Share this app with friends',
                      'share',
                      _shareApp,
                    ),
                    _buildActionRow(
                      'About',
                      'About this app and developers',
                      'info',
                      _showAboutDialog,
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
                if (_isViewingOwnProfile)
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showLogoutDialog(context), // ✅ Pass context
                      icon: CustomIconWidget(
                        iconName: 'logout',
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(l10n?.logout ?? 'Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.getErrorColorFromContext(
                          context,
                        ),
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
          );
        },
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
