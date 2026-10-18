import '../models/notification.dart';
import '../models/post.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Página de notificaciones: `GET /notifications` →
/// `{items, unreadCount, total, skip, limit}`.
class NotificationPage {
  final List<AppNotification> items;
  final int unreadCount;
  final int total;

  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.total,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        items: (json['items'] as List)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
        unreadCount: json['unreadCount'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );
}

class UserService {
  /// `GET /users/me` → perfil propio (`UserMe`).
  static Future<UserMe> getMe() async {
    final data = await ApiService.getJson('/users/me');
    return UserMe.fromJson(data as Map<String, dynamic>);
  }

  /// `PATCH /users/me/profile` → perfil actualizado.
  static Future<UserMe> updateProfile({
    String? fullName,
    String? bio,
    String? avatar,
    String? banner,
    String? location,
    String? website,
    String? profession,
  }) async {
    final data = await ApiService.patchJson('/users/me/profile', body: {
      'fullName': ?fullName,
      'bio': ?bio,
      'avatar': ?avatar,
      'banner': ?banner,
      'location': ?location,
      'website': ?website,
      'profession': ?profession,
    });
    return UserMe.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /users/{id}` → `{user: ProfileUser, posts: [PostSummary]}`.
  static Future<(ProfileUser, List<Post>)> getUser(String userId) async {
    final data = await ApiService.getJson('/users/$userId', auth: false);
    final user = ProfileUser.fromJson(data['user'] as Map<String, dynamic>);
    final posts = (data['posts'] as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
    return (user, posts);
  }

  /// `GET /users/by-username/{username}` → id mínimo o null si no existe.
  static Future<String?> getUserIdByUsername(String username) async {
    final data =
        await ApiService.getJson('/users/by-username/$username', auth: false);
    final user = data['user'] as Map<String, dynamic>?;
    return user?['id'] as String?;
  }

  // --------------------------- Notificaciones ----------------------------

  /// `GET /notifications?skip&limit` → página con `unreadCount`.
  static Future<NotificationPage> getNotifications({
    int skip = 0,
    int limit = 20,
  }) async {
    final data =
        await ApiService.getJson('/notifications?skip=$skip&limit=$limit');
    return NotificationPage.fromJson(data as Map<String, dynamic>);
  }

  /// `PATCH /notifications/read-all` → marca todo como leído.
  static Future<int> markAllRead() async {
    final data = await ApiService.patchJson('/notifications/read-all');
    return data['marked'] as int? ?? 0;
  }

  /// `GET /notifications/unread-count` → `{notifications, direct_messages}`.
  static Future<int> getUnreadCount() async {
    final data = await ApiService.getJson('/notifications/unread-count');
    return data['notifications'] as int? ?? 0;
  }

  // -------------------------------- Follow --------------------------------

  /// `GET /follow?userId=` → estado + contadores.
  static Future<Map<String, dynamic>> followStatus(String userId) async {
    final data = await ApiService.getJson('/follow?userId=$userId');
    return data as Map<String, dynamic>;
  }

  /// `POST /follow {followeeId}` → `{following}` (idempotente).
  static Future<bool> follow(String userId) async {
    final data = await ApiService.postJson('/follow', body: {'followeeId': userId});
    return data['following'] as bool? ?? false;
  }

  /// `DELETE /follow?followeeId=` → `{following}`.
  static Future<bool> unfollow(String userId) async {
    final data = await ApiService.deleteJson('/follow?followeeId=$userId');
    return data['following'] as bool? ?? false;
  }

  /// `GET /users/{id}/followers` → `{total, followers}`.
  static Future<List<FollowUser>> getFollowers(String userId) async {
    final data = await ApiService.getJson('/users/$userId/followers', auth: false);
    return (data['followers'] as List)
        .map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /users/{id}/following` → `{total, following}`.
  static Future<List<FollowUser>> getFollowing(String userId) async {
    final data = await ApiService.getJson('/users/$userId/following', auth: false);
    return (data['following'] as List)
        .map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
