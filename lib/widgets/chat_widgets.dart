import 'package:flutter/material.dart';

import '../theme.dart';
import 'avatar.dart';

/// `true` si ambas fechas caen el mismo día (en hora local).
bool sameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Hora local en formato `HH:mm`.
String clockTime(DateTime date) {
  final local = date.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Etiqueta de fecha para separar bloques de mensajes.
class ChatDayChip extends StatelessWidget {
  final DateTime date;
  const ChatDayChip({super.key, required this.date});

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _label() {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: DevColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: DevColors.border),
          ),
          child: Text(
            _label(),
            style: DevTheme.labelCaps(size: 9, color: DevColors.mutedFg),
          ),
        ),
      ),
    );
  }
}

/// Burbuja de mensaje (chat global y directos comparten diseño).
class ChatBubble extends StatelessWidget {
  final String username;
  final String? avatar;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final bool showHeader;
  final bool pending;

  /// Abre un mensaje directo con el autor (solo en el chat mundial).
  final VoidCallback? onAvatarTap;

  const ChatBubble({
    super.key,
    required this.username,
    this.avatar,
    required this.content,
    required this.createdAt,
    required this.isMine,
    this.showHeader = true,
    this.pending = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isMine ? DevColors.primary : DevColors.cardRaised,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 5),
          bottomRight: Radius.circular(isMine ? 5 : 16),
        ),
        border: isMine ? null : Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        content,
        style: DevTheme.body(
          size: 13.5,
          color: isMine ? Colors.white : DevColors.foreground,
          height: 1.35,
        ),
      ),
    );

    final meta = showHeader
        ? Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMine) ...[
                  Flexible(
                    child: Text(
                      '@$username',
                      style: DevTheme.body(
                        size: 12,
                        w: FontWeight.w700,
                        color: DevColors.goldSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  clockTime(createdAt),
                  style: DevTheme.bodySecondary(size: 10.5),
                ),
                if (pending) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.schedule_rounded,
                    size: 11,
                    color: DevColors.mutedFg,
                  ),
                ],
              ],
            ),
          )
        : null;

    final column = Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ?meta,
        bubble,
      ],
    );

    final avatarWidget = UserAvatar(
      username: username,
      avatar: avatar,
      size: 30,
    );
    final tappableAvatar = onAvatarTap == null
        ? avatarWidget
        : Tooltip(
            message: 'Enviar mensaje a @$username',
            child: InkWell(
              onTap: onAvatarTap,
              borderRadius: BorderRadius.circular(15),
              child: avatarWidget,
            ),
          );

    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 12 : 3),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            if (showHeader) tappableAvatar else const SizedBox(width: 30),
            const SizedBox(width: 8),
          ],
          Flexible(child: column),
          if (isMine) ...[
            const SizedBox(width: 8),
            if (showHeader) tappableAvatar else const SizedBox(width: 30),
          ],
        ],
      ),
    );
  }
}

/// Barra de escritura reutilizable (mundo y directos).
class ChatComposer extends StatefulWidget {
  final Future<bool> Function(String text) onSend;
  final bool canChat;
  final bool isGuest;
  final VoidCallback? onOpenAuth;
  final String hint;
  final int maxLength;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.canChat,
    this.isGuest = false,
    this.onOpenAuth,
    this.hint = 'Escribe un mensaje...',
    this.maxLength = 500,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  int _count = 0;

  static const _emojis = ['😀', '😂', '🔥', '❤️', '🎮', '🚀'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final n = _controller.text.length;
    if (n != _count) setState(() => _count = n);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    final before = _controller.text;
    setState(() => _busy = true);
    _controller.clear();
    final ok = await widget.onSend(text);
    if (!mounted) return;
    if (!ok) _controller.text = before;
    setState(() => _busy = false);
    _focus.requestFocus();
  }

  void _insertEmoji(String emoji) {
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.isValid ? selection.start : text.length;
    final cursor = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(offset, cursor, emoji);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset + emoji.length),
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canChat) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: const BoxDecoration(
          color: DevColors.cardRaised,
          border: Border(top: BorderSide(color: DevColors.border)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: DevColors.mutedFg,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.isGuest
                    ? 'Estás en modo invitado: puedes leer, pero no escribir.'
                    : 'Inicia sesión para participar en el chat.',
                style: DevTheme.bodySecondary(size: 12),
              ),
            ),
            if (widget.onOpenAuth != null)
              TextButton(
                onPressed: widget.onOpenAuth,
                child: Text(
                  'Iniciar sesión',
                  style: DevTheme.body(
                    size: 12.5,
                    w: FontWeight.w700,
                    color: DevColors.goldSoft,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final canSend = _count > 0 && !_busy;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: DevColors.cardRaised,
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  maxLines: 1,
                  maxLength: widget.maxLength,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: DevTheme.body(size: 14),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: DevColors.muted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: DevColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: DevColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: DevColors.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                width: 46,
                child: ElevatedButton(
                  onPressed: canSend ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DevColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DevColors.muted,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ..._emojis.map(
                (e) => InkWell(
                  onTap: () => _insertEmoji(e),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$_count/${widget.maxLength}',
                style: DevTheme.bodySecondary(
                  size: 10.5,
                  color: _count >= widget.maxLength
                      ? DevColors.destructive
                      : DevColors.mutedFg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
