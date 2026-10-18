/// `BetaOut` del backend FastAPI — alias camelCase (`postId`, `downloadType`,
/// `betaStatus`, `coverImage`, `createdAt`); `genre`, `version`, `downloads`
/// van en snake_case (sin alias).
library;

class Beta {
  final String id;
  final String postId;
  final String title;
  final String description;
  final String downloadType;
  final String betaStatus;
  final String? externalUrl;
  final String? fileUrl;
  final String? genre;
  final String? version;
  final String? coverImage;
  final int downloads;
  final DateTime createdAt;

  const Beta({
    required this.id,
    required this.postId,
    required this.title,
    required this.description,
    required this.downloadType,
    required this.betaStatus,
    this.externalUrl,
    this.fileUrl,
    this.genre,
    this.version,
    this.coverImage,
    required this.downloads,
    required this.createdAt,
  });

  factory Beta.fromJson(Map<String, dynamic> json) => Beta(
        id: json['id'] as String,
        postId: json['postId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        downloadType: json['downloadType'] as String? ?? 'LINK',
        betaStatus: json['betaStatus'] as String? ?? 'open_beta',
        externalUrl: json['externalUrl'] as String?,
        fileUrl: json['fileUrl'] as String?,
        genre: json['genre'] as String?,
        version: json['version'] as String?,
        coverImage: json['coverImage'] as String?,
        downloads: json['downloads'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
