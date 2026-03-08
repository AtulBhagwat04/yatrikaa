import 'package:flutter/material.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
  event,
  place,
  trip,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? route;
  final dynamic arguments;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = NotificationType.info,
    this.isRead = false,
    this.route,
    this.arguments,
  });

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      route: route,
      arguments: arguments,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline_rounded;
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.event:
        return Icons.event_note_rounded;
      case NotificationType.place:
        return Icons.location_on_outlined;
      case NotificationType.trip:
        return Icons.map_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.event:
        return Colors.purple;
      case NotificationType.place:
        return Colors.teal;
      case NotificationType.trip:
        return Colors.indigo;
    }
  }
}
