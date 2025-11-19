import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/equb_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: notificationService.streamNotifications(),
            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data?.docs.where((doc) {
                    final data = doc.data();
                    return (data['isRead'] as bool? ?? false) == false;
                  }).length ??
                  0;
              return IconButton(
                onPressed: unreadCount > 0
                    ? () async {
                        await notificationService.markAllAsRead();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationService.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Error loading notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          // Sort by createdAt descending (most recent first)
          notifications.sort((a, b) {
            final createdAtA = a.data()['createdAt'] as Timestamp?;
            final createdAtB = b.data()['createdAt'] as Timestamp?;
            if (createdAtA == null && createdAtB == null) return 0;
            if (createdAtA == null) return 1;
            if (createdAtB == null) return -1;
            return createdAtB.compareTo(createdAtA);
          });

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'notifications_none',
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'You\'re all caught up!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Stream will automatically update
            },
            child: ListView.separated(
              padding: EdgeInsets.all(2.w),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final data = notification.data();
                return _buildNotificationCard(
                  context,
                  theme,
                  notification.id,
                  data,
                  notificationService,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    ThemeData theme,
    String notificationId,
    Map<String, dynamic> data,
    NotificationService notificationService,
  ) {
    final isRead = data['isRead'] as bool? ?? false;
    final title = data['title'] as String? ?? 'Notification';
    final message = data['message'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final createdAt = data['createdAt'] as Timestamp?;

    // Get icon and color based on type
    String iconName = 'notifications';
    Color iconColor = theme.colorScheme.primary;

    switch (type) {
      case 'payment':
        iconName = 'payment';
        iconColor = const Color(0xFF2E7D32);
        break;
      case 'join_request':
        iconName = 'person_add';
        iconColor = const Color(0xFF6F35A5);
        break;
      case 'spin_winner':
        iconName = 'check_circle';
        iconColor = const Color(0xFF2E7D32);
        break;
      case 'general':
        iconName = 'campaign';
        iconColor = const Color(0xFF6F35A5);
        break;
    }

    final equbId = data['equbId'] as String?;
    final announcementId =
        (data['data'] as Map<String, dynamic>?)?['announcementId'] as String? ??
        data['announcementId'] as String?;

    return Card(
      color: isRead
          ? null
          : theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await notificationService.markAsRead(notificationId);
          }

          // If this notification references an announcement, open a dialog to add a comment specific to this notification
          if (equbId != null && announcementId != null) {
            final TextEditingController _input = TextEditingController();
            final posted = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Add comment'),
                  content: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write your comment...',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final text = _input.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await EqubService().addAnnouncementComment(
                            equbId: equbId,
                            announcementId: announcementId,
                            message: text,
                            parentCommentId: null,
                          );
                          Navigator.pop(context, true);
                        } catch (e) {
                          Navigator.pop(context, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to post comment: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Post'),
                    ),
                  ],
                );
              },
            );

            if (posted == true) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Comment posted')));
            }
          } else {
            // Otherwise, no announcement to comment on - optionally navigate to notifications details
          }
        },
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: iconColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            _formatTime(createdAt.toDate()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    // If this notification references an announcement, show the latest comment (if any)
                    if (equbId != null && announcementId != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: EqubService().streamAnnouncementComments(
                          equbId: equbId,
                          announcementId: announcementId,
                        ),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return Text(
                              message,
                              style: theme.textTheme.bodyMedium,
                            );
                          }
                          final docs = snap.data?.docs ?? [];
                          if (docs.isNotEmpty) {
                            final latest = docs.last.data();
                            final latestMsg =
                                latest['message'] as String? ?? message;
                            return Text(
                              latestMsg,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return Text(
                            message,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      )
                    else
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
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
}
