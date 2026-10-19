import 'package:devplay/models/chat.dart';
import 'package:devplay/providers/auth_provider.dart';
import 'package:devplay/screens/chat_screen.dart';
import 'package:devplay/theme.dart';
import 'package:devplay/widgets/chat_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        theme: buildDevPlayTheme(),
        home: Scaffold(
          backgroundColor: DevColors.background,
          body: child,
        ),
      ),
    );

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(_app(child));
  await tester.pump();
}

void main() {
  testWidgets('ChatScreen monta sin excepciones en escritorio y móvil',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(1280, 900), Size(390, 844)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(const ChatScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull, reason: 'tamaño $size');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });

  testWidgets('Burbuja ajena larga no desborda', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpAt(
      tester,
      const Size(390, 844),
      SingleChildScrollView(
        child: ChatBubble(
          username: 'un_nombre_de_usuario_larguisimo',
          content: 'Hola comunidad ' * 60,
          createdAt: DateTime.now(),
          isMine: false,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burbuja propia larga no desborda', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpAt(
      tester,
      const Size(390, 844),
      SingleChildScrollView(
        child: ChatBubble(
          username: 'yo',
          content: 'Mensaje propio ' * 60,
          createdAt: DateTime.now(),
          isMine: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Composer activo no desborda', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpAt(
      tester,
      const Size(390, 844),
      Column(
        children: [
          ChatComposer(onSend: (_) async => true, canChat: true),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Composer invitado no desborda', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpAt(
      tester,
      const Size(320, 800),
      Column(
        children: [
          ChatComposer(
            onSend: (_) async => true,
            canChat: false,
            isGuest: true,
            onOpenAuth: () {},
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Modelos parsean el contrato del backend', (tester) async {
    final msg = ChatMessage.fromJson({
      'id': 'm1',
      'userId': 'u1',
      'username': 'ana',
      'content': 'hola',
      'createdAt': '2026-10-18T21:18:41.370604-05:00',
    });
    expect(msg.id, 'm1');
    expect(msg.username, 'ana');

    final conv = Conversation.fromJson({
      'peerId': 'u2',
      'peerUsername': 'leo',
      'peerAvatar': null,
      'lastMessage': 'hey',
      'lastMessageAt': '2026-10-18T21:20:00-05:00',
      'unreadCount': 3,
    });
    expect(conv.unreadCount, 3);

    final dm = DirectMessage.fromJson({
      'id': 'd1',
      'senderId': 'u2',
      'recipientId': 'u1',
      'content': 'hey',
      'readAt': null,
      'createdAt': '2026-10-18T21:20:00-05:00',
    });
    expect(dm.recipientId, 'u1');
    expect(dm.readAt, isNull);
  });
}
