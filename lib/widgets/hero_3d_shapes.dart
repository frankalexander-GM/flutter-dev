import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Estilo de las formas decorativas. Cada hero usa una composición distinta
/// para no repetir el mismo adorno en todas las pantallas.
enum Hero3DStyle { home, betas, chat, discover, about }

/// Adorno 3D ligero para los heroes de DevPlay.
///
/// Dibuja cubos isométricos, orbes, anillos y gemas con degradados y brillos.
/// Las piezas flotan y se balancean lentamente, con fases distintas para que
/// el conjunto no parezca un bloque rígido. Es puramente decorativo: no captura
/// toques, no entra en semántica y no participa en el layout.
class Hero3DShapes extends StatefulWidget {
  final Hero3DStyle style;
  final double opacity;

  const Hero3DShapes({
    super.key,
    this.style = Hero3DStyle.home,
    this.opacity = 0.82,
  });

  @override
  State<Hero3DShapes> createState() => _Hero3DShapesState();
}

class _Hero3DShapesState extends State<Hero3DShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _Hero3DShapesPainter(
              style: widget.style,
              opacity: widget.opacity,
              animation: _float,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _Hero3DShapesPainter extends CustomPainter {
  final Hero3DStyle style;
  final double opacity;
  final Animation<double> animation;

  _Hero3DShapesPainter({
    required this.style,
    required this.opacity,
    required this.animation,
  }) : super(repaint: animation);

  double get _time => animation.value * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final scale = (size.width / 1000).clamp(0.55, 1.15).toDouble();
    final unit = math.min(132.0 * scale, size.height * 0.94);
    final compact = size.width < 720;

    switch (style) {
      case Hero3DStyle.home:
        _paintHome(canvas, size, unit, compact);
        break;
      case Hero3DStyle.betas:
        _paintBetas(canvas, size, unit, compact);
        break;
      case Hero3DStyle.chat:
        _paintChat(canvas, size, unit, compact);
        break;
      case Hero3DStyle.discover:
        _paintDiscover(canvas, size, unit, compact);
        break;
      case Hero3DStyle.about:
        _paintAbout(canvas, size, unit, compact);
        break;
    }
  }

  void _paintHome(Canvas canvas, Size size, double u, bool compact) {
    if (compact) {
      _ring(
        canvas,
        Offset(size.width * .87, size.height * .20),
        u * .55,
        rotation: -.5,
        accent: DevColors.gold,
      );
      _cube(
        canvas,
        Offset(size.width * .90, size.height * .60),
        u * .34,
        rotation: .2,
        accent: DevColors.primary,
      );
      _orb(
        canvas,
        Offset(size.width * .74, size.height * .82),
        u * .16,
        accent: DevColors.goldSoft,
      );
      return;
    }

    _ring(
      canvas,
      Offset(size.width * .83, size.height * .34),
      u * .78,
      rotation: -.32,
      accent: DevColors.gold,
    );
    _cube(
      canvas,
      Offset(size.width * .93, size.height * .70),
      u * .42,
      rotation: .18,
      accent: DevColors.primary,
    );
    _orb(
      canvas,
      Offset(size.width * .70, size.height * .76),
      u * .16,
      accent: DevColors.goldSoft,
    );
  }

  void _paintBetas(Canvas canvas, Size size, double u, bool compact) {
    if (compact) {
      _cube(
        canvas,
        Offset(size.width * .88, size.height * .23),
        u * .40,
        rotation: -.18,
        accent: DevColors.primary,
      );
      _gem(
        canvas,
        Offset(size.width * .85, size.height * .68),
        u * .27,
        rotation: .16,
        accent: DevColors.gold,
      );
      _orb(
        canvas,
        Offset(size.width * .70, size.height * .83),
        u * .14,
        accent: DevColors.wine,
      );
      return;
    }

    _cube(
      canvas,
      Offset(size.width * .85, size.height * .37),
      u * .62,
      rotation: -.2,
      accent: DevColors.primary,
    );
    _gem(
      canvas,
      Offset(size.width * .72, size.height * .78),
      u * .32,
      rotation: .18,
      accent: DevColors.gold,
    );
    _orb(
      canvas,
      Offset(size.width * .95, size.height * .66),
      u * .20,
      accent: DevColors.wine,
    );
    _ring(
      canvas,
      Offset(size.width * .68, size.height * .22),
      u * .34,
      rotation: .45,
      accent: DevColors.goldSoft,
    );
  }

  void _paintChat(Canvas canvas, Size size, double u, bool compact) {
    if (compact) {
      _globe(
        canvas,
        Offset(size.width * .86, size.height * .53),
        u * .60,
        accent: DevColors.consoleGreen,
      );
      _gem(
        canvas,
        Offset(size.width * .70, size.height * .84),
        u * .20,
        rotation: -.14,
        accent: DevColors.gold,
      );
      return;
    }

    _globe(
      canvas,
      Offset(size.width * .88, size.height * .50),
      u * .70,
      accent: DevColors.consoleGreen,
    );
    _cube(
      canvas,
      Offset(size.width * .72, size.height * .80),
      u * .28,
      rotation: .14,
      accent: DevColors.primary,
    );
    _ring(
      canvas,
      Offset(size.width * .97, size.height * .20),
      u * .25,
      rotation: -.55,
      accent: DevColors.gold,
    );
  }

  void _paintDiscover(Canvas canvas, Size size, double u, bool compact) {
    if (compact) {
      _ring(
        canvas,
        Offset(size.width * .89, size.height * .16),
        u * .42,
        rotation: -.45,
        accent: DevColors.gold,
      );
      _gem(
        canvas,
        Offset(size.width * .84, size.height * .34),
        u * .20,
        rotation: .18,
        accent: DevColors.primary,
      );
      return;
    }

    _ring(
      canvas,
      Offset(size.width * .87, size.height * .20),
      u * .66,
      rotation: -.38,
      accent: DevColors.gold,
    );
    _gem(
      canvas,
      Offset(size.width * .94, size.height * .43),
      u * .28,
      rotation: .14,
      accent: DevColors.primary,
    );
    _orb(
      canvas,
      Offset(size.width * .76, size.height * .33),
      u * .15,
      accent: DevColors.goldSoft,
    );
  }

  void _paintAbout(Canvas canvas, Size size, double u, bool compact) {
    if (compact) {
      _cube(
        canvas,
        Offset(size.width * .90, size.height * .28),
        u * .40,
        rotation: -.18,
        accent: DevColors.primary,
      );
      _orb(
        canvas,
        Offset(size.width * .82, size.height * .78),
        u * .18,
        accent: DevColors.goldSoft,
      );
      return;
    }

    _cube(
      canvas,
      Offset(size.width * .88, size.height * .43),
      u * .48,
      rotation: -.16,
      accent: DevColors.primary,
    );
    _orb(
      canvas,
      Offset(size.width * .78, size.height * .75),
      u * .17,
      accent: DevColors.goldSoft,
    );
    _ring(
      canvas,
      Offset(size.width * .96, size.height * .82),
      u * .30,
      rotation: .35,
      accent: DevColors.gold,
    );
  }

  // ── Movimiento ─────────────────────────────────────────────────────────────

  double _phase(Offset center) => center.dx * .011 + center.dy * .017;

  double _bob(Offset center, double size) =>
      math.sin(_time + _phase(center)) * math.min(6, size * .06);

  double _sway(Offset center) =>
      math.sin(_time * .72 + _phase(center) * 1.6) * .035;

  double _pulse(Offset center) =>
      .86 + .14 * (0.5 + 0.5 * math.sin(_time * 1.3 + _phase(center)));

  // ── Formas ────────────────────────────────────────────────────────────────

  void _shadow(Canvas canvas, Offset center, double width, double height) {
    if (width <= 0 || height <= 0) return;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      Paint()
        ..color = Colors.black.withValues(alpha: .30 * opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(2, width * .08),
        ),
    );
  }

  void _cube(
    Canvas canvas,
    Offset center,
    double s, {
    required double rotation,
    required Color accent,
  }) {
    if (s <= 0) return;
    // Movimiento suave: flotación vertical, balanceo y respiración del tamaño.
    final bob = _bob(center, s);
    final sway = _sway(center);
    final pulse = _pulse(center);
    _shadow(canvas, center.translate(0, s * .67), s * 1.12, s * .22);

    canvas.save();
    canvas.translate(center.dx, center.dy + bob);
    canvas.rotate(rotation + sway);
    canvas.scale(pulse);

    final topH = s * .48;
    final body = s * .52;
    final halfW = s * .55;

    final top = Path()
      ..moveTo(0, -topH)
      ..lineTo(halfW, 0)
      ..lineTo(0, topH)
      ..lineTo(-halfW, 0)
      ..close();
    final left = Path()
      ..moveTo(-halfW, 0)
      ..lineTo(0, topH)
      ..lineTo(0, topH + body)
      ..lineTo(-halfW, body)
      ..close();
    final right = Path()
      ..moveTo(0, topH)
      ..lineTo(halfW, 0)
      ..lineTo(halfW, body)
      ..lineTo(0, topH + body)
      ..close();

    canvas.drawPath(
      top,
      Paint()
        ..color = accent.withValues(alpha: .22 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawPath(
      left,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: .82 * opacity),
            DevColors.wine.withValues(alpha: .72 * opacity),
            DevColors.background.withValues(alpha: .90 * opacity),
          ],
        ).createShader(Rect.fromLTWH(-halfW, 0, halfW, topH + body)),
    );
    canvas.drawPath(
      right,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            DevColors.primary.withValues(alpha: .78 * opacity),
            DevColors.background.withValues(alpha: .94 * opacity),
          ],
        ).createShader(Rect.fromLTWH(0, 0, halfW, topH + body)),
    );
    canvas.drawPath(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DevColors.cream.withValues(alpha: .88 * opacity),
            DevColors.goldSoft.withValues(alpha: .78 * opacity),
            accent.withValues(alpha: .58 * opacity),
          ],
        ).createShader(Rect.fromLTWH(-halfW, -topH, s, topH * 2)),
    );

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, s * .012)
      ..color = DevColors.cream.withValues(alpha: .46 * opacity)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(top, edge);
    canvas.drawLine(Offset(-halfW, 0), Offset(-halfW, body), edge);
    canvas.drawLine(Offset(0, topH), Offset(0, topH + body), edge);
    canvas.drawLine(Offset(halfW, 0), Offset(halfW, body), edge);

    canvas.drawLine(
      Offset(-halfW * .52, topH * .06),
      Offset(0, -topH * .62),
      Paint()
        ..color = DevColors.cream.withValues(alpha: .72 * opacity)
        ..strokeWidth = math.max(1, s * .018)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _orb(Canvas canvas, Offset center, double s, {required Color accent}) {
    if (s <= 0) return;
    final bob = _bob(center, s);
    final pulse = _pulse(center);
    _shadow(canvas, center.translate(0, s * .62), s * 1.05, s * .22);

    final center2 = center.translate(0, bob);
    final radius = s * .5 * pulse;
    final rect = Rect.fromCircle(center: center2, radius: radius);
    canvas.drawCircle(
      center2,
      s * .58,
      Paint()
        ..color = accent.withValues(alpha: .18 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      center2,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.42),
          radius: 1.05,
          colors: [
            DevColors.cream.withValues(alpha: .96 * opacity),
            accent.withValues(alpha: .88 * opacity),
            DevColors.wine.withValues(alpha: .78 * opacity),
            DevColors.background.withValues(alpha: .96 * opacity),
          ],
          stops: const [0.0, .26, .62, 1.0],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center2,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * .012)
        ..color = DevColors.cream.withValues(alpha: .34 * opacity),
    );

    canvas.save();
    canvas.translate(center2.dx - s * .13, center2.dy - s * .19);
    canvas.rotate(-.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * .25, height: s * .11),
      Paint()..color = DevColors.cream.withValues(alpha: .50 * opacity),
    );
    canvas.restore();
  }

  void _ring(
    Canvas canvas,
    Offset center,
    double s, {
    required double rotation,
    required Color accent,
  }) {
    if (s <= 0) return;
    final bob = _bob(center, s);
    final sway = _sway(center);
    _shadow(canvas, center.translate(0, s * .47), s * .95, s * .18);

    canvas.save();
    canvas.translate(center.dx, center.dy + bob);
    canvas.rotate(rotation + sway * 2.4);
    canvas.scale(1, .58);

    final rect = Rect.fromCircle(center: Offset.zero, radius: s * .45);
    final shader = SweepGradient(
      startAngle: -.2,
      endAngle: math.pi * 2,
      colors: [
        accent.withValues(alpha: .18 * opacity),
        accent.withValues(alpha: .94 * opacity),
        DevColors.cream.withValues(alpha: .92 * opacity),
        DevColors.primary.withValues(alpha: .72 * opacity),
        accent.withValues(alpha: .18 * opacity),
      ],
      stops: const [0.0, .24, .45, .74, 1.0],
    ).createShader(rect);

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .18
        ..color = accent.withValues(alpha: .18 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, s * .105)
        ..shader = shader
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      rect.deflate(s * .085),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * .012)
        ..color = DevColors.cream.withValues(alpha: .20 * opacity),
    );
    canvas.drawArc(
      rect,
      -2.45,
      .65,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, s * .025)
        ..strokeCap = StrokeCap.round
        ..color = DevColors.cream.withValues(alpha: .72 * opacity),
    );
    canvas.restore();
  }

  void _gem(
    Canvas canvas,
    Offset center,
    double s, {
    required double rotation,
    required Color accent,
  }) {
    if (s <= 0) return;
    final bob = _bob(center, s);
    final sway = _sway(center);
    _shadow(canvas, center.translate(0, s * .62), s * .95, s * .20);

    canvas.save();
    canvas.translate(center.dx, center.dy + bob);
    canvas.rotate(rotation + sway * 1.6);

    final top = Offset(0, -s * .56);
    final left = Offset(-s * .48, 0);
    final right = Offset(s * .48, 0);
    final bottom = Offset(0, s * .62);
    final middle = Offset(0, s * .06);

    Path face(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    final faces = <Path>[
      face(top, left, middle),
      face(top, middle, right),
      face(left, bottom, middle),
      face(middle, bottom, right),
    ];
    final colors = <List<Color>>[
      [
        DevColors.cream.withValues(alpha: .90 * opacity),
        accent.withValues(alpha: .76 * opacity),
      ],
      [
        DevColors.goldSoft.withValues(alpha: .92 * opacity),
        accent.withValues(alpha: .70 * opacity),
      ],
      [
        accent.withValues(alpha: .78 * opacity),
        DevColors.wine.withValues(alpha: .78 * opacity),
      ],
      [
        DevColors.wine.withValues(alpha: .72 * opacity),
        DevColors.background.withValues(alpha: .90 * opacity),
      ],
    ];

    canvas.drawPath(
      faces.first,
      Paint()
        ..color = accent.withValues(alpha: .20 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    for (var i = 0; i < faces.length; i++) {
      canvas.drawPath(
        faces[i],
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors[i],
          ).createShader(Rect.fromLTRB(-s * .5, -s * .56, s * .5, s * .62)),
      );
    }

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, s * .012)
      ..color = DevColors.cream.withValues(alpha: .42 * opacity)
      ..strokeJoin = StrokeJoin.round;
    for (final facePath in faces) {
      canvas.drawPath(facePath, edge);
    }
    canvas.drawLine(
      top,
      middle,
      Paint()
        ..color = DevColors.cream.withValues(alpha: .65 * opacity)
        ..strokeWidth = math.max(1, s * .016)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _globe(Canvas canvas, Offset center, double s, {required Color accent}) {
    if (s <= 0) return;
    final bob = _bob(center, s);
    final pulse = _pulse(center);
    _shadow(canvas, center.translate(0, s * .60), s * 1.00, s * .20);

    final center2 = center.translate(0, bob);
    final radius = s * .48 * pulse;
    final rect = Rect.fromCircle(center: center2, radius: radius);
    canvas.drawCircle(
      center2,
      radius * 1.14,
      Paint()
        ..color = accent.withValues(alpha: .13 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      center2,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.34, -.38),
          radius: 1.0,
          colors: [
            accent.withValues(alpha: .34 * opacity),
            DevColors.consoleBg.withValues(alpha: .86 * opacity),
            DevColors.background.withValues(alpha: .96 * opacity),
          ],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, s * .008)
      ..color = accent.withValues(alpha: .34 * opacity);

    for (final y in [-.28, 0.0, .28]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center2.translate(0, radius * y),
          width: radius * 2,
          height: radius * (y == 0 ? .38 : .54),
        ),
        grid,
      );
    }
    for (final x in [-.22, 0.0, .22]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center2.translate(radius * x, 0),
          width: radius * (x == 0 ? .34 : .62),
          height: radius * 2,
        ),
        grid,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      center2,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, s * .012)
        ..color = accent.withValues(alpha: .62 * opacity),
    );
    canvas.drawArc(
      rect.deflate(radius * .08),
      -2.5,
      .85,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, s * .022)
        ..strokeCap = StrokeCap.round
        ..color = DevColors.cream.withValues(alpha: .60 * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _Hero3DShapesPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.opacity != opacity;
}
