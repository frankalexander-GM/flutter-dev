import '../models/beta.dart';
import 'api_service.dart';

/// Servicio de `GET/POST /betas` (array plano de `BetaOut`).
class BetaService {
  static Future<List<Beta>> getBetas({
    int skip = 0,
    int limit = 20,
    String? betaStatus,
  }) async {
    final query =
        'skip=$skip&limit=$limit${betaStatus != null ? '&beta_status=$betaStatus' : ''}';
    final data = await ApiService.getJson('/betas?$query');
    return (data as List)
        .map((e) => Beta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Beta> getBeta(String id) async {
    final data = await ApiService.getJson('/betas/$id');
    return Beta.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /betas` → 201 con la beta creada (crea además el post asociado).
  static Future<Beta> createBeta({
    required String title,
    required String description,
    String downloadType = 'LINK',
    String betaStatus = 'open_beta',
    String? externalUrl,
    String? fileUrl,
    int? fileSize,
    String? fileName,
    String? version,
    String? genre,
    String? coverImage,
    List<String> platforms = const [],
    List<String> tags = const [],
    List<String> screenshots = const [],
    String? requirements,
    String? changelog,
    String? installInstructions,
    String? externalPlatform,
  }) async {
    final data = await ApiService.postJson(
      '/betas',
      body: {
        'title': title,
        'description': description,
        'downloadType': downloadType,
        'betaStatus': betaStatus,
        'externalUrl': ?externalUrl,
        'fileUrl': ?fileUrl,
        'fileSize': ?fileSize,
        'fileName': ?fileName,
        'version': ?version,
        'genre': ?genre,
        'coverImage': ?coverImage,
        if (platforms.isNotEmpty) 'platforms': platforms,
        if (tags.isNotEmpty) 'tags': tags,
        if (screenshots.isNotEmpty) 'screenshots': screenshots,
        'requirements': ?requirements,
        'changelog': ?changelog,
        'installInstructions': ?installInstructions,
        'externalPlatform': ?externalPlatform,
      },
    );
    return Beta.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /betas/{id}/download` → registra la descarga y devuelve la URL.
  static Future<Map<String, dynamic>> registerDownload(String betaId) async {
    final data = await ApiService.postJson('/betas/$betaId/download');
    return data as Map<String, dynamic>;
  }
}
