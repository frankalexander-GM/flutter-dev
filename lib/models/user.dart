/// Modelos de usuario — claves idénticas a los schemas Pydantic del backend
/// FastAPI (`UserMe`, `ProfileUser`, `FollowListUser`).
library;

/// `UserMe` — 100% snake_case. Devuelto por `/auth/me`, `/users/me` y como
/// `user` del login.
class UserMe {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatar;
  final String? banner;
  final String role;
  final String language;
  final bool isGuest;
  final bool isPrivate;
  final bool tourCompleted;
  final int devCoins;
  final String? location;
  final String? website;
  final String? profession;
  final List<String>? tags;
  final DateTime createdAt;

  const UserMe({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.bio,
    this.avatar,
    this.banner,
    required this.role,
    required this.language,
    required this.isGuest,
    required this.isPrivate,
    required this.tourCompleted,
    required this.devCoins,
    this.location,
    this.website,
    this.profession,
    this.tags,
    required this.createdAt,
  });

  factory UserMe.fromJson(Map<String, dynamic> json) => UserMe(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        bio: json['bio'] as String?,
        avatar: json['avatar'] as String?,
        banner: json['banner'] as String?,
        role: json['role'] as String? ?? 'USER',
        language: json['language'] as String? ?? 'es',
        isGuest: json['is_guest'] as bool? ?? false,
        isPrivate: json['is_private'] as bool? ?? false,
        tourCompleted: json['tour_completed'] as bool? ?? false,
        devCoins: json['dev_coins'] as int? ?? 0,
        location: json['location'] as String?,
        website: json['website'] as String?,
        profession: json['profession'] as String?,
        tags: (json['tags'] as List?)?.cast<String>(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// `ProfileUser` — perfil público de `GET /users/{id}`.
/// Contadores en camelCase (`followersCount`, `postsCount`...).
class ProfileUser {
  final String id;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatar;
  final String? banner;
  final String role;
  final bool isGuest;
  final String? location;
  final String? website;
  final String? profession;
  final DateTime createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;

  const ProfileUser({
    required this.id,
    required this.username,
    this.fullName,
    this.bio,
    this.avatar,
    this.banner,
    required this.role,
    required this.isGuest,
    this.location,
    this.website,
    this.profession,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) => ProfileUser(
        id: json['id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        bio: json['bio'] as String?,
        avatar: json['avatar'] as String?,
        banner: json['banner'] as String?,
        role: json['role'] as String? ?? 'USER',
        isGuest: json['is_guest'] as bool? ?? false,
        location: json['location'] as String?,
        website: json['website'] as String?,
        profession: json['profession'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        postsCount: json['postsCount'] as int? ?? 0,
        isFollowing: json['isFollowing'] as bool? ?? false,
      );
}

/// Fila de `GET /users/{id}/followers|following`.
class FollowUser {
  final String id;
  final String username;
  final String? avatar;
  final String? bio;
  final String role;
  final int followersCount;
  final int postsCount;
  final DateTime followedAt;

  const FollowUser({
    required this.id,
    required this.username,
    this.avatar,
    this.bio,
    required this.role,
    required this.followersCount,
    required this.postsCount,
    required this.followedAt,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) => FollowUser(
        id: json['id'] as String,
        username: json['username'] as String,
        avatar: json['avatar'] as String?,
        bio: json['bio'] as String?,
        role: json['role'] as String? ?? 'USER',
        followersCount: json['followersCount'] as int? ?? 0,
        postsCount: json['postsCount'] as int? ?? 0,
        followedAt: DateTime.parse(json['followedAt'] as String),
      );
}
