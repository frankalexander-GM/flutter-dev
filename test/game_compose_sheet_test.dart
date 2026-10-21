import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/theme.dart';
import 'package:devplay/widgets/game_compose_sheet.dart';

void main() {
  testWidgets('el formulario de juego monta y valida campos', (tester) async {
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDevPlayTheme(),
          home: const Scaffold(body: GameComposeSheet()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'falló en $size');
      expect(find.text('Publicar un juego'), findsOneWidget);
      expect(find.text('Nombre del juego *'), findsOneWidget);
      expect(find.text('Descripción *'), findsOneWidget);
      expect(find.text('Género'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Portada'), findsOneWidget);
      expect(find.text('Enlace para jugar'), findsOneWidget);

      await tester.tap(find.text('Publicar juego'));
      await tester.pump();

      expect(
        find.text('Escribe un nombre de al menos 3 caracteres'),
        findsOneWidget,
      );
      expect(
        find.text('Cuéntanos un poco más (mín. 10 caracteres)'),
        findsOneWidget,
      );
    }
    await tester.binding.setSurfaceSize(null);
  });
}
