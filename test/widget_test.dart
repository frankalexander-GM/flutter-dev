// Test de humo: la app de DevPlay arranca con el tema oscuro y, sin sesión,
// muestra la pantalla de login (gate de autenticación).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devplay/main.dart';
import 'package:devplay/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('El tema DevPlay es oscuro con la paleta de la web', () {
    final theme = buildDevPlayTheme();
    expect(theme.scaffoldBackgroundColor, DevColors.background);
    expect(theme.brightness, isNotNull);
    expect(theme.colorScheme.surface, DevColors.card);
  });

  testWidgets('sin sesión arranca en el login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DevPlayApp());
    await tester.pumpAndSettle();

    expect(find.text('DevPlay'), findsWidgets);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Entrar como invitado'), findsOneWidget);
  });
}
