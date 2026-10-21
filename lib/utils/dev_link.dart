import '../services/api_service.dart';

/// Enlace profundo de DevPlay.
///
/// El perfil se comparte con una URL `?user=<username>`. Esta clase la
/// interpreta y la resuelve contra la API real (`GET /users/by-username/{u}`).
class DevLink {
  /// Parámetro de query que lleva el username del perfil.
  static const String userParam = 'user';

  /// Extrae el username de perfil de una URL de DevPlay.
  ///
  /// Acepta `?user=alice`, `/#/user/alice` y URLs completas.
  static String? usernameFrom(Uri uri) {
    final fromQuery = uri.queryParameters[userParam];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return fromQuery.trim();
    }
    // Formato por ruta: /#/user/alice
    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == userParam && segments[i + 1].trim().isNotEmpty) {
        return segments[i + 1].trim();
      }
    }
    final hash = uri.fragment;
    if (hash.isNotEmpty) {
      final hashUri = Uri.tryParse('http://x/$hash');
      if (hashUri != null) {
        final fromHash = usernameFrom(hashUri);
        if (fromHash != null) return fromHash;
      }
    }
    return null;
  }

  /// Username del perfil de la URL actual del navegador (si lo hay).
  static String? currentUsername() {
    final base = Uri.base;
    return usernameFrom(base);
  }

  /// Construye la URL pública de un perfil.
  static String profileUrl(String username, {String? origin}) {
    final base = origin ?? _currentOrigin();
    return '$base/?$userParam=$username';
  }

  /// Origen del navegador, con reserva si no es http(s) (p. ej. en tests).
  static String _currentOrigin() {
    final uri = Uri.base;
    if (uri.scheme == 'http' || uri.scheme == 'https') return uri.origin;
    return 'https://devplay.app';
  }

  /// Resuelve el username de un enlace a su id de usuario real.
  ///
  /// Devuelve `null` si el usuario no existe o no se puede resolver.
  static Future<String?> resolveUserId(String username) async {
    try {
      return await ApiService.getJson(
        '/users/by-username/$username',
        auth: false,
      ).then((data) {
        final user = data['user'] as Map<String, dynamic>?;
        return user?['id'] as String?;
      });
    } catch (_) {
      return null;
    }
  }
}
