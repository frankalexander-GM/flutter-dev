import 'package:flutter/material.dart';

import '../theme.dart';

///Entrada escalonada: cada hijo aparece con un desfase (como el `motion.article`
/// de la web, que anima `opacity` + `y` con un retardo por índice).
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Duration delay;
  final Widget child;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 55),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    // Retardo proporcional al índice: 0ms, 55ms, 110ms, ...
    final ms = 40 + widget.index * widget.delay.inMilliseconds;
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Pulseo suave para cosas que "viven" (punto de "en vivo", like activo).
/// Un Latido endless: escala + opacidad, como el `.live-pulse` de la web.
class LivePulse extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration period;

  const LivePulse({
    super.key,
    required this.child,
    this.minScale = 0.92,
    this.maxScale = 1.15,
    this.period = const Duration(milliseconds: 1100),
  });

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// "Pop" elástico al dar like: la escala se dispara y vuelve rebotando.
/// Se dispara cuando [trigger] cambia (normalmente el contador de likes).
class PopScale extends StatefulWidget {
  final int trigger;
  final Widget child;

  const PopScale({super.key, required this.trigger, required this.child});

  @override
  State<PopScale> createState() => _PopScaleState();
}

class _PopScaleState extends State<PopScale> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant PopScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // Curva elástica para el rebote.
        final t = Curves.elasticOut.transform(_c.value.clamp(0.0, 1.0));
        final scale = 1.0 + 0.45 * (1.0 - t) * (t > 0 ? 1 : 0);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// Brillo que recorre la superficie una sola vez (para acentos nuevos).
class Sheen extends StatefulWidget {
  final Widget child;
  const Sheen({super.key, required this.child});

  @override
  State<Sheen> createState() => _SheenState();
}

class _SheenState extends State<Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final slide = Tween<double>(begin: -1.5, end: 2.5)
                .transform(_c.value);
            return LinearGradient(
              begin: Alignment(slide - 1, -1),
              end: Alignment(slide + 1, 1),
              colors: const [
                Colors.transparent,
                DevColors.gold20,
                Colors.transparent,
              ],
              stops: const [0.4, 0.5, 0.6],
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}