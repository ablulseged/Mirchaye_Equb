import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'messaging_service.dart' show MessagingService, showLocalNotification;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Render service URL for push notifications
  static const String renderApiUrl = 'https://robot-9qcb.onrender.com';

  CollectionReference<Map<String, dynamic>> _userNotifications(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  /// Stream all notifications for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    // Don't use orderBy to avoid index requirements
    return _userNotifications(user.uid).snapshots();
  }

  /// Stream only unread notifications
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUnreadNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    // Don't use orderBy to avoid index requirements
    return _userNotifications(user.uid).snapshots();
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    
    try {
      // Get all notifications and filter client-side to avoid index requirement
      final snapshot = await _userNotifications(user.uid).get();
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['isRead'] as bool? ?? false) == false;
      }).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Stream count of unread notifications
  Stream<int> streamUnreadCount() {
    return streamUnreadNotifications().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['isRead'] as bool? ?? false) == false;
      }).length;
    });
  }

  /// Create a notification for a user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'payment', 'join_request', 'spin_winner', 'general'
    String? equbId,
    String? equbName,
    Map<String, dynamic>? data,
    bool showHeadsUp = false, // Show heads-up notification immediately
  }) async {
    try {
      // Save notification to Firestore
      await _userNotifications(userId).add({
        'title': title,
        'message': message,
        'type': type,
        'equbId': equbId,
        'equbName': equbName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data,
        'showHeadsUp': showHeadsUp, // Store heads-up flag
      });

      // Show heads-up notification if requested and user is the current user
      if (showHeadsUp) {
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId == userId) {
          await _showHeadsUpNotification(title, message, type, data ?? {});
        }
      }

      // Send push notification
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: message,
        data: {
          'type': type,
          'equbId': equbId ?? '',
          'equbName': equbName ?? '',
          ...?data,
        },
      );
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Create notifications for multiple users (e.g., all members of a group)
  Future<void> createNotificationForUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    String? equbId,
    String? equbName,
    Map<String, dynamic>? data,
    bool showHeadsUp = false, // Show heads-up notification immediately for current user
  }) async {
    try {
      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();
      final currentUserId = _auth.currentUser?.uid;
      
      // Save notifications to Firestore
      for (final userId in userIds) {
        final notificationRef = _userNotifications(userId).doc();
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'type': type,
          'equbId': equbId,
          'equbName': equbName,
          'isRead': false,
          'createdAt': now,
          'data': data,
          'showHeadsUp': showHeadsUp, // Store heads-up flag
        });
      }
      
      await batch.commit();

      // Show heads-up notification if requested and current user is in the list
      if (showHeadsUp && currentUserId != null && userIds.contains(currentUserId)) {
        await _showHeadsUpNotification(title, message, type, data ?? {});
      }

      // Send push notifications to all users
      await _sendPushNotificationsToUsers(
        userIds: userIds,
        title: title,
        body: message,
        data: {
          'type': type,
          'equbId': equbId ?? '',
          'equbName': equbName ?? '',
          ...?data,
        },
      );
    } catch (e) {
      print('Error creating notifications for users: $e');
    }
  }

  /// Show heads-up (overlay) notification immediately
  Future<void> _showHeadsUpNotification(
    String title,
    String message,
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      await showLocalNotification(
        title,
        message,
        {
          'type': type,
          ...data,
        },
      );
    } catch (e) {
      print('Error showing heads-up notification: $e');
    }
  }

  /// Send push notification to a single user
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _db.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for user $userId');
        return;
      }

      // Send notification using Cloud Function or FCM REST API
      // For now, we'll create a document in a collection that triggers a Cloud Function
      // OR use the push notification service
      await _sendPushNotificationViaCloudFunction(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data ?? {},
      );
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  /// Send push notifications to multiple users
  Future<void> _sendPushNotificationsToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final messagingService = MessagingService();
      
      // Get FCM tokens for all users
      final tokens = await messagingService.getFcmTokensForUsers(userIds);
      
      if (tokens.isEmpty) {
        print('⚠️ No FCM tokens found for users');
        return;
      }

      // Send notifications to all tokens
      for (final entry in tokens.entries) {
        await _sendPushNotificationViaCloudFunction(
          fcmToken: entry.value,
          title: title,
          body: body,
          data: data ?? {},
        );
      }
    } catch (e) {
      print('Error sending push notifications: $e');
    }
  }

  /// Send push notification via Render API
  Future<void> _sendPushNotificationViaCloudFunction({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (renderApiUrl == 'YOUR_RENDER_API_URL_HERE' || renderApiUrl.isEmpty) {
      print('⚠️ Render API URL is not configured. Skipping push notification.');
      print('⚠️ Please update renderApiUrl in notification_service.dart with your Render service URL.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$renderApiUrl/api/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
          'data': data,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Timeout connecting to Render service');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully via Render');
      } else {
        print('❌ Failed to send push notification via Render: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending push notification request to Render: $e');
    }
  }

  /// Test connection to Render service
  /// Returns true if connection is successful, false otherwise
  Future<bool> testRenderConnection() async {
    if (renderApiUrl == 'YOUR_RENDER_API_URL_HERE' || renderApiUrl.isEmpty) {
      print('❌ Render API URL is not configured');
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$renderApiUrl/test'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Timeout connecting to Render service');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Render service is connected: ${responseData['message']}');
        return true;
      } else {
        print('❌ Render service returned status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error testing Render connection: $e');
      return false;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _userNotifications(user.uid).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Get all notifications and filter client-side to avoid index requirement
      final snapshot = await _userNotifications(user.uid).get();
      final unreadDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['isRead'] as bool? ?? false) == false;
      }).toList();
      
      if (unreadDocs.isEmpty) return;
      
      final batch = _db.batch();
      for (final doc in unreadDocs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _userNotifications(user.uid).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete all read notifications older than specified days
  Future<void> deleteOldReadNotifications({int daysOld = 30}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _userNotifications(user.uid)
          .where('isRead', isEqualTo: true)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error deleting old notifications: $e');
    }
  }
}

