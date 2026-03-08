import 'package:bhatkanti_app/Frontend/core/models/notification_model.dart';

class NotificationService {
  // Static mock data for now
  static final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: '1',
      title: 'New Event Near You!',
      message: 'A new cultural festival has been added in Devbag Sangam. Check it out now!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.event,
    ),
    NotificationModel(
      id: '2',
      title: 'Review Liked',
      message: 'Someone liked your review of Tarkarli Beach. Keep sharing your experiences!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.success,
    ),
    NotificationModel(
      id: '3',
      title: 'Trip Reminder',
      message: 'Don\'t forget your upcoming trip to Sindhudurg Fort tomorrow morning.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.trip,
    ),
    NotificationModel(
      id: '4',
      title: 'Guide Verification',
      message: 'Your request for verification is currently being reviewed by our team.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.info,
    ),
    NotificationModel(
      id: '5',
      title: 'System Update',
      message: 'Bhatkanti has been updated with several UI enhancements and performance fixes.',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      type: NotificationType.warning,
    ),
  ];

  Future<bool> hasUnreadNotifications() async {
    return _mockNotifications.any((n) => !n.isRead);
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockNotifications;
  }

  Future<void> markAsRead(String id) async {
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockNotifications[index] =
          _mockNotifications[index].copyWith(isRead: true);
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
