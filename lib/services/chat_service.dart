import '../models/chat.dart';
import 'api_service.dart';

/// Chat global (`/chat`), mensajes directos (`/dm`) y contador de no leídos.
class ChatService {
  // ------------------------------------------------------------- Chat global

  /// `GET /chat?skip&limit` → historial del más nuevo al más viejo.
  static Future<List<ChatMessage>> getWorldMessages({
    int skip = 0,
    int limit = 50,
  }) async {
    final data =
        await ApiService.getJson('/chat?skip=$skip&limit=$limit', auth: false);
    return (data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /chat {content}` → mensaje creado.
  static Future<ChatMessage> sendWorldMessage(String content) async {
    final data = await ApiService.postJson('/chat', body: {'content': content});
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  // ------------------------------------------------------- Mensajes directos

  /// `GET /dm` → conversaciones con último mensaje y no leídos.
  static Future<List<Conversation>> getConversations() async {
    final data = await ApiService.getJson('/dm');
    return (data as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /dm/{userId}?skip&limit` → historial del más antiguo al más nuevo.
  static Future<List<DirectMessage>> getDirectMessages(
    String userId, {
    int skip = 0,
    int limit = 200,
  }) async {
    final data =
        await ApiService.getJson('/dm/$userId?skip=$skip&limit=$limit');
    return (data as List)
        .map((e) => DirectMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /dm/{userId} {content}` → mensaje enviado.
  static Future<DirectMessage> sendDirectMessage(
    String userId,
    String content,
  ) async {
    final data = await ApiService.postJson(
      '/dm/$userId',
      body: {'content': content},
    );
    return DirectMessage.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /dm/{userId}/read` → marca la conversación como leída.
  static Future<int> markConversationRead(String userId) async {
    final data = await ApiService.postJson('/dm/$userId/read');
    return data['marked'] as int? ?? 0;
  }

  /// `GET /notifications/unread-count` → nº de DMs sin leer.
  static Future<int> getUnreadDms() async {
    final data = await ApiService.getJson('/notifications/unread-count');
    return data['direct_messages'] as int? ?? 0;
  }
}
