import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devplay/models/post.dart';
import 'package:devplay/theme.dart';
import 'package:devplay/widgets/post_card.dart';

Post _post({
  String id = 'p1',
  PostType type = PostType.post,
  String content = 'Contenido de prueba',
  bool liked = false,
  int likes = 3,
  int comments = 2,
  bool bookmarked = false,
  Post? original,
}) {
  return Post(
    id: id,
    type: type,
    content: content,
    likesCount: likes,
    commentsCount: comments,
    liked: liked,
    bookmarked: bookmarked,
    createdAt: DateTime(2026, 1, 1),
    author: const PostAuthor(
      id: 'u1',
      username: 'frank_dev',
      fullName: 'Frank Dev',
    ),
    originalPost: original,
  );
}

void main() {
  testWidgets('el feed no muestra el botón de guardar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDevPlayTheme(),
        home: Scaffold(
          body: PostCard(post: _post()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
  });

  testWidgets('el perfil sí muestra el botón de guardar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDevPlayTheme(),
        home: Scaffold(
          body: PostCard(post: _post(), showSave: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
  });

  testWidgets('la tarjeta muestra el botón de repost', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDevPlayTheme(),
        home: Scaffold(
          body: PostCard(post: _post()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.repeat_on_rounded), findsOneWidget);
  });

  testWidgets('un repost muestra la atribución del autor original',
      (tester) async {
    final original = _post(id: 'orig', content: 'El post original');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDevPlayTheme(),
        home: Scaffold(
          body: PostCard(post: _post(content: '', original: original)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Republicado de @frank_dev'), findsOneWidget);
  });
}
