import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/avatar.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/hero_3d_shapes.dart';
import '../widgets/hero_video.dart';
import 'direct_chat_screen.dart';

enum ChatTab { world, dms }

/// Vista "Chat Mundial": sala general en vivo + mensajes directos.
class ChatScreen extends StatefulWidget {
  final VoidCallback? onOpenAuth;
  const ChatScreen({super.key, this.onOpenAuth});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatTab _tab = ChatTab.world;
  static const int _pageSize = 50;

  // ---- Chat global ----
  List<ChatMessage> _messages = []; // del más nuevo al más viejo
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  Timer? _poll;
  final _scroll = ScrollController();

  /// Mensajes de historial descargados (para el `skip` de la paginación).
  /// Los mensajes nuevos que llegan por polling no cuentan aquí.
  int _historyCount = 0;

  // ---- Mensajes directos ----
  List<Conversation> _conversations = [];
  bool _loadingDms = true;
  String? _dmsError;
  int _unreadDms = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMessages();
    _loadUnreadDms();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _onTick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  String get _myId => context.read<AuthProvider>().user?.id ?? '';

  void _onTick() {
    if (!mounted) return;
    _refreshLatest();
    if (_tab == ChatTab.dms) {
      _loadConversations(silent: true);
    } else {
      _loadUnreadDms();
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  // ------------------------------------------------------------- Mundial

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final msgs = await ChatService.getWorldMessages(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _historyCount = msgs.length;
        _hasMore = msgs.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final msgs = await ChatService.getWorldMessages(
        skip: _historyCount,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, ...msgs];
        _historyCount += msgs.length;
        _hasMore = msgs.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refreshLatest() async {
    if (_loading || _loadingMore) return;
    try {
      final latest = await ChatService.getWorldMessages(limit: _pageSize);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final nuevos = latest.where((m) => !known.contains(m.id)).toList();
      if (nuevos.isEmpty) return;
      setState(() => _messages = [...nuevos, ..._messages]);
    } catch (_) {
      // Silencioso: el polling no debe molestar si falla una vez.
    }
  }

  Future<bool> _sendWorld(String text) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || user.isGuest) return false;

    final temp = ChatMessage(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      userId: user.id,
      username: user.username,
      content: text,
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() => _messages = [temp, ..._messages]);
    _scrollToBottom();

    try {
      final real = await ChatService.sendWorldMessage(text);
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
      _snack('No se pudo enviar: ${_friendly(e)}');
      return false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ----------------------------------------------------------------- DMs

  void _loadUnreadDms() async {
    try {
      final unread = await ChatService.getUnreadDms();
      if (!mounted) return;
      if (unread != _unreadDms) setState(() => _unreadDms = unread);
    } catch (_) {}
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingDms = true;
        _dmsError = null;
      });
    }
    try {
      final items = await ChatService.getConversations();
      items.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _loadingDms = false;
        _unreadDms = items.fold(0, (sum, c) => sum + c.unreadCount);
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _dmsError = e.toString();
          _loadingDms = false;
        });
      }
    }
  }

  Future<void> _openDirect(
    String peerId,
    String peerUsername, {
    String? peerAvatar,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          peerId: peerId,
          peerUsername: peerUsername,
          peerAvatar: peerAvatar,
        ),
      ),
    );
    if (!mounted) return;
    _loadUnreadDms();
    if (_tab == ChatTab.dms) _loadConversations(silent: true);
  }

  Future<void> _newDirect() async {
    final raw = await _askUsername();
    if (raw == null || !mounted) return;
    final username = raw.trim().replaceAll('@', '');
    if (username.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: DevColors.primary),
      ),
    );
    try {
      final id = await UserService.getUserIdByUsername(username);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (id == null) {
        _snack('No existe @$username');
        return;
      }
      if (id == _myId) {
        _snack('No puedes escribirte a ti mismo');
        return;
      }
      await _openDirect(id, username);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(e.statusCode == 404 ? 'No existe @$username' : e.detail);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack('No se pudo abrir el chat: $e');
    }
  }

  Future<String?> _askUsername() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DevColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DevColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: DevColors.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Nuevo mensaje',
              style: DevTheme.display(size: 18, w: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribe el nombre de usuario con quien quieres hablar.',
              style: DevTheme.bodySecondary(size: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: DevTheme.body(size: 14),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
              decoration: InputDecoration(
                hintText: '@usuario',
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  size: 18,
                  color: DevColors.mutedFg,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendly(Object e) => e is ApiException ? e.detail : '$e';

  // ---------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.user?.isGuest ?? true;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: _ChatHero(
            tab: _tab,
            unreadDms: _unreadDms,
            onTab: (t) {
              setState(() => _tab = t);
              if (t == ChatTab.dms) _loadConversations();
            },
          ),
        ),
        Expanded(
          child: _tab == ChatTab.world
              ? _buildWorld(auth.user?.id ?? '', isGuest)
              : _buildDms(),
        ),
      ],
    );
  }

  Widget _buildWorld(String myId, bool isGuest) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final panel = _buildChatPanel(myId, isGuest);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: panel),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 280,
                      child: _CommunityPanel(
                        messages: _messages,
                        myId: myId,
                        onDm: (msg) => _openDirect(msg.userId, msg.username),
                      ),
                    ),
                  ],
                )
              : panel,
        );
      },
    );
  }

  Widget _buildChatPanel(String myId, bool isGuest) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: DevColors.cardRaised,
              border: Border(bottom: BorderSide(color: DevColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DevColors.consoleGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Sala general',
                  style: DevTheme.body(size: 13, w: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Todos los desarrolladores pueden leer',
                    style: DevTheme.bodySecondary(size: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _loadMessages,
                  tooltip: 'Recargar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: DevColors.mutedFg,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMessageList(myId)),
          ChatComposer(
            onSend: _sendWorld,
            canChat: !isGuest,
            isGuest: isGuest,
            onOpenAuth: widget.onOpenAuth,
            hint: 'Escribe un mensaje...',
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(String myId) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DevColors.primary),
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadMessages);
    }
    if (_messages.isEmpty) {
      return _EmptyState(
        icon: Icons.forum_rounded,
        title: 'Sé el primero en escribir',
        subtitle: 'El chat mundial está esperando a la comunidad 🌍',
      );
    }

    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: _messages.length + 1,
      itemBuilder: (context, index) {
        if (index == _messages.length) return _listTopTile();
        final msg = _messages[index];
        final older = index + 1 < _messages.length
            ? _messages[index + 1]
            : null;
        final showHeader =
            older == null ||
            older.userId != msg.userId ||
            msg.createdAt.difference(older.createdAt).inMinutes.abs() > 5;
        final showDay =
            older == null || !sameDay(older.createdAt, msg.createdAt);
        return Column(
          children: [
            if (showDay) ChatDayChip(date: msg.createdAt),
            ChatBubble(
              username: msg.username,
              content: msg.content,
              createdAt: msg.createdAt,
              isMine: msg.userId == myId,
              showHeader: showHeader,
              pending: msg.pending,
              onAvatarTap: msg.userId == myId
                  ? null
                  : () => _openDirect(msg.userId, msg.username),
            ),
          ],
        );
      },
    );
  }

  Widget _listTopTile() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DevColors.primary,
            ),
          ),
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('Cargar mensajes anteriores'),
            style: TextButton.styleFrom(foregroundColor: DevColors.goldSoft),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'Aquí empieza el chat mundial ✨',
          style: DevTheme.bodySecondary(size: 11),
        ),
      ),
    );
  }

  Widget _buildDms() {
    Widget body;
    if (_loadingDms && _conversations.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(color: DevColors.primary),
      );
    } else if (_dmsError != null && _conversations.isEmpty) {
      body = _ErrorState(
        message: _dmsError!,
        onRetry: () => _loadConversations(),
      );
    } else if (_conversations.isEmpty) {
      body = _EmptyState(
        icon: Icons.mark_chat_unread_rounded,
        title: 'Aún no tienes mensajes',
        subtitle:
            'Busca a alguien por su @usuario y empieza una '
            'conversación privada.',
        actionLabel: 'Nuevo mensaje',
        onAction: _newDirect,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => _loadConversations(),
        color: DevColors.primary,
        backgroundColor: DevColors.card,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _conversations.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: DevColors.border),
          itemBuilder: (context, i) => _ConversationTile(
            conversation: _conversations[i],
            onTap: () => _openDirect(
              _conversations[i].peerId,
              _conversations[i].peerUsername,
              peerAvatar: _conversations[i].peerAvatar,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DevColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DevColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              decoration: const BoxDecoration(
                color: DevColors.cardRaised,
                border: Border(bottom: BorderSide(color: DevColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.forum_rounded,
                    size: 17,
                    color: DevColors.gold,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Mensajes directos',
                      style: DevTheme.body(size: 13, w: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _newDirect,
                    icon: const Icon(Icons.add_comment_rounded, size: 16),
                    label: const Text('Nuevo'),
                    style: TextButton.styleFrom(
                      foregroundColor: DevColors.goldSoft,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Hero + tabs

class _ChatHero extends StatelessWidget {
  final ChatTab tab;
  final int unreadDms;
  final ValueChanged<ChatTab> onTab;

  const _ChatHero({
    required this.tab,
    required this.unreadDms,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF0A101D), Color(0xFF0A101D)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: DevColors.wine.withValues(alpha: 0.2),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Video 3D en loop como fondo del hero (mismo asset que Inicio).
          Positioned.fill(
            child: HeroVideo(
              videoAsset: 'assets/videos/hero_loop_crystal_loop',
              posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
              autoPlay: true,
              mute: true,
              shapeOpacity: 0.35,
              shapeStyle: Hero3DStyle.home,
              enablePointerInterceptor: true,
              scrimOpacity: 0.32,
            ),
          ),
          Positioned(
            right: -22,
            bottom: -30,
            child: Icon(
              Icons.public_rounded,
              size: 150,
              color: DevColors.gold.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 620;
                final info = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: DevColors.btnGradient(),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: DevColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Chat Mundial',
                                  style: DevTheme.display(
                                    size: wide ? 23 : 20,
                                    w: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const _LiveBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Conversa con la comunidad en tiempo real',
                            style: DevTheme.bodySecondary(size: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final tabs = _TabSwitch(
                  tab: tab,
                  unreadDms: unreadDms,
                  onTab: onTab,
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: info),
                      const SizedBox(width: 16),
                      tabs,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    info,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerLeft, child: tabs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: DevColors.consoleGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: DevColors.consoleGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: DevColors.consoleGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'EN VIVO',
            style: DevTheme.labelCaps(size: 9, color: DevColors.consoleGreen),
          ),
        ],
      ),
    );
  }
}

class _TabSwitch extends StatelessWidget {
  final ChatTab tab;
  final int unreadDms;
  final ValueChanged<ChatTab> onTab;

  const _TabSwitch({
    required this.tab,
    required this.unreadDms,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DevColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DevColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            label: 'Mundial',
            icon: Icons.public_rounded,
            value: ChatTab.world,
            badge: 0,
          ),
          _button(
            label: 'Mensajes',
            icon: Icons.forum_rounded,
            value: ChatTab.dms,
            badge: unreadDms,
          ),
        ],
      ),
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required ChatTab value,
    required int badge,
  }) {
    final active = tab == value;
    return GestureDetector(
      onTap: () => onTab(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? DevColors.btnGradient() : null,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : DevColors.mutedFg,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: DevTheme.body(
                size: 12.5,
                w: FontWeight.w700,
                color: active ? Colors.white : DevColors.mutedFg,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white : DevColors.destructive,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: active ? DevColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------ Panel de comunidad

class _CommunityPanel extends StatelessWidget {
  final List<ChatMessage> messages;
  final String myId;
  final void Function(ChatMessage) onDm;

  const _CommunityPanel({
    required this.messages,
    required this.myId,
    required this.onDm,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    final order = <String>[];
    final latest = <String, ChatMessage>{};
    for (final m in messages) {
      if (m.userId.isEmpty) continue;
      counts[m.userId] = (counts[m.userId] ?? 0) + 1;
      if (!latest.containsKey(m.userId)) {
        latest[m.userId] = m;
        order.add(m.userId);
      }
    }
    final top = order.take(8).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DevColors.border),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _sectionTitle('Últimos en escribir'),
          const SizedBox(height: 4),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no hay actividad en la sala.',
                style: DevTheme.bodySecondary(size: 12),
              ),
            )
          else
            ...top.map((id) {
              final msg = latest[id]!;
              final isMe = id == myId;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    UserAvatar(username: msg.username, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${msg.username}',
                            style: DevTheme.body(
                              size: 12.5,
                              w: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${counts[id]} ${counts[id] == 1 ? 'mensaje' : 'mensajes'}',
                            style: DevTheme.bodySecondary(size: 10.5),
                          ),
                        ],
                      ),
                    ),
                    if (!isMe)
                      IconButton(
                        onPressed: () => onDm(msg),
                        tooltip: 'Enviar mensaje',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: DevColors.goldSoft,
                        ),
                      ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 18),
          _sectionTitle('Normas de la sala'),
          const SizedBox(height: 8),
          const _Rule(text: 'Sé respetuoso con el resto de la comunidad.'),
          const _Rule(text: 'Nada de spam ni autopromoción excesiva.'),
          const _Rule(text: 'Comparte feedback constructivo.'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: DevTheme.labelCaps(size: 10, color: DevColors.goldSoft),
  );
}

class _Rule extends StatelessWidget {
  final String text;
  const _Rule({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: DevColors.mutedFg,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: DevTheme.bodySecondary(
                size: 11.5,
                color: DevColors.mutedFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Lista DMs

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  username: conversation.peerUsername,
                  avatar: conversation.peerAvatar,
                  size: 46,
                ),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DevColors.destructive,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: DevColors.card, width: 2),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '@${conversation.peerUsername}',
                          style: DevTheme.body(
                            size: 14,
                            w: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo(conversation.lastMessageAt),
                        style: DevTheme.bodySecondary(size: 10.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage,
                    style: DevTheme.bodySecondary(
                      size: 12.5,
                      color: unread > 0
                          ? DevColors.foreground
                          : DevColors.mutedFg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- Estados

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DevColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DevColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, size: 30, color: DevColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: DevTheme.display(size: 16, w: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                subtitle,
                style: DevTheme.body(
                  size: 12.5,
                  color: DevColors.mutedFg,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 34,
              color: DevColors.mutedFg,
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el chat',
              style: DevTheme.body(size: 14, w: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                style: DevTheme.bodySecondary(size: 11.5),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
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
}
