import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_export.dart';
import '../../services/equb_service.dart';
import '../../services/user_service.dart';

class AnnouncementsScreen extends StatelessWidget {
  final String equbId;
  const AnnouncementsScreen({Key? key, required this.equbId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final equbService = EqubService();
    final userService = UserService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: equbService.streamAnnouncements(equbId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading announcements: ${snapshot.error}'),
            );
          }

          final announcements = snapshot.data?.docs ?? [];
          
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'campaign',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No announcements yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: announcements.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final data = announcement.data();
              final message = data['message'] as String? ?? '';
              final senderUid = data['senderUid'] as String? ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final likeCount = data['likeCount'] as int? ?? 0;
              final likedBy = List<String>.from(data['likedBy'] ?? []);
              final isLiked = currentUser != null && likedBy.contains(currentUser.uid);

              return StreamBuilder(
                stream: userService.streamUser(senderUid),
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data();
                  final senderName = userData?['displayName'] as String? ?? userData?['email'] as String? ?? 'Unknown';
                  final senderPhotoUrl = userData?['photoUrl'] as String?;

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
                          // Sender info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: senderPhotoUrl != null && senderPhotoUrl.isNotEmpty
                                    ? NetworkImage(senderPhotoUrl)
                                    : null,
                                child: senderPhotoUrl == null || senderPhotoUrl.isEmpty
                                    ? Text(senderName.substring(0, 1).toUpperCase())
                                    : null,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      senderName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (createdAt != null)
                                      Text(
                                        _formatDate(createdAt),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          // Message
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 2.h),
                          // Like button
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await equbService.toggleLike(
                                      equbId: equbId,
                                      announcementId: announcement.id,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to toggle like: ${e.toString()}'),
                                          backgroundColor: theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '$likeCount',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
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

