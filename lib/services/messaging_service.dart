import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('📱 Title: ${message.notification?.title}');
  print('📱 Body: ${message.notification?.body}');
}

class MessagingService {
  MessagingService._internal();
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('✅ User granted provisional notification permission');
    } else {
      print('❌ User declined or has not accepted notification permission');
      return;
    }

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      print('📱 FCM Token: $_fcmToken');
      await _saveTokenToFirestore(_fcmToken!);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('📱 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      _saveTokenToFirestore(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps (when user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Foreground message received: ${message.messageId}');
    print('📱 Title: ${message.notification?.title}');
    print('📱 Body: ${message.notification?.body}');
    
    // FCM will automatically show notifications even when app is in foreground
    // if the notification payload includes both 'notification' and 'data' fields
    // We don't need to manually show local notifications in most cases
  }

  /// Handle when user taps on a notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 Message opened app: ${message.messageId}');
    print('📱 Data: ${message.data}');
    
    // You can navigate to a specific screen based on message data here
    // For example, if message.data['type'] == 'payment', navigate to payment screen
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Get FCM tokens for multiple users
  Future<Map<String, String>> getFcmTokensForUsers(List<String> userIds) async {
    final Map<String, String> tokens = {};
    
    try {
      final futures = userIds.map((userId) async {
        final doc = await _db.collection('users').doc(userId).get();
        if (doc.exists) {
          final token = doc.data()?['fcmToken'] as String?;
          if (token != null && token.isNotEmpty) {
            tokens[userId] = token;
          }
        }
      });
      
      await Future.wait(futures);
    } catch (e) {
      print('❌ Error getting FCM tokens: $e');
    }
    
    return tokens;
  }
}
