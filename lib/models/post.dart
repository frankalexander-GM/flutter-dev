/// Modelos de DevPlay — mismo shape que la API FastAPI
/// (`/api/v1/posts`, enums en minúsculas). Por ahora se usan con datos de
/// ejemplo; cuando el compañero integre las funciones, estos modelos ya
/// calzan con la respuesta real del backend.
library;

enum PostType { post, beta, stream }

class PostAuthor {
  final String username;
  final String? avatar;
  final String role; // 'DEV' | 'USER'
  const PostAuthor({required this.username, this.avatar, this.role = 'USER'});
}

class PostMedia {
  final String kind; // 'image' | 'video' (enums de la API en minúsculas)
  final String url; // vacío = placeholder de diseño
  const PostMedia({required this.kind, this.url = ''});
}

class BetaInfo {
  final String title;
  final String version;
  final String? genre;
  final int downloads;
  const BetaInfo({
    required this.title,
    required this.version,
    this.genre,
    required this.downloads,
  });
}

class Post {
  final String id;
  final PostAuthor author;
  final String content;
  final DateTime createdAt;
  final PostType type;
  final List<PostMedia> media;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool liked;
  final bool saved;
  final BetaInfo? beta;
  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.type,
    this.media = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.liked = false,
    this.saved = false,
    this.beta,
  });

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? liked,
    bool? saved,
  }) {
    return Post(
      id: id,
      author: author,
      content: content,
      createdAt: createdAt,
      type: type,
      media: media,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      beta: beta,
    );
  }
}

/// Comentario simple (mock local; la API real llega después).
class PostComment {
  final String username;
  final String text;
  final DateTime createdAt;
  const PostComment({
    required this.username,
    required this.text,
    required this.createdAt,
  });
}

/// Datos de ejemplo para la maqueta visual. Son idénticos en forma a lo que
/// devuelve `/api/v1/posts` del backend.
final List<Post> mockPosts = [
  Post(
    id: 'p1',
    author: const PostAuthor(username: 'dev_pixel', role: 'DEV'),
    content:
        'Subimos la beta 0.4.2 de Pixel Dash. Ahora con el modo arcade '
        'infinito y mejoras de rendimiento. Los devs ya pueden probarla!',
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    type: PostType.beta,
    media: const [],
    likesCount: 48,
    commentsCount: 7,
    sharesCount: 12,
    liked: true,
    saved: false,
    beta: const BetaInfo(
      title: 'Pixel Dash',
      version: 'v0.4.2',
      genre: 'Arcade',
      downloads: 1284,
    ),
  ),
  Post(
    id: 'p2',
    author: const PostAuthor(username: 'luna_dev', role: 'DEV'),
    content:
        'Primera luz del nuevo escenario del proyecto Neon Drift. Todavia en '
        'progreso, pero el ambiente nocturno ya se siente.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
    type: PostType.post,
    media: const [PostMedia(kind: 'image')],
    likesCount: 156,
    commentsCount: 23,
    sharesCount: 31,
  ),
  Post(
    id: 'p3',
    author: const PostAuthor(username: 'raikoh', role: 'DEV'),
    content:
        'Estamos en vivo jugando la beta de Codigo Rojo con el equipo. '
        'Pasamos por aca un rato, los esperamos!',
    createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    type: PostType.stream,
    media: const [],
    likesCount: 89,
    commentsCount: 14,
    sharesCount: 9,
  ),
  Post(
    id: 'p4',
    author: const PostAuthor(username: 'nick_og'),
    content:
        'A quien mas le pasa que prueba la beta y se le va el dia entero? '
        'Esto es adictivo!',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    type: PostType.post,
    media: const [],
    likesCount: 27,
    commentsCount: 5,
    sharesCount: 3,
  ),
];