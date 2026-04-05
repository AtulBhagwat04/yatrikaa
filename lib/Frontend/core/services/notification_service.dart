import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yatrikaa/Frontend/core/models/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  // Channel ID for local notifications
  static const String _channelId = 'yatrikaa_notifications';
  static const String _channelName = 'Yatrikaa Notifications';
  static const String _channelDescription = 'Notifications from Yatrikaa app';

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[NotificationService] User granted permission');
    } else {
      debugPrint('[NotificationService] User declined or has not accepted permission');
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 4. Handle Background/Terminated state and notification clicks
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // 6. Topic Subscriptions
    try {
      await _fcm.subscribeToTopic('all_users');
    } catch (e) {
      debugPrint('[NotificationService] Topic error: $e');
    }

    // 7. Initial Token Check
    await updateToken();
  }

  /// Fetches the FCM token and sends it to the backend if the user is logged in
  Future<void> updateToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('[NotificationService] FCM Token: $token');
        
        final isLoggedIn = await _authService.isLoggedIn();
        if (isLoggedIn) {
          await _sendTokenToBackend(token);
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error getting token: $e');
    }
  }

  /// Sends the FCM token to the backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final jwtToken = await _authService.getToken();
      if (jwtToken == null) return;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('[NotificationService] FCM token updated successfully on backend');
      } else {
        debugPrint('[NotificationService] Failed to update FCM token on backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error sending token to backend: $e');
    }
  }

  /// Shows a local notification when a message is received in the foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      debugPrint('[NotificationService] Notification tapped with data: $data');
      // TODO: Handle navigation based on data
    }
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    debugPrint('[NotificationService] App opened from notification: ${message.data}');
    // TODO: Handle navigation based on message data
  }

  // --- UI/Mock related methods (Keep if needed by UI) ---
  
  static final List<NotificationModel> _mockNotifications = [];

  Future<bool> hasUnreadNotifications() async {
    return _mockNotifications.any((n) => !n.isRead);
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    // In a real app, you might fetch this from a local database or backend
    return _mockNotifications;
  }

  Future<void> markAsRead(String id) async {
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _mockNotifications.length; i++) {
      _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
    }
  }

  Future<void> clearAll() async {
    _mockNotifications.clear();
  }
}
