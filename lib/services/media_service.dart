import 'package:file_picker/file_picker.dart' as picker;
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Archivo subido al servidor.
class UploadedMedia {
  final String url;
  final String kind; // "image" | "video"
  final String filename;
  final int size;

  const UploadedMedia({
    required this.url,
    required this.kind,
    required this.filename,
    required this.size,
  });

  bool get isVideo => kind == 'video';

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => UploadedMedia(
    url: json['url'] as String,
    kind: json['kind'] as String? ?? 'image',
    filename: json['filename'] as String? ?? '',
    size: json['size'] as int? ?? 0,
  );
}

/// Subida de imágenes y videos (avatar, portada y galería del perfil).
class MediaService {
  /// Formatos de imagen aceptados por el backend.
  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  /// Formatos de video aceptados por el backend.
  static const videoExtensions = ['mp4', 'webm'];

  /// Abre el selector de archivos y sube el elegido.
  ///
  /// Devuelve `null` si el usuario cancela. Lanza [ApiException] con el
  /// mensaje del backend si el archivo no es válido.
  static Future<UploadedMedia?> pickAndUpload({
    bool allowVideo = false,
  }) async {
    final file = await _pickFile(allowVideo: allowVideo);
    if (file == null) return null;
    return upload(file);
  }

  /// Abre el selector de archivos sin subirlo (para previsualizar).
  static Future<LocalMedia?> pickFile({bool allowVideo = false}) =>
      _pickFile(allowVideo: allowVideo);

  /// Sube un archivo ya seleccionado.
  static Future<UploadedMedia> upload(LocalMedia file) async {
    final bytes = await file.readBytes();
    final part = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
    );

    final data = await ApiService.postMultipart(
      '/users/me/media',
      fields: const {},
      files: [part],
    );
    return UploadedMedia.fromJson(data as Map<String, dynamic>);
  }

  /// Borra un archivo subido previamente por su URL.
  static Future<void> delete(String url) async {
    await ApiService.deleteJson(
      '/users/me/media?url=${Uri.encodeQueryComponent(url)}',
    );
  }

  static Future<LocalMedia?> _pickFile({required bool allowVideo}) async {
    // file_picker v13: `FilePicker.pickFiles` es estático y devuelve una
    // lista (vacía si el usuario cancela).
    final result = await picker.FilePicker.pickFiles(
      type: picker.FileType.custom,
      allowedExtensions: allowVideo
          ? [...imageExtensions, ...videoExtensions]
          : imageExtensions,
    );
    if (result.isEmpty) return null;
    final picked = result.first;
    return LocalMedia(
      name: picked.name,
      bytes: await picked.xFile.readAsBytes(),
      size: picked.lengthSync() ?? 0,
    );
  }
}

/// Archivo local seleccionado por el usuario.
///
/// Los bytes se leen al seleccionar el archivo: así funciona igual en web
/// (donde no hay ruta local) y en móvil.
class LocalMedia {
  final String name;
  final List<int> bytes;
  final int size;

  const LocalMedia({
    required this.name,
    required this.bytes,
    required this.size,
  });

  /// MIME declarado a partir de la extensión.
  String get mimeType {
    final ext = name.toLowerCase().split('.').last;
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      _ => 'application/octet-stream',
    };
  }

  /// Tamaño legible (KB / MB).
  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Bytes del archivo.
  Future<List<int>> readBytes() async => bytes;
}
