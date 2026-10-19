import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/chat_widgets.dart';

/// Conversación privada con un usuario (`GET/POST /dm/{userId}`).
class DirectChatScreen extends StatefulWidget {
  final String peerId;
  final String peerUsername;
  final String? peerAvatar;

  const DirectChatScreen({
    super.key,
    required this.peerId,
    required this.peerUsername,
    this.peerAvatar,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  List<DirectMessage> _messages = []; // del más nuevo al más viejo
  bool _loading = true;
  String? _error;
  Timer? _poll;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final msgs = await ChatService.getDirectMessages(widget.peerId);
      if (!mounted) return;
      setState(() {
        _messages = msgs.reversed.toList();
        _loading = false;
      });
      _markRead();
      _scrollToBottom(animate: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final msgs = await ChatService.getDirectMessages(widget.peerId);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final nuevos =
          msgs.reversed.where((m) => !known.contains(m.id)).toList();
      if (nuevos.isEmpty) return;
      setState(() => _messages = [...nuevos, ..._messages]);
      _markRead();
    } catch (_) {
      // Silencioso.
    }
  }

  Future<void> _markRead() async {
    try {
      await ChatService.markConversationRead(widget.peerId);
    } catch (_) {}
  }

  Future<bool> _send(String text) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return false;

    final temp = DirectMessage(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      senderId: user.id,
      recipientId: widget.peerId,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() => _messages = [temp, ..._messages]);
    _scrollToBottom();

    try {
      final real = await ChatService.sendDirectMessage(widget.peerId, text);
      if (!mounted) return true;
      final rest = _messages
          .where((m) => m.id != temp.id && m.id != real.id)
          .toList();
      setState(() => _messages = [real, ...rest]);
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(
        () => _messages = _messages.where((m) => m.id != temp.id).toList(),
      );
      final detail = e is ApiException ? e.detail : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar: $detail')),
      );
      return false;
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (animate) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myId = auth.user?.id ?? '';
    final myUsername = auth.user?.username ?? '';
    final isGuest = auth.user?.isGuest ?? true;

    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.card,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              username: widget.peerUsername,
              avatar: widget.peerAvatar,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${widget.peerUsername}',
                    style: DevTheme.display(size: 16, w: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Mensaje directo',
                    style: DevTheme.bodySecondary(size: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildList(myId, myUsername)),
          ChatComposer(
            onSend: _send,
            canChat: !isGuest,
            isGuest: isGuest,
            hint: 'Escribe a @${widget.peerUsername}...',
            maxLength: 2000,
          ),
        ],
      ),
    );
  }

  Widget _buildList(String myId, String myUsername) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DevColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: DevColors.mutedFg,
              ),
              const SizedBox(height: 10),
              Text(
                'No se pudo abrir la conversación',
                style: DevTheme.body(size: 14, w: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DevColors.primary,
                  side: const BorderSide(color: DevColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                username: widget.peerUsername,
                avatar: widget.peerAvatar,
                size: 64,
              ),
              const SizedBox(height: 14),
              Text(
                'Aún no hay mensajes',
                style: DevTheme.display(size: 16, w: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Saluda a @${widget.peerUsername} y empieza la conversación.',
                style: DevTheme.body(
                  size: 12.5,
                  color: DevColors.mutedFg,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final older =
            index + 1 < _messages.length ? _messages[index + 1] : null;
        final isMine = msg.senderId == myId;
        final showHeader = older == null ||
            older.senderId != msg.senderId ||
            msg.createdAt.difference(older.createdAt).inMinutes.abs() > 5;
        final showDay =
            older == null || !sameDay(older.createdAt, msg.createdAt);
        return Column(
          children: [
            if (showDay) ChatDayChip(date: msg.createdAt),
            ChatBubble(
              username: isMine ? myUsername : widget.peerUsername,
              avatar: isMine ? null : widget.peerAvatar,
              content: msg.content,
              createdAt: msg.createdAt,
              isMine: isMine,
              showHeader: showHeader,
              pending: msg.id.startsWith('temp-'),
            ),
          ],
        );
      },
    );
  }
}
