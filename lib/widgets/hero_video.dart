import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:video_player/video_player.dart';

import '../widgets/hero_3d_shapes.dart';
import '../theme.dart';

/// HeroVideo – fondo de video en loop imperceptible con un adorno 3D sutil arriba.
///
/// [videoAsset] ruta del archivo de video (sin extensión .mp4) ubicado en assets/videos/.
/// [posterAsset] imagen de respaldo que se muestra mientras el video se carga.
/// [autoPlay] si el video comienza automáticamente (por defecto true).
/// [mute] si el video se reproduce sin sonido (por defecto true, ideal para heroes).
/// [shapeOpacity] opacidad del adorno 3D (0.0 = invisible, 1.0 = opaco). Recomendado 0.30‑0.45.
/// [shapeStyle] estilo decorativo 3D (por defecto Hero3DStyle.home).
/// [enablePointerInterceptor] en web, si true, envuelve el video con PointerInterceptor para que los clics no se bloqueen (por defecto true).
/// [scrimOpacity] velo oscuro sobre el video (0.0 = transparente) para que el
/// texto del hero siga siendo legible. Recomendado 0.20‑0.45.
class HeroVideo extends StatefulWidget {
  final String videoAsset;
  final String posterAsset;
  final bool autoPlay;
  final bool mute;
  final double shapeOpacity;
  final Hero3DStyle shapeStyle;
  final bool enablePointerInterceptor;
  final double scrimOpacity;

  const HeroVideo({
    super.key,
    required this.videoAsset,
    required this.posterAsset,
    this.autoPlay = true,
    this.mute = true,
    this.shapeOpacity = 0.35,
    this.shapeStyle = Hero3DStyle.home,
    this.enablePointerInterceptor = true,
    this.scrimOpacity = 0.30,
  });

  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _reduceMotion = false;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    // Construye la ruta del asset (añade .mp4 si no tiene).
    final assetPath = widget.videoAsset.endsWith('.mp4')
        ? widget.videoAsset
        : '${widget.videoAsset}.mp4';

    _controller = VideoPlayerController.asset(
      assetPath,
    );

    // Si el video se detiene (pestaña en segundo plano, pausa del sistema),
    // lo volvemos a reproducir para que el loop nunca se rompa.
    _controller.addListener(_ensurePlaying);

    // Inicialización asíncrona.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      // Loop infinito: el video es un clip corto que se repite sin cortes.
      // El asset ya viene con una cola de fundido, así que el empalme entre
      // el último y el primer fotograma es imperceptible.
      await _controller.setLooping(true);
      if (widget.mute) {
        await _controller.setVolume(0.0);
      }
      if (widget.autoPlay) {
        await _controller.play();
      }
    } catch (error) {
      // Si el video no puede reproducirse (plataforma sin soporte, asset
      // ausente, error de red…) el hero se queda con el póster.
      debugPrint('No se pudo iniciar el video del hero: $error');
      return;
    }
    if (!mounted) return;
    setState(() => _initialized = true);
  }

  /// Garantiza que el video siga en loop aunque el sistema lo pause.
  void _ensurePlaying() {
    if (!_initialized || !widget.autoPlay || _reduceMotion) return;
    if (_controller.value.isPlaying) return;
    if (_controller.value.duration == Duration.zero) return;
    if (_resuming) return;
    _resuming = true;
    _controller.play().whenComplete(() => _resuming = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (!_initialized) return;
    if (reduceMotion) {
      // Accesibilidad: si el sistema pide menos movimiento, el video se
      // detiene y el hero muestra el póster.
      _controller.pause();
    } else if (widget.autoPlay) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_ensurePlaying);
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------
  // Build
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Mientras el video no está listo, mostramos el póster.
    if (!_initialized) {
      return _poster();
    }

    // Componente de video. En web lo envolvemos con PointerInterceptor para
    // que los clics sobre el video no bloqueen los botones de encima.
    Widget player = ExcludeSemantics(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
    if (kIsWeb && widget.enablePointerInterceptor) {
      player = PointerInterceptor(child: player);
    }

    // Velo oscuro sutil: mantiene legible el texto del hero sin apagar el video.
    final scrim = widget.scrimOpacity <= 0
        ? const SizedBox.shrink()
        : IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DevColors.background.withValues(
                  alpha: widget.scrimOpacity.clamp(0, 1),
                ),
              ),
            ),
          );

    // Adorno 3D superpuesto (opacidad y estilo definidos en la pantalla).
    final shapeOverlay = Hero3DShapes(
      style: widget.shapeStyle,
      opacity: widget.shapeOpacity,
    );

    // Empaquetamos todo en un Stack: video de fondo + velo + formas 3D al frente.
    return Stack(
      fit: StackFit.expand,
      children: [
        player,
        scrim,
        shapeOverlay,
      ],
    );
  }

  Widget _poster() {
    // Normaliza la ruta: si no trae extensión se asume .jpg (el póster).
    final poster = widget.posterAsset.contains('.')
        ? widget.posterAsset
        : '${widget.posterAsset}.jpg';
    return ExcludeSemantics(
      child: SizedBox.expand(
        child: Image.asset(
          poster,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}