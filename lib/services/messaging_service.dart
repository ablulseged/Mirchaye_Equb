import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'dart:io' show Platform;

// Initialize local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initialize local notifications
Future<void> initializeLocalNotifications() async {
  if (kIsWeb) return; // Not supported on web

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/icon');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // Create Android notification channel with heads-up support
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'notifications_channel', // Same as in AndroidManifest.xml
      'Notifications',
      description: 'Notifications for Equb app',
      importance: Importance.max, // MAX for heads-up notifications
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

/// Show local notification (can be called from anywhere)
/// Supports: Push notifications, Heads-up (overlay), Lock screen, Banner, Notification center
Future<void> showLocalNotification(
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  if (kIsWeb) return; // Not supported on web

  // Android notification details with full support for:
  // - Heads-up notifications (overlay at top) - Importance.max + Priority.max
  // - Lock screen notifications - Visibility.public
  // - Banner notifications - Automatic with high importance
  // - Notification center - Automatic with all notifications
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'notifications_channel', // Same channel ID as in AndroidManifest.xml
    'Notifications',
    channelDescription: 'Notifications for Equb app',
    importance: Importance.max, // MAX for heads-up notifications (overlay at top)
    priority: Priority.max, // MAX priority for heads-up notifications
    showWhen: true,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: const Color(0xFF2196F3), // Blue LED light
    ledOnMs: 1000,
    ledOffMs: 500,
    visibility: NotificationVisibility.public, // Show on lock screen
    ticker: '$title: $body', // Text shown in status bar
    ongoing: false,
    autoCancel: true,
    channelShowBadge: true,
    fullScreenIntent: false, // Set to true for critical notifications
    styleInformation: BigTextStyleInformation(
      body, // Show full text in expanded notification
      contentTitle: title,
      htmlFormatBigText: false,
      summaryText: '',
    ),
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true, // Show alert (heads-up)
    presentBadge: true, // Show badge
    presentSound: true, // Play sound
    interruptionLevel: InterruptionLevel.active, // Heads-up notification
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  // Generate unique notification ID
  final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformChannelSpecifics,
    payload: data.toString(),
  );
}

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('📱 Title: ${message.notification?.title}');
  print('📱 Body: ${message.notification?.body}');
  
  // Initialize local notifications in background handler
  await initializeLocalNotifications();
  
  // Show notification even when app is in background
  if (message.notification != null) {
    await showLocalNotification(
      message.notification!.title ?? 'Notification',
      message.notification!.body ?? '',
      message.data,
    );
  }
}

class MessagingService {
  MessagingService._internal();
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    await initializeLocalNotifications();
  }

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Initialize local notifications first
    await _initializeLocalNotifications();
    
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
    
    // Show local notification even when app is in foreground
    // This ensures notifications appear even when using other apps
    if (message.notification != null) {
      await showLocalNotification(
        message.notification!.title ?? 'Notification',
        message.notification!.body ?? '',
        message.data,
      );
    }
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
