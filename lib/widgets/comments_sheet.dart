import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../services/post_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'avatar.dart';

/// Abre la hoja de comentarios real de un post.
///
/// Carga `GET /posts/{id}/comments`, publica con `POST /posts/{id}/comments` y
/// permite borrar los propios con `DELETE /posts/{id}/comments/{commentId}`.
Future<void> showCommentsSheet(
  BuildContext context, {
  required Post post,
  ValueChanged<int>? onCountChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DevColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CommentsSheet(post: post, onCountChanged: onCountChanged),
  );
}

class _CommentsSheet extends StatefulWidget {
  final Post post;
  final ValueChanged<int>? onCountChanged;

  const _CommentsSheet({required this.post, this.onCountChanged});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focus = FocusNode();

  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await PostService.getComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
      widget.onCountChanged?.call(comments.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) return;
    if (content.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El comentario supera los 2000 caracteres')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final comment = await PostService.addComment(
        widget.post.id,
        content: content,
      );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, comment];
        _sending = false;
      });
      _controller.clear();
      widget.onCountChanged?.call(_comments.length);
      _scrollToEnd();
      _focus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo comentar: $e')),
      );
    }
  }

  Future<void> _delete(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Borrar comentario', style: DevTheme.display(size: 16)),
        content: Text(
          '¿Seguro que quieres borrar este comentario?',
          style: DevTheme.body(size: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: DevTheme.body(color: DevColors.mutedFg)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.destructive,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await PostService.deleteComment(widget.post.id, comment.id);
      if (!mounted) return;
      setState(() => _comments = _comments.where((c) => c.id != comment.id).toList());
      widget.onCountChanged?.call(_comments.length);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final user = context.watch<AuthProvider>().user;
    final isMod = user?.role == 'ADMIN' || user?.role == 'DEV';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (size.height - keyboard) * 0.82,
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(color: DevColors.border, height: 1),
            Expanded(child: _buildBody(user?.id, isMod)),
            const Divider(color: DevColors.border, height: 1),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: DevColors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.forum_rounded, size: 18, color: DevColors.primary),
          const SizedBox(width: 8),
          Text('Comentarios', style: DevTheme.display(size: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: DevColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: DevColors.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              '${_comments.length}',
              style: DevTheme.body(size: 10.5, color: DevColors.primary),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: DevColors.mutedFg),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String? myId, bool isMod) {
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
              const Icon(Icons.cloud_off_rounded,
                  size: 40, color: DevColors.mutedFg),
              const SizedBox(height: 10),
              Text('No se pudieron cargar los comentarios',
                  style: DevTheme.body(size: 13.5)),
              const SizedBox(height: 4),
              Text(_error!, textAlign: TextAlign.center,
                  style: DevTheme.bodySecondary(size: 11)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 40, color: DevColors.mutedFg),
              const SizedBox(height: 10),
              Text('Todavía no hay comentarios',
                  style: DevTheme.body(size: 13.5)),
              const SizedBox(height: 4),
              Text('Sé el primero en comentar',
                  style: DevTheme.bodySecondary(size: 11.5)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final comment = _comments[i];
        final author = comment.author;
        final canDelete = isMod || (myId != null && author?.id == myId);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              username: author?.username ?? 'dev',
              avatar: author?.avatar,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          author?.fullName?.isNotEmpty == true
                              ? author!.fullName!
                              : (author?.username ?? 'Usuario'),
                          style: DevTheme.body(size: 12, w: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '@${author?.username ?? 'usuario'} · ${timeAgo(comment.createdAt)}',
                          style: DevTheme.bodySecondary(size: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (canDelete) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () => _delete(comment),
                          borderRadius: BorderRadius.circular(99),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 15, color: DevColors.mutedFg),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: DevTheme.body(size: 12.5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: DevColors.cardRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DevColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  style: DevTheme.body(size: 13),
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario…',
                    hintStyle:
                        DevTheme.bodySecondary(size: 12.5, color: DevColors.mutedFg),
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              height: 42,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.primary,
                  disabledBackgroundColor: DevColors.muted,
                  foregroundColor: DevColors.primaryFg,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
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
      ),
    );
  }
}
