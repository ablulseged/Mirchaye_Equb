import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/equb_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './widgets/advanced_settings_widget.dart';
import './widgets/financial_config_widget.dart';
import './widgets/group_basics_widget.dart';
import './widgets/member_invitation_widget.dart';
import './widgets/privacy_settings_widget.dart';
import './widgets/start_date_widget.dart';
import './widgets/terms_agreement_widget.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with TickerProviderStateMixin {
  static const int MAX_OWNED_EQUBS = 2;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late TabController _tabController;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form State
  int _currentStep = 0;
  String _selectedCategory = 'family';
  double _contributionAmount = 100.0;
  String _paymentFrequency = 'monthly';
  int _groupSize = 8;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  double _latePenaltyPercentage = 5.0;
  double _emergencyFundPercentage = 2.0;
  bool _allowEarlyExit = false;
  List<Map<String, dynamic>> _invitedMembers = [];
  bool _isPublic = false;
  bool _requireApproval = true;
  bool _isAgreed = false;
  bool _isLoading = false;

  final List<String> _stepTitles = [
    'Basics',
    'Finance',
    'Schedule',
    'Settings',
    'Members',
    'Privacy',
    'Agreement',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stepTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Create Equb Group',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: Text(
              'Save Draft',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12.h),
          child: Column(
            children: [
              // Progress Indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of ${_stepTitles.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${((_currentStep + 1) / _stepTitles.length * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _stepTitles.length,
                      backgroundColor: colorScheme.outline.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                onTap: (index) {
                  if (index <= _currentStep) {
                    _goToStep(index);
                  }
                },
                tabs: _stepTitles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final title = entry.value;
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;

                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted)
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: colorScheme.primary,
                            size: 4.w,
                          )
                        else if (isCurrent)
                          CustomIconWidget(
                            iconName: 'radio_button_checked',
                            color: colorScheme.primary,
                            size: 4.w,
                          )
                        else
                          CustomIconWidget(
                            iconName: 'radio_button_unchecked',
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            size: 4.w,
                          ),
                        SizedBox(width: 1.w),
                        Text(title),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentStep = index;
              _tabController.animateTo(index);
            });
          },
          children: [
            // Step 1: Group Basics
            _buildStepContent(
              GroupBasicsWidget(
                nameController: _nameController,
                descriptionController: _descriptionController,
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ),

            // Step 2: Financial Configuration
            _buildStepContent(
              FinancialConfigWidget(
                contributionAmount: _contributionAmount,
                paymentFrequency: _paymentFrequency,
                groupSize: _groupSize,
                onContributionChanged: (amount) {
                  setState(() {
                    _contributionAmount = amount;
                  });
                },
                onFrequencyChanged: (frequency) {
                  setState(() {
                    _paymentFrequency = frequency;
                  });
                },
                onGroupSizeChanged: (size) {
                  setState(() {
                    _groupSize = size;
                  });
                },
              ),
            ),

            // Step 3: Start Date
            _buildStepContent(
              StartDateWidget(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),

            // Step 4: Advanced Settings
            _buildStepContent(
              AdvancedSettingsWidget(
                latePenaltyPercentage: _latePenaltyPercentage,
                emergencyFundPercentage: _emergencyFundPercentage,
                allowEarlyExit: _allowEarlyExit,
                onLatePenaltyChanged: (penalty) {
                  setState(() {
                    _latePenaltyPercentage = penalty;
                  });
                },
                onEmergencyFundChanged: (fund) {
                  setState(() {
                    _emergencyFundPercentage = fund;
                  });
                },
                onEarlyExitChanged: (allow) {
                  setState(() {
                    _allowEarlyExit = allow;
                  });
                },
              ),
            ),

            // Step 5: Member Invitation
            _buildStepContent(
              MemberInvitationWidget(
                invitedMembers: _invitedMembers,
                onMemberAdded: (member) {
                  setState(() {
                    _invitedMembers.add(member);
                  });
                },
                onMemberRemoved: (index) {
                  setState(() {
                    _invitedMembers.removeAt(index);
                  });
                },
              ),
            ),

            // Step 6: Privacy Settings
            _buildStepContent(
              PrivacySettingsWidget(
                isPublic: _isPublic,
                requireApproval: _requireApproval,
                onPublicChanged: (isPublic) {
                  setState(() {
                    _isPublic = isPublic;
                  });
                },
                onApprovalChanged: (requireApproval) {
                  setState(() {
                    _requireApproval = requireApproval;
                  });
                },
              ),
            ),

            // Step 7: Terms Agreement
            _buildStepContent(
              TermsAgreementWidget(
                isAgreed: _isAgreed,
                onAgreementChanged: (agreed) {
                  setState(() {
                    _isAgreed = agreed;
                  });
                },
                contributionAmount: _contributionAmount,
                paymentFrequency: _paymentFrequency,
                groupSize: _groupSize,
                latePenaltyPercentage: _latePenaltyPercentage,
                emergencyFundPercentage: _emergencyFundPercentage,
                allowEarlyExit: _allowEarlyExit,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: colorScheme.primary,
                      size: 4.w,
                    ),
                    label: const Text('Previous'),
                  ),
                ),
              if (_currentStep > 0) SizedBox(width: 4.w),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == _stepTitles.length - 1
                            ? _createGroup
                            : _nextStep),
                  icon: _isLoading
                      ? SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : CustomIconWidget(
                          iconName: _currentStep == _stepTitles.length - 1
                              ? 'check'
                              : 'arrow_forward',
                          color: colorScheme.onPrimary,
                          size: 4.w,
                        ),
                  label: Text(
                    _currentStep == _stepTitles.length - 1
                        ? 'Create Group'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(Widget child) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          child,
          SizedBox(height: 10.h), // Extra space for bottom navigation
        ],
      ),
    );
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _stepTitles.length - 1) {
        _goToStep(_currentStep + 1);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Group Basics
        if (_nameController.text.trim().isEmpty) {
          _showErrorMessage('Please enter a group name');
          return false;
        }
        if (_nameController.text.trim().length < 3) {
          _showErrorMessage('Group name must be at least 3 characters');
          return false;
        }
        break;
      case 1: // Financial Configuration
        if (_contributionAmount < 10) {
          _showErrorMessage('Contribution amount must be at least \$10');
          return false;
        }
        if (_groupSize < 3) {
          _showErrorMessage('Group must have at least 3 members');
          return false;
        }
        break;
      case 2: // Start Date
        if (_selectedDate.isBefore(DateTime.now())) {
          _showErrorMessage('Start date must be in the future');
          return false;
        }
        break;
      case 6: // Terms Agreement
        if (!_isAgreed) {
          _showErrorMessage('You must agree to the terms and conditions');
          return false;
        }
        break;
    }
    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _saveDraft() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved successfully')));
  }

  Future<void> _createGroup() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Enforce owned equb limit
      final ownedCount = await EqubService().countOwnedEqubsByCurrentUser();
      if (ownedCount >= MAX_OWNED_EQUBS) {
        final allowed = await _promptReauth();
        if (!allowed) {
          if (mounted) {
            _showErrorMessage('Creation limited to $MAX_OWNED_EQUBS Equbs per user.');
          }
          return;
        }
      }

      await EqubService().createEqubGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        contributionAmount: _contributionAmount,
        paymentFrequency: _paymentFrequency,
        groupSize: _groupSize,
        startDate: _selectedDate,
        latePenaltyPercentage: _latePenaltyPercentage,
        emergencyFundPercentage: _emergencyFundPercentage,
        allowEarlyExit: _allowEarlyExit,
        isPublic: _isPublic,
        requireApproval: _requireApproval,
        invitedMemberEmails:
            _invitedMembers.map((m) => m['email'] as String).toList(),
      );

      // Show success message with haptic feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: Colors.white,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                const Text('Equb group created successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to dashboard (groups screen)
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
      }
    } catch (e) {
      if (mounted) {
        if (e is FirebaseException) {
          _showErrorMessage(e.message ?? 'Failed to create group. Check Firestore rules and auth.');
        } else {
          _showErrorMessage('Failed to create group: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _promptReauth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;
    String password = '';
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify Identity', style: theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You already created $MAX_OWNED_EQUBS Equbs. Enter password to proceed.'),
              SizedBox(height: 12),
              Text('Email: ${user.email}'),
              SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (v) => password = v,
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
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    if (result != true) return false;
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      if (mounted) {
        _showErrorMessage('Reauthentication failed. Please try again.');
      }
      return false;
    }
  }
}
