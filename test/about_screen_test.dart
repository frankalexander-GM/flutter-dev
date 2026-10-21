import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/screens/about_screen.dart';
import 'package:devplay/theme.dart';

void main() {
  testWidgets(
    'Acerca de DevPlay muestra la información legal y abre los términos',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: buildDevPlayTheme(), home: const AboutScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acerca de DevPlay'), findsOneWidget);
      expect(find.text('Términos y condiciones'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
      expect(find.text('Normas de la comunidad'), findsOneWidget);
      expect(find.text('Cookies y almacenamiento local'), findsOneWidget);

      final terms = find.text('Términos y condiciones');
      await tester.ensureVisible(terms);
      await tester.pumpAndSettle();
      await tester.tap(terms);
      await tester.pumpAndSettle();

      expect(find.text('1. Aceptación'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Entendido'), findsNothing);
    },
  );
  testWidgets('Acerca de DevPlay no desborda en móvil y abre privacidad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: buildDevPlayTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    final privacy = find.text('Política de privacidad');
    await tester.ensureVisible(privacy);
    await tester.pumpAndSettle();
    await tester.tap(privacy);
    await tester.pumpAndSettle();

    expect(find.text('2. Datos que tratamos'), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);
  });
}
