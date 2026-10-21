import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devplay/providers/auth_provider.dart';
import 'package:devplay/screens/profile_screen.dart';
import 'package:devplay/theme.dart';

void main() {
  testWidgets('ProfileScreen monta sin excepciones en escritorio y móvil',
      (tester) async {
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            theme: buildDevPlayTheme(),
            home: const ProfileScreen(userId: 'usuario_de_prueba'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'falló en $size');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('el perfil define las 5 pestañas del PRD', (tester) async {
    // El enum es la fuente de verdad de las pestañas: si cambia, el test falla.
    expect(ProfileTab.values.length, 5);
    expect(
      ProfileTab.values.map((t) => t.label).toList(),
      ['Publicaciones', 'Juegos', 'Multimedia', 'Me gusta', 'Acerca de'],
    );
    // Cada pestaña tiene icono lineal asociado.
    for (final tab in ProfileTab.values) {
      expect(tab.icon, isNotNull);
    }
  });
}
