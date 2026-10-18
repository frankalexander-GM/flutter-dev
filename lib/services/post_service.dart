import '../models/comment.dart';
import '../models/post.dart';
import 'api_service.dart';

/// Servicio de `POST /posts` (listados paginados con `{items, total,...}`).
class PostService {
  /// `GET /posts?skip&limit` → lista de `PostOut`.
  static Future<List<Post>> getPosts({int skip = 0, int limit = 20}) async {
    final data = await ApiService.getJson('/posts?skip=$skip&limit=$limit');
    return (data['items'] as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Post> getPost(String id) async {
    final data = await ApiService.getJson('/posts/$id');
    return Post.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /posts` → 201 con el `PostOut` creado.
  static Future<Post> createPost({
    required String content,
    String type = 'POST',
    List<Map<String, dynamic>> media = const [],
  }) async {
    final data = await ApiService.postJson('/posts', body: {
      'type': type,
      if (content.isNotEmpty) 'content': content,
      if (media.isNotEmpty) 'media': media,
    });
    return Post.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deletePost(String id) =>
      ApiService.deleteJson('/posts/$id');

  /// `POST /posts/{id}/likes` → `{active, count}` (toggle).
  static Future<Map<String, dynamic>> toggleLike(String postId) async {
    final data = await ApiService.postJson('/posts/$postId/likes');
    return data as Map<String, dynamic>;
  }

  /// `POST /posts/{id}/bookmarks` → `{active, count}` (toggle).
  static Future<Map<String, dynamic>> toggleBookmark(String postId) async {
    final data = await ApiService.postJson('/posts/$postId/bookmarks');
    return data as Map<String, dynamic>;
  }

  /// `GET /posts/{id}/comments` → array plano de `CommentOut`.
  static Future<List<Comment>> getComments(String postId) async {
    final data = await ApiService.getJson('/posts/$postId/comments');
    return (data as List)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /posts/{id}/comments` → 201 con el comentario creado.
  static Future<Comment> addComment(String postId, {required String content}) async {
    final data = await ApiService.postJson('/posts/$postId/comments',
        body: {'content': content});
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteComment(String postId, String commentId) =>
      ApiService.deleteJson('/posts/$postId/comments/$commentId');
}
