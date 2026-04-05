import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yatrikaa/Frontend/core/models/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:yatrikaa/main.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';

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
      settings: initializationSettings,
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
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
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
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        debugPrint('[NotificationService] Notification tapped with data: $data');
        _handleNavigation(data);
      } catch (e) {
        debugPrint('[NotificationService] Error parsing tap payload: $e');
      }
    }
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    debugPrint('[NotificationService] App opened from notification: ${message.data}');
    _handleNavigation(message.data);
  }

  /// Centralized navigation logic based on notification data
  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    
    // Check for explicit route field
    if (data.containsKey('route') && data['route'] != null) {
      MyApp.navigatorKey.currentState?.pushNamed(
        data['route'] as String,
        arguments: data['arguments'] ?? data,
      );
      return;
    }

    // fallback to type-based navigation
    switch (type) {
      case 'event':
        if (data.containsKey('eventId')) {
          MyApp.navigatorKey.currentState?.pushNamed(
            RouteNames.eventDetails,
            arguments: {'eventId': data['eventId']},
          );
        }
        break;
      case 'place':
      case 'new_place':
        if (data.containsKey('placeId')) {
          MyApp.navigatorKey.currentState?.pushNamed(
            RouteNames.placeDetails,
            arguments: data['placeId'], // PlaceDetails usually takes a String ID
          );
        }
        break;
      case 'guide_request':
        MyApp.navigatorKey.currentState?.pushNamed(RouteNames.profile);
        break;
      default:
        // Default to notifications screen if it exists, or home
        debugPrint('[NotificationService] No specific route for type: $type');
    }
  }


  Future<bool> hasUnreadNotifications() async {
    final notifications = await getAllNotifications();
    return notifications.any((n) => !n.isRead);
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final jwtToken = await _authService.getToken();
      if (jwtToken == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _mapJsonToNotification(json)).toList();
      }
    } catch (e) {
      debugPrint('[NotificationService] Error fetching notifications: $e');
    }
    return [];
  }

  Future<void> markAsRead(String id) async {
    try {
      final jwtToken = await _authService.getToken();
      if (jwtToken == null) return;

      await http.put(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final jwtToken = await _authService.getToken();
      if (jwtToken == null) return;

      await http.put(
        Uri.parse('${ApiConstants.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] Error marking all as read: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final jwtToken = await _authService.getToken();
      if (jwtToken == null) return;

      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/notifications/clear-all'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] Error clearing notifications: $e');
    }
  }

  NotificationModel _mapJsonToNotification(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      type: _parseNotificationType(json['type']),
      route: json['route'],
      arguments: json['arguments'],
    );
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'success': return NotificationType.success;
      case 'warning': return NotificationType.warning;
      case 'error': return NotificationType.error;
      case 'event': return NotificationType.event;
      case 'place': case 'new_place': return NotificationType.place;
      case 'trip': return NotificationType.trip;
      default: return NotificationType.info;
    }
  }
}
