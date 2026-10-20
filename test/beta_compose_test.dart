import 'package:devplay/theme.dart';
import 'package:devplay/widgets/beta_compose_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildDevPlayTheme(),
  home: Scaffold(backgroundColor: DevColors.background, body: child),
);

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    _app(SizedBox(width: size.width, height: size.height, child: child)),
  );
  await tester.pump();
}

void main() {
  testWidgets('BetaComposeSheet monta sin overflow en escritorio y móvil', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(1280, 900), Size(390, 844)]) {
      await _pumpAt(tester, size, const BetaComposeSheet());
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull, reason: 'tamaño $size');
      expect(find.text('Publicar beta'), findsOneWidget);
      expect(find.text('Cuéntanos qué estás construyendo'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });

  testWidgets('Valida los campos y avanza entre pasos', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAt(tester, const Size(390, 844), const BetaComposeSheet());

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'paso 1');
    expect(find.text('Este campo es obligatorio'), findsWidgets);
    expect(find.text('Cuéntanos qué estás construyendo'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Beta de prueba');
    await tester.enterText(
      fields.at(1),
      'Una descripción suficientemente larga para la prueba.',
    );
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'paso 2');
    expect(find.text('Presentación visual'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'paso 3');
    expect(find.text('Distribución'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'validación paso 3');
    expect(find.text('Distribución'), findsOneWidget);
    expect(find.text('Este campo es obligatorio'), findsWidgets);

    final deliveryFields = find.byType(TextFormField);
    await tester.enterText(
      deliveryFields.at(0),
      'https://example.com/build.zip',
    );
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'paso 4');
    expect(find.text('Revisión y protocolo'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Publicar beta'));
    await tester.pumpAndSettle();
    expect(find.text('Revisión y protocolo'), findsOneWidget);
    expect(
      find.text('Debes aceptar los tres protocolos antes de publicar.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull, reason: 'protocolos');
  });
}
