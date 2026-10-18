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
    String? externalUrl,
    String? version,
    String? genre,
    String? coverImage,
  }) async {
    final data = await ApiService.postJson('/betas', body: {
      'title': title,
      'description': description,
      'downloadType': downloadType,
      'externalUrl': ?externalUrl,
      'version': ?version,
      'genre': ?genre,
      'coverImage': ?coverImage,
    });
    return Beta.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /betas/{id}/download` → registra la descarga y devuelve la URL.
  static Future<Map<String, dynamic>> registerDownload(String betaId) async {
    final data = await ApiService.postJson('/betas/$betaId/download');
    return data as Map<String, dynamic>;
  }
}
