import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/models/user.dart';
import 'package:devplay/theme.dart';
import 'package:devplay/widgets/share_sheet.dart';

ProfileUser _profile() => ProfileUser(
  id: 'u1',
  username: 'dev_pixel',
  fullName: 'Dev Pixel',
  role: 'DEV',
  isGuest: false,
  createdAt: DateTime(2024, 5, 1),
);

void main() {
  testWidgets('la hoja de compartir monta en móvil y escritorio', (
    tester,
  ) async {
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDevPlayTheme(),
          home: Scaffold(body: ProfileShareSheet(profile: _profile())),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'falló en $size');
      expect(find.text('Compartir perfil'), findsOneWidget);
      expect(find.text('@dev_pixel'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Copiar enlace'), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
