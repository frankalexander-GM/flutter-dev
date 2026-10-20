/// `BetaOut` del backend FastAPI — alias camelCase (`postId`, `downloadType`,
/// `betaStatus`, `coverImage`, `createdAt`, `installInstructions`); `genre`,
/// `version`, `downloads`, `platforms`, `tags`, `screenshots` van sin alias.
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
  final int? fileSize;
  final String? fileName;
  final String? genre;
  final String? version;
  final String? coverImage;
  final List<String> platforms;
  final List<String> tags;
  final List<String> screenshots;
  final String? requirements;
  final String? changelog;
  final String? installInstructions;
  final String? externalPlatform;
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
    this.fileSize,
    this.fileName,
    this.genre,
    this.version,
    this.coverImage,
    this.platforms = const [],
    this.tags = const [],
    this.screenshots = const [],
    this.requirements,
    this.changelog,
    this.installInstructions,
    this.externalPlatform,
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
    fileSize: json['fileSize'] as int?,
    fileName: json['fileName'] as String?,
    genre: json['genre'] as String?,
    version: json['version'] as String?,
    coverImage: json['coverImage'] as String?,
    platforms: (json['platforms'] as List?)?.cast<String>() ?? const [],
    tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    screenshots: (json['screenshots'] as List?)?.cast<String>() ?? const [],
    requirements: json['requirements'] as String?,
    changelog: json['changelog'] as String?,
    installInstructions: json['installInstructions'] as String?,
    externalPlatform: json['externalPlatform'] as String?,
    downloads: json['downloads'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Beta copyWith({int? downloads}) => Beta(
    id: id,
    postId: postId,
    title: title,
    description: description,
    downloadType: downloadType,
    betaStatus: betaStatus,
    externalUrl: externalUrl,
    fileUrl: fileUrl,
    fileSize: fileSize,
    fileName: fileName,
    genre: genre,
    version: version,
    coverImage: coverImage,
    platforms: platforms,
    tags: tags,
    screenshots: screenshots,
    requirements: requirements,
    changelog: changelog,
    installInstructions: installInstructions,
    externalPlatform: externalPlatform,
    downloads: downloads ?? this.downloads,
    createdAt: createdAt,
  );
}
