import '../models/comment.dart';
import '../models/post.dart';
import 'api_service.dart';

/// Servicio de `GET/POST /posts` (listados paginados con `{items, total,...}`).
class PostService {
  /// `GET /posts?skip&limit&type&sort` → lista de `PostOut`.
  ///
  /// El backend todavía no filtra por `type` ni ordena por `trending`: esas
  /// dos opciones se resuelven en el cliente sobre la página descargada para
  /// que los filtros de la UI no mientan. Si el backend las incorpora, basta
  /// con dejar de hacer el filtrado local.
  static Future<List<Post>> getPosts({
    int skip = 0,
    int limit = 20,
    String? type,
    String? sort, // 'latest' | 'trending'
  }) async {
    final wantsType = type != null && type.isNotEmpty;

    // Con filtro local hace falta traer suficientes posts para no dejar la
    // sección vacía cuando el tipo es poco frecuente.
    final fetchSkip = wantsType ? 0 : skip;
    final fetchLimit = wantsType ? (skip + limit + 60).clamp(limit, 100) : limit;

    final query = 'skip=$fetchSkip&limit=$fetchLimit';
    final data = await ApiService.getJson('/posts?$query');
    var posts = (data['items'] as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();

    if (wantsType) {
      final wanted = postTypeFrom(type);
      posts = posts.where((p) => p.type == wanted).toList();
      posts = posts.skip(skip).take(limit).toList();
    }

    if (sort == 'trending') {
      posts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    } else if (sort == 'latest') {
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return posts;
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
    final body = <String, dynamic>{
      'type': type,
      if (content.isNotEmpty) 'content': content,
      if (media.isNotEmpty) 'media': media,
    };
    final data = await ApiService.postJson('/posts', body: body);
    return Post.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deletePost(String id) => ApiService.deleteJson('/posts/$id');

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
    final data = await ApiService.postJson('/posts/$postId/comments', body: {
      'content': content,
    });
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteComment(String postId, String commentId) =>
      ApiService.deleteJson('/posts/$postId/comments/$commentId');

  /// Crea un post de tipo `POLL` y le adjunta la encuesta real
  /// (`POST /posts` + `POST /posts/{id}/poll`).
  static Future<Post> createPoll({
    required String question,
    required List<String> options,
    bool allowMultiple = false,
  }) async {
    final post = await createPost(content: question, type: 'POLL');
    try {
      await ApiService.postJson('/posts/${post.id}/poll', body: {
        'question': question,
        'options': options.map((text) => {'text': text}).toList(),
        'allow_multiple': allowMultiple,
      });
    } catch (_) {
      // No dejamos un post POLL huérfano si falla la encuesta.
      try {
        await deletePost(post.id);
      } catch (_) {
        // Si tampoco se puede borrar, se ignora.
      }
      rethrow;
    }
    return post;
  }

  /// `GET /posts/{id}/poll` → encuesta del post, o `null` si no tiene.
  static Future<PollAttachment?> getPoll(String postId) async {
    try {
      final data = await ApiService.getJson('/posts/$postId/poll');
      return PollAttachment.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// `POST /polls/{pollId}/vote` → encuesta actualizada.
  static Future<PollAttachment> votePoll(
    String pollId,
    List<String> optionIds,
  ) async {
    final data = await ApiService.postJson(
      '/polls/$pollId/vote',
      body: {'option_ids': optionIds},
    );
    return PollAttachment.fromJson(
      (data as Map<String, dynamic>)['poll'] as Map<String, dynamic>,
    );
  }

  /// `POST /security/report` → reporta contenido (post, usuario, comentario o beta).
  static Future<void> reportContent({
    required String entityId,
    required String entityType,
    required String reason,
    String? description,
  }) async {
    await ApiService.postJson('/security/report', body: {
      'type': entityType.toUpperCase(),
      'entityId': entityId,
      'reason': reason,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }
}
