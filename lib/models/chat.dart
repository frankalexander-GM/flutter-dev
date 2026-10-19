/// Modelos del chat global (`/chat`) y de los mensajes directos (`/dm`).
library;

/// Mensaje del chat mundial (`ChatMessageOut`).
class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;

  /// `true` mientras un mensaje optimista aún no ha sido confirmado por el
  /// backend (se pinta con un indicador de "enviando").
  final bool pending;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.pending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String? ?? 'Usuario',
        content: json['content'] as String? ?? '',
        createdAt: _parseDate(json['createdAt']),
      );
}

/// Fila de `GET /dm`: interlocutor, último mensaje y no leídos.
class Conversation {
  final String peerId;
  final String peerUsername;
  final String? peerAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.peerId,
    required this.peerUsername,
    this.peerAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        peerId: json['peerId'] as String? ?? '',
        peerUsername: json['peerUsername'] as String? ?? 'Usuario',
        peerAvatar: json['peerAvatar'] as String?,
        lastMessage: json['lastMessage'] as String? ?? '',
        lastMessageAt: _parseDate(json['lastMessageAt']),
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

/// Mensaje directo (`DirectMessageOut`).
class DirectMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.readAt,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) => DirectMessage(
        id: json['id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        recipientId: json['recipientId'] as String? ?? '',
        content: json['content'] as String? ?? '',
        readAt: json['readAt'] == null ? null : _parseDate(json['readAt']),
        createdAt: _parseDate(json['createdAt']),
      );
}

/// Parsea una fecha ISO (con o sin zona) y la normaliza a hora local.
DateTime _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}
