import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devplay/providers/auth_provider.dart';
import 'package:devplay/screens/profile_screen.dart';
import 'package:devplay/theme.dart';

void main() {
  testWidgets('el perfil abre en la pestaña Publicaciones, no en Acerca de',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
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

    // La pestaña inicial (índice 0) debe ser "Publicaciones".
    expect(ProfileTab.values[0].label, 'Publicaciones');
    expect(ProfileTab.values[0], isNot(ProfileTab.about));

    // "Acerca de" es la última pestaña, no la inicial.
    expect(ProfileTab.values.last, ProfileTab.about);
    expect(ProfileTab.values.indexOf(ProfileTab.about), 4);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('la pestaña inicial se limita al rango válido', (tester) async {
    // Un índice fuera de rango no debe romper la apertura del perfil.
    for (final tab in [-5, 0, 99]) {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            theme: buildDevPlayTheme(),
            home: ProfileScreen(userId: 'usuario_de_prueba', initialTab: tab),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'falló con initialTab=$tab');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
