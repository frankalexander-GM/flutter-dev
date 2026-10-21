import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:video_player/video_player.dart';

/// Fondo animado del hero de Inicio.
///
/// Usa un MP4 local, sin audio y en loop. Mientras carga (o si el video no
/// puede reproducirse) muestra el poster, así el hero nunca queda en blanco.
/// En web se envuelve en [PointerInterceptor] para que el platform view del
/// video no se coma los clics de los botones que están encima.
class HeroLoopVideo extends StatefulWidget {
  const HeroLoopVideo({super.key});

  static const videoAsset = 'assets/videos/hero_loop_crystal_loop.mp4';
  static const posterAsset = 'assets/videos/hero_loop_crystal_loop_poster.jpg';

  @override
  State<HeroLoopVideo> createState() => _HeroLoopVideoState();
}

class _HeroLoopVideoState extends State<HeroLoopVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      HeroLoopVideo.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      if (!mounted) return;
      if (!_reduceMotion) {
        await _controller.play();
      }
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      debugPrint('No se pudo iniciar el video del hero: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (!_ready) return;
    if (reduceMotion) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _poster();
    if (!_ready) return _poster();
    if (_reduceMotion) return _poster();

    Widget player = VideoPlayer(_controller);
    if (kIsWeb) {
      player = PointerInterceptor(child: player);
    }

    return ExcludeSemantics(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: player,
          ),
        ),
      ),
    );
  }

  Widget _poster() {
    return ExcludeSemantics(
      child: Image.asset(
        HeroLoopVideo.posterAsset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }
}
