/// Modelos de publicación — claves idénticas a los schemas del backend
/// FastAPI: `PostOut` (snake_case, feed) y `PostSummary` (camelCase,
/// perfiles/bookmarks). El parser acepta ambas formas.
library;

enum PostType { post, beta, stream, poll, game_showcase, dev_log, update, announcement }

PostType postTypeFrom(String value) {
  switch (value.toUpperCase()) {
    case 'BETA':
      return PostType.beta;
    case 'STREAM':
      return PostType.stream;
    case 'POLL':
      return PostType.poll;
    case 'GAME_SHOWCASE':
      return PostType.game_showcase;
    case 'DEV_LOG':
      return PostType.dev_log;
    case 'UPDATE':
      return PostType.update;
    case 'ANNOUNCEMENT':
      return PostType.announcement;
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
  final String? bio;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final List<String>? tags;

  const PostAuthor({
    required this.id,
    required this.username,
    this.fullName,
    this.avatar,
    this.role = 'USER',
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
    this.tags,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
        id: (json['id'] ?? json['authorId'] ?? '') as String,
        username: (json['username'] ?? json['authorName'] ?? '') as String,
        fullName: (json['full_name'] ?? json['fullName']) as String?,
        avatar: (json['avatar'] ?? json['authorAvatar']) as String?,
        role: json['role'] as String? ?? 'USER',
        bio: json['bio'] as String?,
        followersCount: (json['followers_count'] ?? json['followersCount'] ?? 0) as int,
        followingCount: (json['following_count'] ?? json['followingCount'] ?? 0) as int,
        isVerified: json['is_verified'] as bool? ?? false,
        tags: (json['tags'] as List?)?.cast<String>(),
      );
}

/// Elemento de media: `{url, kind}` (`kind`: `image` | `video` | `gif`).
class PostMedia {
  final String url;
  final String kind;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? duration;

  const PostMedia({
    required this.url,
    this.kind = 'image',
    this.thumbnailUrl,
    this.width,
    this.height,
    this.duration,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
        url: json['url'] as String? ?? '',
        kind: json['kind'] as String? ?? 'image',
        thumbnailUrl: json['thumbnail_url'] as String?,
        width: json['width'] as int?,
        height: json['height'] as int?,
        duration: json['duration'] as int?,
      );
}

/// Información de juego adjunta al post (game showcase, beta, etc.)
class GameAttachment {
  final String id;
  final String title;
  final String? coverUrl;
  final String? description;
  final String? developer;
  final String? genre;
  final String? platform;
  final String? status;
  final String? version;
  final String? playUrl;
  final String? storeUrl;
  final List<String> tags;
  final int viewsCount;
  final int followersCount;

  const GameAttachment({
    required this.id,
    required this.title,
    this.coverUrl,
    this.description,
    this.developer,
    this.genre,
    this.platform,
    this.status,
    this.version,
    this.playUrl,
    this.storeUrl,
    this.tags = const [],
    this.viewsCount = 0,
    this.followersCount = 0,
  });

  factory GameAttachment.fromJson(Map<String, dynamic> json) => GameAttachment(
        id: json['id'] as String,
        title: json['title'] as String,
        coverUrl: json['cover_url'] as String?,
        description: json['description'] as String?,
        developer: json['developer'] as String?,
        genre: json['genre'] as String?,
        platform: json['platform'] as String?,
        status: json['status'] as String?,
        version: json['version'] as String?,
        playUrl: json['play_url'] as String?,
        storeUrl: json['store_url'] as String?,
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        viewsCount: (json['views_count'] ?? json['viewsCount'] ?? 0) as int,
        followersCount: (json['followers_count'] ?? json['followersCount'] ?? 0) as int,
      );
}

/// Encuesta adjunta al post
class PollAttachment {
  final String id;
  final String question;
  final List<PollOption> options;
  final bool allowMultiple;
  final bool showResults;
  final DateTime? closesAt;
  final DateTime? endsAt;
  final int totalVotes;
  final bool isClosed;
  final List<String> votedOptionIds;
  final String? userVote;

  const PollAttachment({
    required this.id,
    required this.question,
    required this.options,
    this.allowMultiple = false,
    this.showResults = true,
    this.closesAt,
    this.endsAt,
    this.totalVotes = 0,
    this.isClosed = false,
    this.votedOptionIds = const [],
    this.userVote,
  });

  bool get hasVoted => votedOptionIds.isNotEmpty || userVote != null;

  bool get canVote => !isClosed && !hasVoted;

  factory PollAttachment.fromJson(Map<String, dynamic> json) {
    final closes = json['closes_at'] ?? json['closesAt'];
    final voted = (json['voted_option_ids'] ?? json['votedOptionIds'] ?? const [])
        .cast<String>();
    final single = json['user_vote'] as String?;
    return PollAttachment(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List? ?? [])
          .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      showResults: json['show_results'] as bool? ?? true,
      closesAt: closes != null ? DateTime.tryParse(closes as String) : null,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
      totalVotes: (json['total_votes'] ?? json['totalVotes'] ?? 0) as int,
      isClosed: json['is_closed'] as bool? ?? false,
      votedOptionIds: voted.isNotEmpty ? voted : (single != null ? [single] : const []),
      userVote: single,
    );
  }
}

class PollOption {
  final String id;
  final String text;
  final int votesCount;
  final double percentage;

  const PollOption({
    required this.id,
    required this.text,
    this.votesCount = 0,
    this.percentage = 0.0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id'] as String,
        text: json['text'] as String,
        votesCount:
            (json['vote_count'] ?? json['votes_count'] ?? json['votesCount'] ?? 0) as int,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Información de beta embebida en post
class BetaInfo {
  final String id;
  final String title;
  final String? version;
  final String? genre;
  final int downloads;
  final String? description;
  final String? requirements;
  final String? instructions;
  final String? accessUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOpen;
  final int testersCount;
  final int maxTesters;

  const BetaInfo({
    required this.id,
    required this.title,
    this.version,
    this.genre,
    this.downloads = 0,
    this.description,
    this.requirements,
    this.instructions,
    this.accessUrl,
    this.startDate,
    this.endDate,
    this.isOpen = false,
    this.testersCount = 0,
    this.maxTesters = 0,
  });

  factory BetaInfo.fromJson(Map<String, dynamic> json) => BetaInfo(
        id: json['id'] as String,
        title: json['title'] as String,
        version: json['version'] as String?,
        genre: json['genre'] as String?,
        downloads: json['downloads'] as int? ?? 0,
        description: json['description'] as String?,
        requirements: json['requirements'] as String?,
        instructions: json['instructions'] as String?,
        accessUrl: json['access_url'] as String?,
        startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
        endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
        isOpen: json['is_open'] as bool? ?? false,
        testersCount: (json['testers_count'] ?? json['testersCount'] ?? 0) as int,
        maxTesters: (json['max_testers'] ?? json['maxTesters'] ?? 0) as int,
      );
}

/// Post principal — modelo completo para feed
class Post {
  final String id;
  final PostType type;
  final String content;
  final List<PostMedia> media;
  final PostAuthor? author;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final int viewsCount;
  final bool liked;
  final bool bookmarked;
  final bool shared;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BetaInfo? beta;
  final GameAttachment? game;
  final PollAttachment? poll;
  final List<String> tags;
  final String? location;
  final bool isPinned;
  final bool isAnnouncement;
  final String? language;
  final String? parentId;
  final Post? originalPost;

  const Post({
    required this.id,
    required this.type,
    this.content = '',
    this.media = const [],
    this.author,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.liked = false,
    this.bookmarked = false,
    this.shared = false,
    required this.createdAt,
    this.updatedAt,
    this.beta,
    this.game,
    this.poll,
    this.tags = const [],
    this.location,
    this.isPinned = false,
    this.isAnnouncement = false,
    this.language,
    this.parentId,
    this.originalPost,
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
      commentsCount: (json['comments_count'] ?? json['commentsCount'] ?? 0) as int,
      sharesCount: (json['shares_count'] ?? json['sharesCount'] ?? 0) as int,
      savesCount: (json['saves_count'] ?? json['savesCount'] ?? 0) as int,
      viewsCount: (json['views_count'] ?? json['viewsCount'] ?? 0) as int,
      liked: (json['liked_by_me'] ?? json['liked'] ?? false) as bool,
      bookmarked: (json['bookmarked_by_me'] ?? json['bookmarked'] ?? json['savedAt'] != null) as bool,
      shared: (json['shared_by_me'] ?? json['shared'] ?? false) as bool,
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']) as String,
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      beta: json['beta'] != null
          ? BetaInfo.fromJson(json['beta'] as Map<String, dynamic>)
          : null,
      game: json['game'] != null
          ? GameAttachment.fromJson(json['game'] as Map<String, dynamic>)
          : null,
      poll: json['poll'] != null
          ? PollAttachment.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      location: json['location'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      isAnnouncement: json['is_announcement'] as bool? ?? false,
      language: json['language'] as String?,
      parentId: json['parent_id'] as String?,
      originalPost: json['original_post'] != null
          ? Post.fromJson(json['original_post'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Título del post (para game_showcase usa el título del juego, si no el contenido truncado)
  String get title {
    if (type == PostType.game_showcase && game != null) {
      return game!.title;
    }
    if (content.length > 50) {
      return '${content.substring(0, 50)}...';
    }
    return content;
  }
}

/// Elemento guardado (post, juego, beta) en colecciones del usuario.
enum SavedItemType { post, game, beta }

class SavedItem {
  final String id;
  final SavedItemType type;
  final String itemId;
  final String? collectionId;
  final DateTime savedAt;
  final Post? post;
  final GameAttachment? game;
  final BetaInfo? beta;

  const SavedItem({
    required this.id,
    required this.type,
    required this.itemId,
    this.collectionId,
    required this.savedAt,
    this.post,
    this.game,
    this.beta,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) => SavedItem(
        id: json['id'] as String,
        type: SavedItemType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SavedItemType.post,
        ),
        itemId: json['item_id'] as String,
        collectionId: json['collection_id'] as String?,
        savedAt: DateTime.parse(json['saved_at'] as String),
        post: json['post'] != null
            ? Post.fromJson(json['post'] as Map<String, dynamic>)
            : null,
        game: json['game'] != null
            ? GameAttachment.fromJson(json['game'] as Map<String, dynamic>)
            : null,
        beta: json['beta'] != null
            ? BetaInfo.fromJson(json['beta'] as Map<String, dynamic>)
            : null,
      );
}

/// Colección de elementos guardados.
class Collection {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int itemsCount;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.itemsCount = 0,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        coverUrl: json['cover_url'] as String?,
        itemsCount: (json['items_count'] ?? json['itemsCount'] ?? 0) as int,
        isDefault: json['is_default'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

/// Resultados de búsqueda.
class SearchResults {
  final List<Post> posts;
  final List<GameAttachment> games;
  final List<PostAuthor> users;
  final List<Tag> tags;
  final int totalPosts;
  final int totalGames;
  final int totalUsers;

  const SearchResults({
    this.posts = const [],
    this.games = const [],
    this.users = const [],
    this.tags = const [],
    this.totalPosts = 0,
    this.totalGames = 0,
    this.totalUsers = 0,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults(
        posts: (json['posts'] as List? ?? [])
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList(),
        games: (json['games'] as List? ?? [])
            .map((e) => GameAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
        users: (json['users'] as List? ?? [])
            .map((e) => PostAuthor.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: (json['tags'] as List? ?? [])
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPosts: (json['total_posts'] ?? json['totalPosts'] ?? 0) as int,
        totalGames: (json['total_games'] ?? json['totalGames'] ?? 0) as int,
        totalUsers: (json['total_users'] ?? json['totalUsers'] ?? 0) as int,
      );
}

/// Filtros de búsqueda avanzada.
class SearchFilters {
  final String? query;
  final List<PostType>? types;
  final List<String>? tags;
  final List<String>? genres;
  final List<String>? platforms;
  final String? status;
  final String? sortBy;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? language;
  final bool? onlyWithMedia;
  final bool? onlyPolls;
  final bool? onlyBetas;

  const SearchFilters({
    this.query,
    this.types,
    this.tags,
    this.genres,
    this.platforms,
    this.status,
    this.sortBy,
    this.fromDate,
    this.toDate,
    this.language,
    this.onlyWithMedia,
    this.onlyPolls,
    this.onlyBetas,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) params['q'] = query;
    if (types != null && types!.isNotEmpty) params['types'] = types!.join(',');
    if (tags != null && tags!.isNotEmpty) params['tags'] = tags!.join(',');
    if (genres != null && genres!.isNotEmpty) params['genres'] = genres!.join(',');
    if (platforms != null && platforms!.isNotEmpty) params['platforms'] = platforms!.join(',');
    if (status != null) params['status'] = status;
    if (sortBy != null) params['sort'] = sortBy;
    if (fromDate != null) params['from'] = fromDate!.toIso8601String();
    if (toDate != null) params['to'] = toDate!.toIso8601String();
    if (language != null) params['lang'] = language;
    if (onlyWithMedia == true) params['media'] = 'true';
    if (onlyPolls == true) params['polls'] = 'true';
    if (onlyBetas == true) params['betas'] = 'true';
    return params;
  }
}

/// Etiqueta/tag.
class Tag {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? color;
  final int postsCount;
  final int followersCount;
  final bool isFeatured;

  const Tag({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.color,
    this.postsCount = 0,
    this.followersCount = 0,
    this.isFeatured = false,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String?,
        description: json['description'] as String?,
        color: json['color'] as String?,
        postsCount: (json['posts_count'] ?? json['postsCount'] ?? 0) as int,
        followersCount: (json['followers_count'] ?? json['followersCount'] ?? 0) as int,
        isFeatured: json['is_featured'] as bool? ?? false,
      );
}

/// Reporte de contenido.
class Report {
  final String id;
  final String reporterId;
  final String reportedEntityId;
  final String reportedEntityType; // post, comment, user, game, beta
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedEntityId,
    required this.reportedEntityType,
    required this.reason,
    this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterId: json['reporter_id'] as String,
        reportedEntityId: json['reported_entity_id'] as String,
        reportedEntityType: json['reported_entity_type'] as String,
        reason: ReportReason.values.firstWhere(
          (e) => e.name == json['reason'],
          orElse: () => ReportReason.other,
        ),
        description: json['description'] as String?,
        status: ReportStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ReportStatus.pending,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
      );
}

enum ReportReason {
  spam,
  harassment,
  hate_speech,
  misinformation,
  nsfw,
  copyright,
  malware,
  fake_account,
  off_topic,
  other,
}

enum ReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed,
}