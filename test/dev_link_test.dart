import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/utils/dev_link.dart';

void main() {
  group('DevLink', () {
    test('extrae el usuario del query param ?user=', () {
      final uri = Uri.parse('https://devplay.app/?user=frank_dev');
      expect(DevLink.usernameFrom(uri), 'frank_dev');
    });

    test('extrae el usuario de una ruta /user/xxx', () {
      final uri = Uri.parse('https://devplay.app/user/frank_dev');
      expect(DevLink.usernameFrom(uri), 'frank_dev');
    });

    test('extrae el usuario de un hash #/user/xxx', () {
      final uri = Uri.parse('https://devplay.app/#/user/frank_dev');
      expect(DevLink.usernameFrom(uri), 'frank_dev');
    });

    test('devuelve null si no hay usuario en la URL', () {
      expect(DevLink.usernameFrom(Uri.parse('https://devplay.app/')), isNull);
      expect(
        DevLink.usernameFrom(Uri.parse('https://devplay.app/?user=')),
        isNull,
      );
    });

    test('construye la URL pública de un perfil', () {
      expect(
        DevLink.profileUrl('frank_dev', origin: 'https://devplay.app'),
        'https://devplay.app/?user=frank_dev',
      );
    });

    test('la URL construida se puede volver a interpretar', () {
      final url = DevLink.profileUrl('frank_dev', origin: 'https://devplay.app');
      expect(DevLink.usernameFrom(Uri.parse(url)), 'frank_dev');
    });
  });
}
