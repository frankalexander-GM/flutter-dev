import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/models/user.dart';

void main() {
  test('el perfil público parsea el nombre visible del backend', () {
    // Respuesta real de `GET /users/{id}` (snake_case en el usuario).
    final json = <String, dynamic>{
      'id': 'u1',
      'username': 'frank_dev',
      'full_name': 'Frank Dev',
      'bio': 'Dev indie de juegos 2D en Godot.',
      'avatar': null,
      'banner': null,
      'role': 'USER',
      'is_guest': false,
      'tags': ['godot', 'pixelart'],
      'location': 'Valencia, España',
      'website': 'https://github.com/frankdev',
      'profession': 'Game Developer',
      'created_at': '2026-01-15T10:00:00',
      'followersCount': 4,
      'followingCount': 0,
      'postsCount': 6,
      'isFollowing': false,
    };

    final profile = ProfileUser.fromJson(json);
    expect(profile.fullName, 'Frank Dev');
    expect(profile.username, 'frank_dev');
    expect(profile.bio, isNotNull);
    expect(profile.tags, ['godot', 'pixelart']);
    expect(profile.followersCount, 4);
    expect(profile.postsCount, 6);
  });
}
