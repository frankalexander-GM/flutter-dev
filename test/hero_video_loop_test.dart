import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:devplay/widgets/hero_video.dart';

/// Plataforma de video falsa: registra lo que el widget le pide.
class _FakeVideoPlatform extends VideoPlayerPlatform {
  static bool looping = false;
  static bool played = false;
  static double volume = 1;
  static int created = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    created++;
    return created;
  }

  @override
  Future<void> setLooping(int playerId, bool value) async {
    looping = value;
  }

  @override
  Future<void> play(int playerId) async {
    played = true;
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double value) async {
    volume = value;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = StreamController<VideoEvent>();
    // Evento de inicialización: duración y tamaño del clip.
    scheduleMicrotask(() {
      controller.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(milliseconds: 4290),
          size: const Size(1280, 720),
        ),
      );
    });
    return controller.stream;
  }
}

void main() {
  setUp(() {
    _FakeVideoPlatform.looping = false;
    _FakeVideoPlatform.played = false;
    _FakeVideoPlatform.volume = 1;
    _FakeVideoPlatform.created = 0;
    VideoPlayerPlatform.instance = _FakeVideoPlatform();
  });

  testWidgets('el video del hero entra en loop y se reproduce mudo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 400,
            child: HeroVideo(
              videoAsset: 'assets/videos/hero_loop_crystal_loop',
              posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // El loop debe estar activo: es lo que hace que el video se repita
    // sin cortes en todos los heroes.
    expect(_FakeVideoPlatform.looping, isTrue);
    expect(_FakeVideoPlatform.played, isTrue);
    // Sin audio: el hero es decorativo.
    expect(_FakeVideoPlatform.volume, 0);
  });
}
