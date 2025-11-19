import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_export.dart';
import '../../services/equb_service.dart';
import '../../services/user_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String equbId;
  const AnnouncementsScreen({Key? key, required this.equbId}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final EqubService _equbService = EqubService();
  bool _isOwner = false;
  bool _isCheckingOwner = true;
  final Map<String, bool> _commentsExpanded = {};
  final Map<String, String?> _replyTo = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkOwnership() async {
    final isOwner = await _equbService.isOwner(widget.equbId);
    setState(() {
      _isOwner = isOwner;
      _isCheckingOwner = false;
    });
  }

  void _handleSpin() {
    // Navigate to spin wheel screen for all users
    // The spin wheel screen will handle restricting spin functionality to owners only
    Navigator.pushNamed(
      context,
      AppRoutes.spinWheel,
      arguments: {'equbId': widget.equbId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        elevation: 0,
        actions: [
          // Spin icon - clickable for all users
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: const Icon(Icons.casino_outlined),
              onPressed: _isCheckingOwner ? null : _handleSpin,
              tooltip: _isCheckingOwner ? 'Loading...' : 'Spin Wheel',
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _equbService.streamAnnouncements(widget.equbId),
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
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final likedBy = List<String>.from(data['likedBy'] ?? []);
              final likeCount = data['likeCount'] as int? ?? likedBy.length;
              final currentUserId =
                  FirebaseAuth.instance.currentUser?.uid ?? '';
              final isLiked = likedBy.contains(currentUserId);

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
                      // Message
                      Text(message, style: theme.textTheme.bodyMedium),
                      SizedBox(height: 2.h),
                      // Like button and timestamp row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Timestamp
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          // Like button
                          InkWell(
                            onTap: () async {
                              print(
                                'Like button tapped for announcement: ${announcement.id}',
                              );
                              try {
                                await _equbService.toggleLike(
                                  equbId: widget.equbId,
                                  announcementId: announcement.id,
                                );
                                print('Like toggled successfully');
                              } catch (e) {
                                print('Error toggling like: $e');
                                if (mounted &&
                                    ScaffoldMessenger.maybeOf(context) !=
                                        null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to toggle like: ${e.toString()}',
                                      ),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 1.h,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? Colors.red
                                        : theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    likeCount.toString(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Comments toggle
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _commentsExpanded[announcement.id] =
                                    !(_commentsExpanded[announcement.id] ??
                                        false);
                                if (_commentsExpanded[announcement.id] ==
                                    true) {
                                  // Reset reply target when opening
                                  _replyTo[announcement.id] = null;
                                }
                              });
                            },
                            icon: const Icon(Icons.comment_outlined),
                            tooltip: 'Comments',
                          ),
                        ],
                      ),
                      // Comments area (expandable)
                      if (_commentsExpanded[announcement.id] ?? false)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Column(
                            children: [
                              StreamBuilder(
                                stream: _equbService.streamAnnouncementComments(
                                  equbId: widget.equbId,
                                  announcementId: announcement.id,
                                ),
                                builder: (context, commentsSnap) {
                                  if (commentsSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final docs = commentsSnap.data?.docs ?? [];
                                  if (docs.isEmpty) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'No comments yet',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    );
                                  }

                                  // Build parent -> replies map
                                  final parentComments = docs
                                      .where(
                                        (d) =>
                                            (d.data()['parentCommentId']
                                                as String?) ==
                                            null,
                                      )
                                      .toList();
                                  final replies = docs
                                      .where(
                                        (d) =>
                                            (d.data()['parentCommentId']
                                                as String?) !=
                                            null,
                                      )
                                      .toList();

                                  return Column(
                                    children: parentComments.map((parentDoc) {
                                      final pdata = parentDoc.data();
                                      final pid = parentDoc.id;
                                      final message = pdata['message'] ?? '';
                                      final senderUid =
                                          pdata['senderUid'] as String?;
                                      final createdAt =
                                          (pdata['createdAt'] as Timestamp?)
                                              ?.toDate();
                                      final childReplies = replies
                                          .where(
                                            (r) =>
                                                (r.data()['parentCommentId']
                                                    as String?) ==
                                                pid,
                                          )
                                          .toList();

                                      return Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(2.w),
                                        margin: EdgeInsets.only(bottom: 1.h),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Author name and message
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (senderUid != null)
                                                        FutureBuilder<String?>(
                                                          future:
                                                              _resolveUserName(
                                                                senderUid,
                                                              ),
                                                          builder: (context, snap) {
                                                            final name =
                                                                snap.data ??
                                                                senderUid;
                                                            return Text(
                                                              name ?? senderUid,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                      SizedBox(height: 0.5.h),
                                                      Text(
                                                        message,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (createdAt != null)
                                                  Text(
                                                    _formatDate(createdAt),
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: 1.h),
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _replyTo[announcement
                                                              .id] =
                                                          pid;
                                                      // Ensure controller exists for this announcement
                                                      _commentControllers
                                                              .putIfAbsent(
                                                                announcement.id,
                                                                () =>
                                                                    TextEditingController(),
                                                              )
                                                              .text =
                                                          '';
                                                    });
                                                  },
                                                  child: const Text('Reply'),
                                                ),
                                              ],
                                            ),
                                            // Replies
                                            if (childReplies.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 4.w,
                                                  top: 1.h,
                                                ),
                                                child: Column(
                                                  children: childReplies.map((
                                                    r,
                                                  ) {
                                                    final rdata = r.data();
                                                    final rmsg =
                                                        rdata['message'] ?? '';
                                                    final rSenderUid =
                                                        rdata['senderUid']
                                                            as String?;
                                                    final rcreatedAt =
                                                        (rdata['createdAt']
                                                                as Timestamp?)
                                                            ?.toDate();

                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: 1.h,
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                if (rSenderUid !=
                                                                    null)
                                                                  FutureBuilder<
                                                                    String?
                                                                  >(
                                                                    future: _resolveUserName(
                                                                      rSenderUid,
                                                                    ),
                                                                    builder:
                                                                        (
                                                                          context,
                                                                          snap,
                                                                        ) {
                                                                          final name =
                                                                              snap.data ??
                                                                              rSenderUid;
                                                                          return Text(
                                                                            name ??
                                                                                rSenderUid,
                                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          );
                                                                        },
                                                                  ),
                                                                SizedBox(
                                                                  height: 0.4.h,
                                                                ),
                                                                Text(
                                                                  rmsg,
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodySmall,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (rcreatedAt !=
                                                              null)
                                                            Text(
                                                              _formatDate(
                                                                rcreatedAt,
                                                              ),
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                              SizedBox(height: 1.h),
                              // Reply / New comment input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentControllers
                                          .putIfAbsent(
                                            announcement.id,
                                            () => TextEditingController(),
                                          ),
                                      decoration: InputDecoration(
                                        hintText:
                                            _replyTo[announcement.id] != null
                                            ? 'Replying...'
                                            : 'Add a comment',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final controller =
                                          _commentControllers[announcement.id];
                                      final text =
                                          controller?.text.trim() ?? '';
                                      if (text.isEmpty) return;
                                      final parent = _replyTo[announcement.id];
                                      try {
                                        await _equbService
                                            .addAnnouncementComment(
                                              equbId: widget.equbId,
                                              announcementId: announcement.id,
                                              message: text,
                                              parentCommentId: parent,
                                            );
                                        controller?.clear();
                                        setState(() {
                                          _replyTo[announcement.id] = null;
                                        });
                                      } catch (e) {
                                        if (mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to post comment: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                      }
                                    },
                                    child: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
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

  /// Resolve a user's display name (cached). Falls back to email or uid.
  Future<String?> _resolveUserName(String uid) async {
    if (uid.isEmpty) return null;
    if (_userNames.containsKey(uid)) return _userNames[uid];
    try {
      final snap = await UserService().streamUser(uid).first;
      if (snap.exists) {
        final data = snap.data() ?? {};
        final name = data['displayName'] ?? data['name'] ?? data['email'];
        final result = name?.toString() ?? uid;
        _userNames[uid] = result;
        return result;
      }
    } catch (_) {}
    _userNames[uid] = uid;
    return uid;
  }
}
