import 'api_service.dart';

/// Acciones de seguridad del usuario: bloqueo, desbloqueo, reporte de
/// perfiles y privacidad. Todas apuntan a endpoints reales del backend
/// (`/security/*`).
class SecurityService {
  /// `POST /security/block {blockedId}` → `{blocked}`.
  static Future<bool> block(String userId) async {
    final data = await ApiService.postJson(
      '/security/block',
      body: {'blockedId': userId},
    );
    return data['blocked'] as bool? ?? true;
  }

  /// `DELETE /security/block?blockedId=` → `{blocked}`.
  static Future<bool> unblock(String userId) async {
    final data = await ApiService.deleteJson('/security/block?blockedId=$userId');
    return data['blocked'] as bool? ?? false;
  }

  /// `GET /security/block/list` → `{blocked: [BlockedUser]}`.
  static Future<List<BlockedUser>> listBlocked() async {
    final data = await ApiService.getJson('/security/block/list');
    return (data['blocked'] as List? ?? [])
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /security/report` → `{ok}`.
  /// [entityType] es `USER`, `POST`, `COMMENT` o `BETA`.
  static Future<void> report({
    required String entityId,
    required String entityType,
    required String reason,
    String? description,
  }) async {
    await ApiService.postJson('/security/report', body: {
      'type': entityType.toUpperCase(),
      'entityId': entityId,
      'reason': reason,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
  }

  /// `PATCH /security/privacy {isPrivate}` → `{ok, isPrivate}`.
  static Future<bool> setPrivate(bool isPrivate) async {
    final data = await ApiService.patchJson(
      '/security/privacy',
      body: {'isPrivate': isPrivate},
    );
    return data['isPrivate'] as bool? ?? isPrivate;
  }
}

/// Usuario bloqueado (`GET /security/block/list`).
class BlockedUser {
  final String id;
  final String username;
  final String? avatar;

  const BlockedUser({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    id: json['id'] as String,
    username: json['username'] as String? ?? 'usuario',
    avatar: json['avatar'] as String?,
  );
}
