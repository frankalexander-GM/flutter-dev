import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devplay/models/navigation.dart';
import 'package:devplay/models/user.dart';
import 'package:devplay/providers/auth_provider.dart';
import 'package:devplay/theme.dart';
import 'package:devplay/widgets/sidebar.dart';

/// Provider con un usuario ya autenticado (para que se vea la tarjeta).
class _AuthWithUser extends AuthProvider {
  @override
  UserMe? get user => UserMe(
    id: 'u1',
    email: 'a@b.com',
    username: 'frank_dev',
    role: 'USER',
    language: 'es',
    isGuest: false,
    isPrivate: false,
    tourCompleted: true,
    devCoins: 100,
    createdAt: DateTime(2026, 1, 1),
  );

  @override
  bool get isAuthenticated => true;
}

void main() {
  testWidgets('la tarjeta del usuario del sidebar abre el perfil',
      (tester) async {
    var profileTaps = 0;
    var settingsTaps = 0;

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _AuthWithUser(),
        child: MaterialApp(
          theme: buildDevPlayTheme(),
          home: Scaffold(
            body: DevSidebar(
              currentView: ViewId.explore,
              onViewChanged: (_) {},
              onProfileTap: () => profileTaps++,
              onSettingsTap: () => settingsTaps++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // El engranaje es un botón aparte (configuración), no el perfil.
    final settings = find.byTooltip('Configuración');
    expect(settings, findsOneWidget);

    // El nombre de usuario es la entrada al perfil.
    expect(find.text('frank_dev'), findsOneWidget);
    await tester.tap(find.text('frank_dev'));
    await tester.pump();
    expect(profileTaps, 1);
    expect(settingsTaps, 0);

    // El engranaje dispara su propia acción.
    await tester.tap(settings);
    await tester.pump();
    expect(settingsTaps, 1);
    expect(profileTaps, 1);

    await tester.binding.setSurfaceSize(null);
  });
}
