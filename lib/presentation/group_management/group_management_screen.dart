import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/equb_service.dart';

class GroupManagementScreen extends StatefulWidget {
  final String equbId;
  final bool? isOwnerForced; // Optional parameter to force ownership status
  const GroupManagementScreen({super.key, required this.equbId, this.isOwnerForced});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late final EqubService _equbService;

  bool? _isOwner;
  
  @override
  void initState() {
    super.initState();
    _equbService = EqubService();
    _checkOwnership();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String get _currentPeriod {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _checkOwnership() async {
    // Use forced value if provided, otherwise check ownership
    final isOwner = widget.isOwnerForced ?? await _equbService.isOwner(widget.equbId);
    setState(() {
      _isOwner = isOwner;
      final int tabLength = isOwner ? 6 : 5;
      _tabController?.dispose();
      _tabController = TabController(length: tabLength, vsync: this);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Wait for ownership check
    if (_isOwner == null || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isOwner = _isOwner!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? 'Manage Equb' : 'Group Details'),
        actions: isOwner
            ? [
                IconButton(
                  onPressed: _showAnnouncementSheet,
                  icon: const Icon(Icons.campaign_outlined),
                ),
                IconButton(
                  onPressed: _handleSpin,
                  icon: const Icon(Icons.casino_outlined),
                  tooltip: 'Spin Winner',
                ),
              ]
            : null,
        bottom: TabBar(
          controller: _tabController!,
          tabs: isOwner
              ? const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Requests'),
                  Tab(text: 'Announcements'),
                  Tab(text: 'Settings'),
                ]
              : const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Requests'),
                  Tab(text: 'Announcements'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: isOwner
            ? [
                _buildOverview(theme),
                _buildMembers(theme),
                _buildPayments(theme),
                _buildRequests(theme),
                _buildAnnouncements(theme),
                _buildSettings(theme),
              ]
            : [
                _buildOverview(theme),
                _buildMembers(theme),
                _buildPayments(theme),
                _buildRequests(theme),
                _buildAnnouncements(theme),
              ],
      ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamEqub(widget.equbId),
      builder: (context, snap) {
        final data = snap.data?.data();
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data == null) {
          return const Center(child: Text('Equb not found'));
        }
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['name'] ?? 'Untitled', style: theme.textTheme.titleLarge),
              SizedBox(height: 1.h),
              Text(data['description'] ?? ''),
              SizedBox(height: 2.h),
              Wrap(spacing: 3.w, runSpacing: 1.h, children: [
                _chip(theme, 'Contribution',
                    '${data['contributionAmount'] ?? 0} ETB'),
                _chip(theme, 'Members',
                    '${data['currentMembers'] ?? 0}/${data['maxMembers'] ?? 0}'),
                _chip(theme, 'Frequency', data['paymentFrequency'] ?? 'Monthly'),
                _chip(theme, 'Category', data['category'] ?? '-'),
              ]),
              SizedBox(height: 3.h),
              Text('Current Period: $_currentPeriod',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembers(ThemeData theme) {
    // Combine members with current period payments to display paid/unpaid
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamMembers(widget.equbId),
      builder: (context, membersSnap) {
        if (membersSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = membersSnap.data?.docs ?? [];
        if (members.isEmpty) {
          return const Center(child: Text('No members yet'));
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _equbService.streamPaymentsForPeriod(widget.equbId, _currentPeriod),
          builder: (context, paymentsSnap) {
            final payments = paymentsSnap.data?.docs ?? [];
            final paidSet = payments
                .where((p) => (p.data()['status'] ?? 'pending') == 'paid')
                .map((p) => p.data()['memberUid'] as String?)
                .whereType<String>()
                .toSet();

            return ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: members.length,
              separatorBuilder: (_, __) => SizedBox(height: 1.h),
              itemBuilder: (context, i) {
                final member = members[i];
                final data = member.data();
                final memberUid = data['uid'] ?? member.id;
                final isPaid = paidSet.contains(memberUid);
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      isPaid ? Icons.check : Icons.hourglass_bottom,
                      color: isPaid
                          ? AppTheme.getSuccessColorFromContext(context)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(data['name'] ?? data['email'] ?? memberUid ?? 'Member'),
                  subtitle: Text('Role: ${data['role'] ?? 'member'}'),
                  trailing: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPaid
                          ? AppTheme.getSuccessColorFromContext(context)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.userProfile,
                      arguments: {'userId': memberUid},
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPayments(ThemeData theme) {
    // Try reading group-level payments; if blocked, fallback to user payments filtered by group.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamPaymentsByEqub(widget.equbId),
      builder: (context, groupSnap) {
        if (groupSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (groupSnap.hasError) {
          return _buildMyPaymentsFallback(theme);
        }
        final groupDocs = groupSnap.data?.docs ?? [];
        if (groupDocs.isEmpty) {
          return _buildMyPaymentsFallback(theme);
        }
        return ListView.separated(
          padding: EdgeInsets.all(4.w),
          itemCount: groupDocs.length,
          separatorBuilder: (_, __) => SizedBox(height: 1.h),
          itemBuilder: (context, i) {
            final p = groupDocs[i].data();
            final status = (p['status'] ?? 'completed').toString();
            final payer = (p['userEmail'] as String?) ?? (p['uid'] as String?) ?? '-';
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            final currency = (p['currency'] as String?) ?? 'ETB';
            return ListTile(
              leading: Icon(
                Icons.payments,
                color: AppTheme.getSuccessColorFromContext(context),
              ),
              title: Text(payer),
              subtitle: Text('Amount: ' + amount.toStringAsFixed(2) + ' ' + currency),
              trailing: Text(
                status.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.getSuccessColorFromContext(context),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyPaymentsFallback(ThemeData theme) {
    // Fallback: show only current user's payments for this group
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamPaymentsByUser(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = (userSnap.data?.docs ?? [])
            .where((d) => (d.data()['equbId'] as String?) == widget.equbId)
            .toList();
        if (docs.isEmpty) {
          return const Center(child: Text('No payments yet'));
        }
        return ListView.separated(
          padding: EdgeInsets.all(4.w),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 1.h),
          itemBuilder: (context, i) {
            final p = docs[i].data();
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            final currency = (p['currency'] as String?) ?? 'ETB';
            final payer = (p['userEmail'] as String?) ?? (p['uid'] as String?) ?? '-';
            return ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(payer),
              subtitle: Text('Amount: ' + amount.toStringAsFixed(2) + ' ' + currency),
            );
          },
        );
      },
    );
  }

  Widget _buildRequests(ThemeData theme) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamEqub(widget.equbId),
      builder: (context, equbSnap) {
        if (equbSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final equbData = equbSnap.data?.data();
        final String? ownerUid = equbData?['ownerUid'] as String?;
        final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
        final bool isOwner = ownerUid != null && ownerUid == currentUid;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _equbService.streamJoinRequests(widget.equbId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No pending requests'));
            }
            return ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 1.h),
              itemBuilder: (context, i) {
                final req = docs[i];
                final data = req.data();
                final status = (data['status'] ?? 'pending').toString();
                return ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: Text(data['email'] ?? data['uid'] ?? req.id),
                  subtitle: Text('Status: ${status.toUpperCase()}'),
                  trailing: isOwner
                      ? (status == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await _equbService.declineJoinRequest(
                                        equbId: widget.equbId,
                                        userId: req.id,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request declined')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to decline: ${e.toString()}'),
                                          backgroundColor: theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    try {
                                      await _equbService.approveJoinRequest(
                                        equbId: widget.equbId,
                                        userId: req.id,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request approved')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to approve: ${e.toString()}'),
                                          backgroundColor: theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            )
                          : (status == 'declined'
                              ? IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Approve anyway',
                                  onPressed: () async {
                                    try {
                                      await _equbService.approveJoinRequest(
                                        equbId: widget.equbId,
                                        userId: req.id,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request approved')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to approve: ${e.toString()}'),
                                          backgroundColor: theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                                )
                              : null))
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAnnouncementSheet() {
    final controller = TextEditingController();
    String? language;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send Announcement', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your message to members...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Language:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: language,
                    hint: const Text('Default'),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'am', child: Text('Amharic')),
                    ],
                    onChanged: (v) => setState(() => language = v),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      await _equbService.addAnnouncement(
                        equbId: widget.equbId,
                        message: controller.text.trim(),
                        language: language,
                      );
                      if (mounted) Navigator.pop(context);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Announcement sent')),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSpin() async {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.spinWheel,
      arguments: {'equbId': widget.equbId},
    );
  }

  Widget _chip(ThemeData theme, String label, String value) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: theme.textTheme.labelMedium),
          Text(value, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSettings(ThemeData theme) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamEqub(widget.equbId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data?.data();
        if (data == null) {
          return const Center(child: Text('Equb not found'));
        }

        final String? ownerUid = data['ownerUid'] as String?;
        final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
        final bool isOwner = ownerUid != null && ownerUid == currentUid;
        final bool isPublic = (data['isPublic'] as bool?) ?? false;

        if (!isOwner) {
          return const Center(
            child: Text('Only group owners can access settings'),
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          children: [
            // Section: Basic Settings
            Text(
              'Basic Settings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Card(
              child: ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.primary, size: 22),
                title: const Text('Edit Group Details'),
                subtitle: const Text('Name, description, contribution'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditGroupDialog(theme, data),
                dense: true,
              ),
            ),

            SizedBox(height: 1.h),

            // Section: Financial Settings
            Text(
              'Financial Settings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary, size: 22),
                title: const Text('Manage Finances'),
                subtitle: const Text('Contribution amount, penalties, emergency fund'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFinanceDialog(theme, data),
                dense: true,
              ),
            ),

            SizedBox(height: 1.h),

            // Section: Schedule Settings
            Text(
              'Schedule Settings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Card(
              child: ListTile(
                leading: Icon(Icons.schedule, color: theme.colorScheme.primary, size: 22),
                title: const Text('Manage Schedule'),
                subtitle: const Text('Payment frequency, start date'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showScheduleDialog(theme, data),
                dense: true,
              ),
            ),

            SizedBox(height: 1.h),

            // Section: Privacy Settings
            Text(
              'Privacy',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Card(
              child: SwitchListTile(
                title: const Text('Public Group'),
                subtitle: Text(isPublic
                    ? 'Anyone can discover and join this group'
                    : 'Only people with the link can join'),
                value: isPublic,
                onChanged: (value) async {
                  try {
                    await _equbService.updateEqub(
                      equbId: widget.equbId,
                      isPublic: value,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Group is now public'
                            : 'Group is now private'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: ${e.toString()}'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
                secondary: Icon(
                  isPublic ? Icons.public : Icons.lock,
                  color: theme.colorScheme.primary,
                ),
                dense: true,
              ),
            ),

            SizedBox(height: 1.h),

            // Section: Member Management
            Text(
              'Member Management',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Card(
              child: ListTile(
                leading: Icon(Icons.people, color: theme.colorScheme.primary, size: 22),
                title: const Text('Manage Members'),
                subtitle: const Text('View and remove members'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMembersManagement(),
                dense: true,
              ),
            ),

            SizedBox(height: 2.h),

            // Section: Danger Zone
            Text(
              'Danger Zone',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 1.h),
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: theme.colorScheme.error, size: 22),
                title: Text(
                  'Delete Group',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
                subtitle: Text(
                  'Permanently delete this group and all data',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.7)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDeleteConfirmDialog(theme),
                dense: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditGroupDialog(ThemeData theme, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descController = TextEditingController(text: data['description'] ?? '');
    final amountController = TextEditingController(
        text: (data['contributionAmount'] as num?)?.toString() ?? '');
    final maxMembersController = TextEditingController(
        text: (data['maxMembers'] as num?)?.toString() ?? '');

  await showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Edit Group'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: amountController,
            decoration:
                const InputDecoration(labelText: 'Contribution Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: maxMembersController,
            decoration: const InputDecoration(labelText: 'Max Members'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () async {
          try {
            await _equbService.updateEqub(
              equbId: widget.equbId,
              name: nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()
                  : null,
              description: descController.text.trim().isNotEmpty
                  ? descController.text.trim()
                  : null,
              contributionAmount:
                  double.tryParse(amountController.text.trim()),
              maxMembers: int.tryParse(maxMembersController.text.trim()),
            );
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group updated successfully')),
            );
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update: ${e.toString()}'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  ),
);

  }

  Future<void> _showDeleteConfirmDialog(ThemeData theme) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text(
          'This will permanently delete the group and all its data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _equbService.deleteEqub(widget.equbId);
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildAnnouncements(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _equbService.streamAnnouncements(widget.equbId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data?.docs ?? [];
        
        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No announcements yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.announcementsScreen,
                      arguments: {'equbId': widget.equbId},
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('View All Announcements'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  ),
                ),
              ],
            ),
          );
        }

        // Show last 5 announcements
        final recentAnnouncements = announcements.take(5).toList();
        
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(4.w),
                itemCount: recentAnnouncements.length,
                separatorBuilder: (context, index) => SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final announcement = recentAnnouncements[index];
                  final data = announcement.data();
                  final message = data['message'] as String? ?? '';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final likeCount = data['likeCount'] as int? ?? 0;
                  
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (createdAt != null) ...[
                            SizedBox(height: 1.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 0.5.w),
                                Text(
                                  '$likeCount',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _formatTime(createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.announcementsScreen,
                      arguments: {'equbId': widget.equbId},
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('View All Announcements'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showFinanceDialog(ThemeData theme, Map<String, dynamic> data) async {
    final amountController = TextEditingController(
        text: (data['contributionAmount'] as num?)?.toString() ?? '');
    final penaltyController = TextEditingController(
        text: (data['latePenaltyPercentage'] as num?)?.toString() ?? '');
    final emergencyController = TextEditingController(
        text: (data['emergencyFundPercentage'] as num?)?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Finances'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Contribution Amount (ETB)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: penaltyController,
                decoration: const InputDecoration(labelText: 'Late Penalty (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emergencyController,
                decoration: const InputDecoration(labelText: 'Emergency Fund (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _equbService.updateEqub(
                  equbId: widget.equbId,
                  contributionAmount: double.tryParse(amountController.text.trim()),
                  latePenaltyPercentage: double.tryParse(penaltyController.text.trim()),
                  emergencyFundPercentage: double.tryParse(emergencyController.text.trim()),
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Financial settings updated')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update: ${e.toString()}'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleDialog(ThemeData theme, Map<String, dynamic> data) async {
    final frequencyController = TextEditingController(text: data['paymentFrequency'] ?? '');
    final startDateController = TextEditingController(
        text: data['startDate'] != null ? data['startDate'].toDate().toString().split(' ').first : '');
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(labelText: 'Payment Frequency (e.g., Monthly, Weekly)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Start Date'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    startDateController.text = date.toString().split(' ').first;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _equbService.updateEqub(
                  equbId: widget.equbId,
                  paymentFrequency: frequencyController.text.trim().isNotEmpty
                      ? frequencyController.text.trim()
                      : null,
                  startDate: selectedDate,
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Schedule updated')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update: ${e.toString()}'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMembersManagement() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 50.h,
          child: StreamBuilder(
            stream: _equbService.streamMembers(widget.equbId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data?.docs ?? [];
              if (members.isEmpty) {
                return const Center(child: Text('No members yet'));
              }

              return ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberData = member.data();
                  final memberUid = memberData['uid'] ?? member.id;
                  final isOwner = memberData['role'] == 'owner';
                  final memberName = memberData['name'] ?? memberData['email'] ?? 'Unknown';

                  // Don't allow removing the owner
                  if (isOwner) {
                    return ListTile(
                      title: Text(memberName),
                      subtitle: const Text('Owner'),
                      leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                      dense: true,
                    );
                  }

                  return ListTile(
                    title: Text(memberName),
                    subtitle: const Text('Member'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Member?'),
                            content: Text('Remove $memberName from this group?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await _equbService.removeMember(
                              equbId: widget.equbId,
                              memberUid: memberUid,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member removed')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to remove: ${e.toString()}'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    dense: true,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}


