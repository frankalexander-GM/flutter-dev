import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/theme.dart';
import 'package:devplay/widgets/hero_3d_shapes.dart';

void main() {
  testWidgets('las formas 3D montan en escritorio y móvil', (tester) async {
    for (final style in Hero3DStyle.values) {
      for (final size in [const Size(1200, 420), const Size(360, 240)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildDevPlayTheme(),
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: Hero3DShapes(style: style),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }

    await tester.binding.setSurfaceSize(null);
  });
}
