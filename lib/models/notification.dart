/// `NotificationOut` del backend FastAPI — mezcla camelCase (`fromUserId`,
/// `createdAt`, `entityId`) con snake_case (`message`, `read`).
library;

enum NotificationType { live, follow, comment, like }

NotificationType notificationTypeFrom(String value) {
  switch (value.toUpperCase()) {
    case 'FOLLOW':
      return NotificationType.follow;
    case 'COMMENT':
      return NotificationType.comment;
    case 'LIVE':
      return NotificationType.live;
    default:
      return NotificationType.like;
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String message;
  final String? entityId;
  final bool read;
  final String fromUserId;
  final String fromUsername;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.entityId,
    required this.read,
    required this.fromUserId,
    required this.fromUsername,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: notificationTypeFrom(json['type'] as String? ?? 'LIKE'),
        message: json['message'] as String? ?? '',
        entityId: json['entityId'] as String?,
        read: json['read'] as bool? ?? false,
        fromUserId: json['fromUserId'] as String? ?? '',
        fromUsername: json['fromUsername'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
