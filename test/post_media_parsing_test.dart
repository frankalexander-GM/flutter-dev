import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/models/post.dart';

void main() {
  test('el post del perfil parsea la media en camelCase (mediaUrls)', () {
    // Respuesta real de `GET /users/{id}` (PostSummary: mediaUrls en camelCase).
    final json = <String, dynamic>{
      'id': 'p1',
      'type': 'POST',
      'content': 'Foto de mi galeria',
      'mediaUrls': [
        {
          'url': 'http://127.0.0.1:8000/uploads/abc.png',
          'kind': 'image',
        },
      ],
      'createdAt': '2026-10-21T10:00:00',
      'author': {'id': 'u1', 'username': 'frank_dev'},
      'likesCount': 2,
      'commentsCount': 1,
      'repostsCount': 0,
      'liked': false,
    };

    final post = Post.fromJson(json);
    expect(post.media.length, 1);
    expect(post.media.first.url, 'http://127.0.0.1:8000/uploads/abc.png');
    expect(post.media.first.kind, 'image');
  });

  test('el post del feed parsea la media en snake_case (media)', () {
    // Respuesta real de `GET /posts` (PostOut: media).
    final json = <String, dynamic>{
      'id': 'p2',
      'type': 'POST',
      'content': 'Con imagen',
      'media': [
        {'url': 'http://127.0.0.1:8000/uploads/xyz.png', 'kind': 'image'},
      ],
      'created_at': '2026-10-21T10:00:00',
      'author': {'id': 'u1', 'username': 'frank_dev'},
      'likes_count': 0,
      'comments_count': 0,
      'liked_by_me': false,
      'bookmarked_by_me': false,
    };

    final post = Post.fromJson(json);
    expect(post.media.length, 1);
    expect(post.media.first.url, 'http://127.0.0.1:8000/uploads/xyz.png');
  });
}
