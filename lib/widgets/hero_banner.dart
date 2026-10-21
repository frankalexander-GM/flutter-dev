import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Hero de DevPlay — banner pixel-art dibujado a mano con CustomPainter.
/// Mismo lenguaje visual que la web: mando retro, título en Fraunces,
/// filete ornamental, chips dorados y cinta de juegos.
///
/// Responsive: en pantallas anchas (>= 680 px) usa el banner horizontal
/// 1200x420 de la web; en móvil baja a una versión vertical compacta para
/// que el texto no se aplaste.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, this.onCreateTap, this.onGameTap});

  final VoidCallback? onCreateTap;
  final ValueChanged<String>? onGameTap;

  static const double _wideBreakpoint = 680;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        if (cons.maxWidth >= _wideBreakpoint) {
          return _WideHero(onCreateTap: onCreateTap, onGameTap: onGameTap);
        }
        return _CompactHero(onCreateTap: onCreateTap, onGameTap: onGameTap);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Fondo compartido: degradado cálido + rejilla de papel + chispas
// ══════════════════════════════════════════════════════════════
class _HeroSurface extends StatelessWidget {
  final Widget child;
  const _HeroSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [Color(0xFF0A1424), Color(0xFF060B14), Color(0xFF060B14)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        foregroundPainter: _SparksPainter(),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DevColors.foreground.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chispas pixel (estrellitas del retro). Las posiciones del diseño
/// 1200x420 se escalan al tamaño real, así que caben en ambas variantes.
class _SparksPainter extends CustomPainter {
  static final _diamonds = <List<Offset>>[
    [
      const Offset(86, 72), const Offset(92, 72), const Offset(86, 78),
      const Offset(98, 78), const Offset(92, 84),
    ],
    [
      const Offset(1090, 96), const Offset(1084, 102),
      const Offset(1096, 102), const Offset(1090, 108),
    ],
  ];
  static final _ember = [
    const Offset(150, 300), const Offset(156, 306),
    const Offset(1044, 286), const Offset(1038, 292), const Offset(1044, 298),
  ];
  static final _soft = [
    const Offset(238, 128), const Offset(962, 150),
    const Offset(880, 96), const Offset(330, 188),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final kx = size.width / 1200;
    final ky = size.height / 420;
    final px = math.max(2.0, 6 * kx);

    Offset at(Offset o) => Offset(o.dx * kx, o.dy * ky);

    final gold = Paint()..color = DevColors.gold;
    for (final d in _diamonds) {
      for (final o in d) {
        canvas.drawRect(Rect.fromLTWH(at(o).dx, at(o).dy, px, px), gold);
      }
    }
    final ember = Paint()..color = DevColors.primary.withValues(alpha: 0.85);
    for (final o in _ember) {
      canvas.drawRect(Rect.fromLTWH(at(o).dx, at(o).dy, px, px), ember);
    }
    final soft = Paint()..color = DevColors.foreground.withValues(alpha: 0.3);
    for (final o in _soft) {
      canvas.drawRect(Rect.fromLTWH(at(o).dx, at(o).dy, px * 0.7, px * 0.7), soft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Marco editorial doble (.frame-double de la web).
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = DevColors.foreground.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final p2 = Paint()
      ..color = DevColors.foreground.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), p1);
    canvas.drawRect(Rect.fromLTWH(17, 17, size.width - 34, size.height - 34), p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════
// Mando pixel-art (cada celda es un píxel del mando)
// ══════════════════════════════════════════════════════════════
class _PixelGamepad extends StatelessWidget {
  const _PixelGamepad();
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 18, height: 9, child: CustomPaint(painter: _GamepadPainter()));
}

class _GamepadPainter extends CustomPainter {
  static const _shell = <Offset>[
    Offset(6, 1), Offset(7, 1), Offset(8, 1), Offset(9, 1), Offset(10, 1), Offset(11, 1),
    Offset(3, 2), Offset(4, 2), Offset(5, 2), Offset(6, 2), Offset(7, 2), Offset(8, 2),
    Offset(9, 2), Offset(10, 2), Offset(11, 2), Offset(12, 2), Offset(13, 2), Offset(14, 2),
    Offset(2, 3), Offset(3, 3), Offset(4, 3), Offset(5, 3), Offset(6, 3), Offset(7, 3),
    Offset(8, 3), Offset(9, 3), Offset(10, 3), Offset(11, 3), Offset(12, 3), Offset(13, 3),
    Offset(14, 3), Offset(15, 3),
    Offset(2, 4), Offset(3, 4), Offset(4, 4), Offset(5, 4), Offset(6, 4), Offset(7, 4),
    Offset(8, 4), Offset(9, 4), Offset(10, 4), Offset(11, 4), Offset(12, 4), Offset(13, 4),
    Offset(14, 4), Offset(15, 4),
    Offset(1, 4), Offset(1, 5), Offset(1, 6),
    Offset(16, 4), Offset(16, 5), Offset(16, 6),
    Offset(0, 5), Offset(0, 6),
    Offset(17, 5), Offset(17, 6),
    Offset(2, 7), Offset(15, 7),
    Offset(3, 8), Offset(4, 8), Offset(13, 8), Offset(14, 8),
  ];
  static const _dpad = <Offset>[
    Offset(4, 3), Offset(4, 4), Offset(4, 5),
    Offset(3, 4), Offset(5, 4),
  ];
  static const _buttons = <Offset>[
    Offset(12, 3), Offset(12, 5), Offset(13, 3), Offset(14, 3), Offset(14, 4),
  ];
  static const _center = <Offset>[Offset(8, 4), Offset(10, 4)];

  void _block(Canvas canvas, Paint p, List<Offset> cells) {
    for (final c in cells) {
      canvas.drawRect(Rect.fromLTWH(c.dx, c.dy, 1, 1), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(1, 2, 16, 5),
      Paint()
        ..color = DevColors.primary.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    _block(canvas, Paint()..color = DevColors.goldSoft, _shell);
    _block(canvas, Paint()..color = DevColors.background, _dpad);
    _block(canvas, Paint()..color = DevColors.gold, _buttons);
    _block(
      canvas,
      Paint()..color = DevColors.background.withValues(alpha: 0.75),
      _center,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════
// Título con degradado (compartido por ambas variantes)
// ══════════════════════════════════════════════════════════════
class _HeroTitleText extends StatelessWidget {
  const _HeroTitleText({required this.size, this.letterSpacing = -2});

  final double size;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final base = DevTheme.display(size: size).copyWith(
      letterSpacing: letterSpacing,
      height: 1.0,
    );
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE0F7FF),
          Color(0xFF7DD3FC),
          Color(0xFF3B82F6),
          Color(0xFF8B5CF6),
        ],
        stops: [0.0, 0.42, 0.72, 1.0],
      ).createShader(rect),
      child: Text(
        'DEVPLAY',
        style: base.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Filete ornamental (oro + terracota).
class _OrnamentRule extends StatelessWidget {
  const _OrnamentRule({this.goldWidth = 120, this.accentWidth = 34});

  final double goldWidth;
  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: goldWidth, height: 3, color: DevColors.gold),
        const SizedBox(width: 8),
        Container(
          width: accentWidth,
          height: 3,
          color: DevColors.primary.withValues(alpha: 0.65),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Variante ANCHA: banner 1200x420 (escala como un viewBox SVG)
// ══════════════════════════════════════════════════════════════
class _WideHero extends StatelessWidget {
  const _WideHero({this.onCreateTap, this.onGameTap});
  final VoidCallback? onCreateTap;
  final ValueChanged<String>? onGameTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        final scale = w / 1200;
        final h = math.min(w * 420 / 1200, 250.0);

        return SizedBox(
          width: w,
          height: h,
          child: ClipRect(
            child: FittedBox(
              alignment: Alignment.topCenter,
              fit: BoxFit.fitWidth,
              child: SizedBox(
                width: 1200,
                height: 420,
                child: _HeroSurface(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 84 * scale,
                        top: 128 * scale,
                        child: GestureDetector(
                          onTap: () => onGameTap?.call('Pixel Dash'),
                          child: Transform.scale(
                            scale: scale * 9,
                            child: const _PixelGamepad(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 270 * scale,
                        top: 96 * scale,
                        child: const _HeroTitleText(size: 112),
                      ),
                      Positioned(
                        left: 272 * scale,
                        top: 232 * scale,
                        child: const _OrnamentRule(),
                      ),
                      Positioned(
                        left: 272 * scale,
                        top: 268 * scale,
                        child: Text(
                          'COMUNIDAD DE DEVS Y BETAS',
                          style: DevTheme.mono(size: 21, w: FontWeight.w700,
                                  color: DevColors.foreground)
                              .copyWith(letterSpacing: 5.5),
                        ),
                      ),
                      Positioned(
                        left: 272 * scale,
                        top: 306 * scale,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: _HeroChips(onGameTap: onGameTap),
                        ),
                      ),
                      Positioned(
                        left: 940 * scale,
                        top: 250 * scale,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _CreateButton(onTap: onCreateTap),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 352 * scale,
                        child: _TickerStrip(),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _FramePainter()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Variante COMPACTA (móvil): vertical, texto legible
// ══════════════════════════════════════════════════════════════
class _CompactHero extends StatelessWidget {
  const _CompactHero({this.onCreateTap, this.onGameTap});
  final VoidCallback? onCreateTap;
  final ValueChanged<String>? onGameTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _HeroSurface(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mando + chip de versión
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => onGameTap?.call('Pixel Dash'),
                        child: Transform.scale(
                          scale: 4.4,
                          child: const _PixelGamepad(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: '★ EN DEVPLAY',
                              bg: DevColors.foreground.withValues(alpha: 0.08),
                              border: DevColors.gold.withValues(alpha: 0.45),
                              fg: DevColors.cream,
                            ),
                            _Chip(
                              label: 'v0.4.2',
                              bg: DevColors.gold.withValues(alpha: 0.22),
                              border: DevColors.gold.withValues(alpha: 0.5),
                              fg: DevColors.goldSoft,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _HeroTitleText(size: 38, letterSpacing: -1),
                  const SizedBox(height: 9),
                  const _OrnamentRule(goldWidth: 60, accentWidth: 22),
                  const SizedBox(height: 10),
                  Text(
                    'COMUNIDAD DE DEVS Y BETAS',
                    style: DevTheme.mono(size: 11, w: FontWeight.w700,
                            color: DevColors.foreground)
                        .copyWith(letterSpacing: 2.6),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CreateButton(
                          onTap: onCreateTap,
                          expand: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Marco solo en el borde inferior
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(height: 3, color: DevColors.gold.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Chips
// ══════════════════════════════════════════════════════════════
class _HeroChips extends StatelessWidget {
  const _HeroChips({this.onGameTap});
  final ValueChanged<String>? onGameTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Chip(
          label: '★ EN DEVPLAY',
          bg: Color(0x14E0F7FF),
          border: Color(0x738B5CF6),
          fg: DevColors.cream,
        ),
        const SizedBox(width: 16),
        const _Chip(
          label: 'v0.4.2',
          bg: Color(0x388B5CF6),
          border: Color(0x808B5CF6),
          fg: DevColors.goldSoft,
        ),
        const SizedBox(width: 16),
        _Chip(
          label: 'Pixel Dash',
          bg: const Color(0x0FE0F7FF),
          border: const Color(0x2EE0F7FF),
          fg: Color(0xD9E0F7FF),
          onTap: () => onGameTap?.call('Pixel Dash'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.bg,
    this.border,
    this.fg,
    this.onTap,
  });

  final String label;
  final Color? bg;
  final Color? border;
  final Color? fg;
  final VoidCallback? onTap;

  static const height = 34.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: border ?? Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: DevTheme.display(size: 15).copyWith(
            color: fg ?? DevColors.cream,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Botón Crear
// ══════════════════════════════════════════════════════════════
class _CreateButton extends StatelessWidget {
  const _CreateButton({this.onTap, this.expand = false});
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: expand ? Alignment.center : null,
      decoration: BoxDecoration(
        gradient: DevTheme.btnGradient(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DevColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: DevColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 9),
          Text('Crear', style: DevTheme.display(size: 19).copyWith(color: Colors.white)),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: expand
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Cinta inferior
// ══════════════════════════════════════════════════════════════
class _TickerStrip extends StatelessWidget {
  const _TickerStrip();

  @override
  Widget build(BuildContext context) {
    const games = [
      'PIXEL DASH · ARCADE · 1.2k',
      'NEON DRIFT · CARRERAS · 3.4k',
      'CÓDIGO ROJO · SHOOTER · 912',
      'ASTRO BAKERY · SIMULACIÓN · 5.9k',
    ];

    return Container(
      height: 68,
      width: 1200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DevColors.background.withValues(alpha: 0.0),
            const Color(0xFF05070D).withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, color: DevColors.gold.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 34),
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  for (final g in games) ...[
                    Text(
                      g,
                      style: DevTheme.mono(size: 13).copyWith(
                        letterSpacing: 2,
                        color: DevColors.foreground.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}