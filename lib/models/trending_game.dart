import 'package:flutter/material.dart';

/// Modelo de juego en tendencia para el carrusel de Descubrir — PRD.
class TrendingGame {
  final String id;
  final String name;
  final String version;
  final String views;
  final bool isTrending;
  final String imageUrl;
  final LinearGradient gradient;

  const TrendingGame({
    required this.id,
    required this.name,
    required this.version,
    required this.views,
    required this.isTrending,
    required this.imageUrl,
    required this.gradient,
  });

  factory TrendingGame.fromJson(Map<String, dynamic> json) => TrendingGame(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as String? ?? 'v1.0.0',
        views: json['views'] as String? ?? '0',
        isTrending: json['is_trending'] as bool? ?? false,
        imageUrl: json['image_url'] as String? ?? '',
        gradient: _gradientFromJson(json['gradient']),
      );

  static LinearGradient _gradientFromJson(dynamic g) {
    if (g is List) {
      return LinearGradient(
        colors: g.map((c) => Color(int.parse(c.toString().replaceAll('#', '0xFF')))).toList(),
      );
    }
    return const LinearGradient(colors: [Color(0xFFC66E41), Color(0xFFB05A35)]);
  }
}