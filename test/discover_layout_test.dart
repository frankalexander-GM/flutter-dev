import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:devplay/providers/auth_provider.dart';
import 'package:devplay/screens/discover_screen.dart';
import 'package:devplay/theme.dart';

void main() {
  testWidgets('DiscoverScreen monta sin excepciones en escritorio y móvil',
      (tester) async {
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            theme: buildDevPlayTheme(),
            home: const DiscoverScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'falló en $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
