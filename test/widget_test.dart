import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/main.dart';

/// La app tiene animaciones infinitas a propósito (cinta del ticker, cursor
/// de la consola), así que `pumpAndSettle` nunca terminaría. Pumpamos un
/// número fijo de cuadros para avanzar el reloj y drenar los temporizadores
/// de la entrada escalonada.
Future<void> _advance(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('la pantalla principal renderiza sin excepciones',
      (tester) async {
    // Pantalla alta para que el feed entre en el viewport de prueba.
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DevPlayApp());
    await _advance(tester, frames: 20);

    expect(tester.takeException(), isNull,
        reason: 'la app debe pintar sin lanzar excepciones');
    expect(find.text('DEVPLAY'), findsWidgets);
  });

  testWidgets('el feed muestra los posts de ejemplo', (tester) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DevPlayApp());
    await _advance(tester);

    expect(tester.takeException(), isNull);
    // Los tres autores del mock tienen que estar en pantalla.
    expect(find.text('luna_dev'), findsOneWidget);
    expect(find.text('raikoh'), findsOneWidget);
    expect(find.text('nick_og'), findsOneWidget);
    // Y el filtro activo.
    expect(find.text('Todo'), findsOneWidget);
  });
}