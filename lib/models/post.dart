/// Modelos de publicación — claves idénticas a los schemas del backend
/// FastAPI: `PostOut` (snake_case, feed) y `PostSummary` (camelCase,
/// perfiles/bookmarks). El parser acepta ambas formas.
library;

enum PostType { post, beta, stream, poll }

PostType postTypeFrom(String value) {
  switch (value.toUpperCase()) {
    case 'BETA':
      return PostType.beta;
    case 'STREAM':
      return PostType.stream;
    case 'POLL':
      return PostType.poll;
    default:
      return PostType.post;
  }
}

/// `AuthorSummary` de `PostOut`: `{id, username, full_name, avatar}`.
class PostAuthor {
  final String id;
  final String username;
  final String? fullName;
  final String? avatar;
  final String role;

  const PostAuthor({
    required this.id,
    required this.username,
    this.fullName,
    this.avatar,
    this.role = 'USER',
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
        id: (json['id'] ?? json['authorId'] ?? '') as String,
        username: (json['username'] ?? json['authorName'] ?? '') as String,
        fullName: (json['full_name'] ?? json['fullName']) as String?,
        avatar: (json['avatar'] ?? json['authorAvatar']) as String?,
        role: json['role'] as String? ?? 'USER',
      );
}

/// Elemento de media: `{url, kind}` (`kind`: `image` | `video`).
class PostMedia {
  final String url;
  final String kind;
  const PostMedia({required this.url, this.kind = 'image'});

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
        url: json['url'] as String? ?? '',
        kind: json['kind'] as String? ?? 'image',
      );
}

/// Ficha de beta embebida en `PostSummary.beta` (perfil).
class BetaInfo {
  final String id;
  final String title;
  final String? version;
  final String? genre;
  final int downloads;
  final String? description;

  const BetaInfo({
    required this.id,
    required this.title,
    this.version,
    this.genre,
    this.downloads = 0,
    this.description,
  });

  factory BetaInfo.fromJson(Map<String, dynamic> json) => BetaInfo(
        id: json['id'] as String,
        title: json['title'] as String,
        version: json['version'] as String?,
        genre: json['genre'] as String?,
        downloads: json['downloads'] as int? ?? 0,
        description: json['description'] as String?,
      );
}

class Post {
  final String id;
  final PostType type;
  final String content;
  final List<PostMedia> media;
  final PostAuthor? author;
  final int likesCount;
  final int commentsCount;
  final bool liked;
  final bool bookmarked;
  final DateTime createdAt;
  final BetaInfo? beta;

  const Post({
    required this.id,
    required this.type,
    this.content = '',
    this.media = const [],
    this.author,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.liked = false,
    this.bookmarked = false,
    required this.createdAt,
    this.beta,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final mediaJson = (json['media'] ?? json['mediaUrls'] ?? const []) as List;
    return Post(
      id: json['id'] as String,
      type: postTypeFrom(json['type'] as String? ?? 'POST'),
      content: json['content'] as String? ?? '',
      media: mediaJson
          .whereType<Map<String, dynamic>>()
          .map(PostMedia.fromJson)
          .toList(),
      author: json['author'] != null
          ? PostAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      likesCount: (json['likes_count'] ?? json['likesCount'] ?? 0) as int,
      commentsCount:
          (json['comments_count'] ?? json['commentsCount'] ?? 0) as int,
      liked: (json['liked_by_me'] ?? json['liked'] ?? false) as bool,
      bookmarked:
          (json['bookmarked_by_me'] ?? json['savedAt'] != null ?? false)
              as bool,
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']) as String,
      ),
      beta: json['beta'] != null
          ? BetaInfo.fromJson(json['beta'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Datos de ejemplo para la maqueta visual (fallback sin backend).
final List<Post> mockPosts = [
  Post(
    id: 'p1',
    type: PostType.beta,
    author: const PostAuthor(id: 'u1', username: 'dev_pixel'),
    content:
        'Subimos la beta 0.4.2 de Pixel Dash. Ahora con el modo arcade '
        'infinito y mejoras de rendimiento. Los devs ya pueden probarla!',
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    likesCount: 48,
    commentsCount: 7,
    liked: true,
    beta: const BetaInfo(
      id: 'b1',
      title: 'Pixel Dash',
      version: 'v0.4.2',
      genre: 'Arcade',
      downloads: 1284,
    ),
  ),
  Post(
    id: 'p2',
    type: PostType.post,
    author: const PostAuthor(id: 'u2', username: 'luna_dev'),
    content:
        'Primera luz del nuevo escenario del proyecto Neon Drift. Todavia en '
        'progreso, pero el ambiente nocturno ya se siente.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
    media: const [PostMedia(url: '', kind: 'image')],
    likesCount: 156,
    commentsCount: 23,
  ),
  Post(
    id: 'p3',
    type: PostType.stream,
    author: const PostAuthor(id: 'u3', username: 'raikoh'),
    content:
        'Estamos en vivo jugando la beta de Codigo Rojo con el equipo. '
        'Pasamos por aca un rato, los esperamos!',
    createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    likesCount: 89,
    commentsCount: 14,
  ),
  Post(
    id: 'p4',
    type: PostType.post,
    author: const PostAuthor(id: 'u4', username: 'nick_og'),
    content:
        'A quien mas le pasa que prueba la beta y se le va el dia entero? '
        'Esto es adictivo',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    likesCount: 27,
    commentsCount: 5,
  ),
];
