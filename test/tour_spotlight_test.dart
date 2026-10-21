import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/widgets/tour_spotlight.dart';

Future<int> _alphaAt({
  required Rect? target,
  required Offset point,
  Size size = const Size(400, 300),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  TourSpotlightPainter(target: target).paint(canvas, size);
  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final index = (point.dy.toInt() * size.width.toInt() + point.dx.toInt()) * 4;
  return data!.getUint8(index + 3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el spotlight deja transparente el área del objetivo', () async {
    const target = Rect.fromLTWH(100, 80, 120, 80);

    expect(
      await _alphaAt(target: target, point: const Offset(150, 120)),
      0,
    );
    expect(
      await _alphaAt(target: target, point: const Offset(20, 20)),
      closeTo(158, 3),
    );
    expect(
      await _alphaAt(target: target, point: const Offset(150, 250)),
      closeTo(158, 3),
    );
  });

  test('sin objetivo usa un velo suave, no una pantalla negra', () async {
    expect(
      await _alphaAt(target: null, point: const Offset(200, 150)),
      closeTo(107, 3),
    );
  });
}
