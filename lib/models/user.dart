/// Modelos de usuario — claves idénticas a los schemas Pydantic del backend
/// FastAPI (`UserMe`, `ProfileUser`, `FollowListUser`).
library;

import 'post.dart';

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
  final List<String>? tags;
  final DateTime createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;
  final bool isBlocked;
  final bool blockedMe;

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
    this.tags,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
    this.isBlocked = false,
    this.blockedMe = false,
  });

  /// El backend puede devolver `is_private`; si el perfil es privado y no es
  /// el propio usuario, `get_profile` no lo expone.
  bool get isPrivate => blockedMe;

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
    tags: (json['tags'] as List?)?.cast<String>(),
    createdAt: DateTime.parse(json['created_at'] as String),
    followersCount: json['followersCount'] as int? ?? 0,
    followingCount: json['followingCount'] as int? ?? 0,
    postsCount: json['postsCount'] as int? ?? 0,
    isFollowing: json['isFollowing'] as bool? ?? false,
    isBlocked: json['isBlocked'] as bool? ?? false,
    blockedMe: json['blockedMe'] as bool? ?? false,
  );
}

/// `MediaItem` — un medio (imagen o video) del usuario.
/// Endpoint: `GET /users/{id}/media`.
class ProfileMedia {
  final String url;
  final String kind;
  final String postId;
  final DateTime createdAt;

  const ProfileMedia({
    required this.url,
    required this.kind,
    required this.postId,
    required this.createdAt,
  });

  bool get isVideo => kind.toLowerCase() == 'video';

  factory ProfileMedia.fromJson(Map<String, dynamic> json) => ProfileMedia(
    url: json['url'] as String,
    kind: json['kind'] as String? ?? 'image',
    postId: json['postId'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// `UserStats` — estadísticas reales del creador (`GET /users/me/stats`).
class UserStats {
  final int posts;
  final int comments;
  final int likes;
  final int betas;
  final int followers;
  final int following;
  final int bookmarks;
  final int totalDownloads;
  final int totalLikesReceived;
  final int totalCommentsReceived;
  final int points;
  final int level;
  final int pointsForNextLevel;
  final double progressToNext;
  final List<ActivityDay> activityByDay;

  const UserStats({
    this.posts = 0,
    this.comments = 0,
    this.likes = 0,
    this.betas = 0,
    this.followers = 0,
    this.following = 0,
    this.bookmarks = 0,
    this.totalDownloads = 0,
    this.totalLikesReceived = 0,
    this.totalCommentsReceived = 0,
    this.points = 0,
    this.level = 1,
    this.pointsForNextLevel = 0,
    this.progressToNext = 0,
    this.activityByDay = const [],
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    posts: json['posts'] as int? ?? 0,
    comments: json['comments'] as int? ?? 0,
    likes: json['likes'] as int? ?? 0,
    betas: json['betas'] as int? ?? 0,
    followers: json['followers'] as int? ?? 0,
    following: json['following'] as int? ?? 0,
    bookmarks: json['bookmarks'] as int? ?? 0,
    totalDownloads: json['totalDownloads'] as int? ?? 0,
    totalLikesReceived: json['totalLikesReceived'] as int? ?? 0,
    totalCommentsReceived: json['totalCommentsReceived'] as int? ?? 0,
    points: json['points'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    pointsForNextLevel: json['pointsForNextLevel'] as int? ?? 0,
    progressToNext: (json['progressToNext'] as num?)?.toDouble() ?? 0,
    activityByDay: (json['activityByDay'] as List? ?? [])
        .map((e) => ActivityDay.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Actividad de un día en `activityByDay`.
class ActivityDay {
  final String date;
  final int count;

  const ActivityDay({required this.date, required this.count});

  factory ActivityDay.fromJson(Map<String, dynamic> json) => ActivityDay(
    date: json['date'] as String? ?? '',
    count: json['count'] as int? ?? 0,
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

/// Respuesta de `GET /users/me/bookmarks` — lista de posts guardados.
class BookmarkListResponse {
  final List<Post> posts;

  const BookmarkListResponse({required this.posts});

  factory BookmarkListResponse.fromJson(Map<String, dynamic> json) =>
      BookmarkListResponse(
        posts: (json['posts'] as List? ?? [])
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
