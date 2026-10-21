import 'package:flutter/material.dart';

/// Oscurece la pantalla salvo el rectángulo del paso activo del tour.
///
/// Se dibujan cuatro paneles alrededor del objetivo en lugar de un path con
/// un hueco. Así el elemento activo queda totalmente libre de la capa oscura,
/// incluso si está dentro de un scroll o de otro contexto de apilamiento.
class TourSpotlightPainter extends CustomPainter {
  final Rect? target;

  const TourSpotlightPainter({required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);

    if (target == null) {
      // Sin objetivo medible no dejamos la pantalla negra: usamos un velo más
      // suave y la tarjeta queda centrada.
      canvas.drawRect(
        screen,
        Paint()..color = Colors.black.withValues(alpha: 0.42),
      );
      return;
    }

    final hole = target!.inflate(10).intersect(screen);
    if (hole.width <= 0 || hole.height <= 0) {
      canvas.drawRect(screen, dimPaint);
      return;
    }

    // Cuatro paneles alrededor del objetivo. El área activa no tiene NINGUNA
    // capa oscura encima y no dependemos de un cutout con Path.combine.
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, hole.top), dimPaint);
    canvas.drawRect(
      Rect.fromLTRB(0, hole.bottom, size.width, size.height),
      dimPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, hole.top, hole.left, hole.bottom),
      dimPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(hole.right, hole.top, size.width, hole.bottom),
      dimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TourSpotlightPainter oldDelegate) {
    return oldDelegate.target != target;
  }
}
