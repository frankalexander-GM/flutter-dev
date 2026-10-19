import '../models/comment.dart';
import '../models/post.dart';
import '../models/trending_game.dart';
import 'api_service.dart';

/// Servicio de `POST /posts` (listados paginados con `{items, total,...}`).
class PostService {
  /// `GET /posts?skip&limit&type&sort` → lista de `PostOut`.
  /// Si `type` es null, devuelve todos los tipos.
  static Future<List<Post>> getPosts({
    int skip = 0,
    int limit = 20,
    String? type,
    String? sort, // 'latest' | 'trending'
  }) async {
    final queryParams = <String>[];
    queryParams.add('skip=$skip');
    queryParams.add('limit=$limit');
    if (type != null) queryParams.add('type=$type');
    if (sort != null) queryParams.add('sort=$sort');
    final query = queryParams.join('&');
    final data = await ApiService.getJson('/posts?$query');
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
    Map<String, dynamic>? gameData,
    Map<String, dynamic>? pollData,
    Map<String, dynamic>? betaData,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      if (content.isNotEmpty) 'content': content,
      if (gameData != null) 'game': gameData,
      if (pollData != null) 'poll': pollData,
      if (betaData != null) 'beta': betaData,
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

  /// `POST /posts/{id}/shares` → `{active, count}` (toggle).
  static Future<Map<String, dynamic>> toggleShare(String postId) async {
    final data = await ApiService.postJson('/posts/$postId/shares');
    return data as Map<String, dynamic>;
  }

  /// `POST /posts/{id}/bookmarks` → `{active, count}` (toggle).
  static Future<Map<String, dynamic>> toggleBookmark(String postId) async {
    final data = await ApiService.postJson('/posts/$postId/bookmarks');
    return data as Map<String, dynamic>;
  }

  /// `POST /posts/{id}/views` → incrementa vista (idempotente por sesión).
  static Future<void> recordView(String postId) async {
    await ApiService.postJson('/posts/$postId/views');
  }

  /// `GET /posts/{id}/comments` → array plano de `CommentOut`.
  static Future<List<Comment>> getComments(String postId) async {
    final data = await ApiService.getJson('/posts/$postId/comments');
    return (data as List)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /posts/{id}/comments` → 201 con el comentario creado.
  static Future<Comment> addComment(String postId, {required String content, String? parentId}) async {
    final data = await ApiService.postJson('/posts/$postId/comments', body: {
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteComment(String postId, String commentId) =>
      ApiService.deleteJson('/posts/$postId/comments/$commentId');

  /// `POST /posts/{id}/comments/{commentId}/likes` → like a comentario.
  static Future<Map<String, dynamic>> toggleCommentLike(String postId, String commentId) async {
    final data = await ApiService.postJson('/posts/$postId/comments/$commentId/likes');
    return data as Map<String, dynamic>;
  }

  /// `POST /posts/{id}/polls/{pollId}/vote` → vota en encuesta.
  static Future<Map<String, dynamic>> votePoll(String postId, String pollId, String optionId) async {
    final data = await ApiService.postJson('/posts/$postId/polls/$pollId/vote', body: {'option_id': optionId});
    return data as Map<String, dynamic>;
  }

  /// `POST /games/{gameId}/beta/join` → solicita acceso a beta.
  static Future<Map<String, dynamic>> joinBeta(String gameId) async {
    final data = await ApiService.postJson('/games/$gameId/beta/join');
    return data as Map<String, dynamic>;
  }

  /// `GET /games/trending` → juegos en tendencia.
  static Future<List<TrendingGame>> getTrendingGames({int limit = 10}) async {
    final data = await ApiService.getJson('/games/trending?limit=$limit', auth: false);
    return (data['items'] as List? ?? [])
        .map((e) => TrendingGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /games/featured` → juego destacado.
  static Future<Post?> getFeaturedGame() async {
    try {
      final data = await ApiService.getJson('/games/featured');
      return Post.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// `GET /games/dev-logs` → juegos en desarrollo (dev logs).
  static Future<List<Post>> getDevGames({int limit = 10}) async {
    final data = await ApiService.getJson('/games/dev-logs?limit=$limit');
    return (data['items'] as List? ?? [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /games/betas` → betas abiertas.
  static Future<List<Post>> getBetaGames({int limit = 10}) async {
    final data = await ApiService.getJson('/games/betas?limit=$limit');
    return (data['items'] as List? ?? [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /users/me/saved` → elementos guardados del usuario.
  static Future<List<SavedItem>> getSavedItems() async {
    final data = await ApiService.getJson('/users/me/saved');
    return (data['items'] as List? ?? [])
        .map((e) => SavedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /users/me/saved` → guarda/desguarda item.
  static Future<Map<String, dynamic>> toggleSave({
    required String itemId,
    required SavedItemType type,
    String? collectionId,
  }) async {
    final data = await ApiService.postJson('/users/me/saved', body: {
      'item_id': itemId,
      'type': type.name,
      if (collectionId != null) 'collection_id': collectionId,
    });
    return data as Map<String, dynamic>;
  }

  /// `GET /users/me/collections` → colecciones del usuario.
  static Future<List<Collection>> getCollections() async {
    final data = await ApiService.getJson('/users/me/collections');
    return (data['items'] as List? ?? [])
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /users/me/collections` → crea colección.
  static Future<Collection> createCollection({required String name, String? description, String? coverUrl}) async {
    final data = await ApiService.postJson('/users/me/collections', body: {
      'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
    });
    return Collection.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /search` → búsqueda global.
  static Future<SearchResults> search({
    required String query,
    int limit = 20,
    SearchFilters? filters,
  }) async {
    final params = <String>['q=query'];
    params.add('limit=$limit');
    if (filters != null) {
      final filterParams = filters.toQueryParams();
      filterParams.forEach((k, v) => params.add('$k=$v'));
    }
    final query = params.join('&');
    final data = await ApiService.getJson('/search?$query', auth: false);
    return SearchResults.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /tags` → etiquetas populares.
  static Future<List<Tag>> getPopularTags({int limit = 20}) async {
    final data = await ApiService.getJson('/tags?limit=$limit', auth: false);
    return (data['items'] as List? ?? [])
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /reports` → reportar contenido.
  static Future<Report> reportContent({
    required String entityId,
    required String entityType, // post, comment, user, game, beta
    required ReportReason reason,
    String? description,
  }) async {
    final data = await ApiService.postJson('/reports', body: {
      'entity_id': entityId,
      'entity_type': entityType,
      'reason': reason.name,
      if (description != null) 'description': description,
    });
    return Report.fromJson(data as Map<String, dynamic>);
  }
}