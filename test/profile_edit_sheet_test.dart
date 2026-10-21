import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/models/user.dart';
import 'package:devplay/theme.dart';
import 'package:devplay/widgets/profile_edit_sheet.dart';

ProfileUser _profile() => ProfileUser(
      id: 'u1',
      username: 'dev_pixel',
      fullName: 'Dev Pixel',
      bio: 'Hago juegos pequeños con ideas grandes.',
      profession: 'Desarrollador indie',
      location: 'Bogotá',
      website: 'https://devpixel.dev',
      tags: const ['Flutter', 'Pixel Art'],
      role: 'DEV',
      isGuest: false,
      createdAt: DateTime(2024, 5, 1),
      followersCount: 120,
      followingCount: 34,
      postsCount: 12,
    );

void main() {
  testWidgets('el formulario de edición monta en móvil y escritorio',
      (tester) async {
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDevPlayTheme(),
          home: Scaffold(
            body: ProfileEditSheet(profile: _profile()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'falló en $size');
      expect(find.text('Información personal'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('muestra la vista previa y los intereses del perfil',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDevPlayTheme(),
        home: Scaffold(
          body: ProfileEditSheet(profile: _profile()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('VISTA PREVIA'), findsOneWidget);
    expect(find.text('Dev Pixel'), findsWidgets);
    expect(find.text('@dev_pixel'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
