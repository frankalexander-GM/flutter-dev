import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'avatar.dart';

/// Hoja de comentarios: lista + caja para comentar.
/// Devuelve la lista actualizada al cerrarse (para actualizar el contador).
class CommentsSheet extends StatefulWidget {
  final Post post;
  final List<PostComment> initial;
  const CommentsSheet({super.key, required this.post, required this.initial});

  static Future<List<PostComment>?> show(
    BuildContext context,
    Post post,
    List<PostComment> initial,
  ) {
    return showModalBottomSheet<List<PostComment>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CommentsSheet(post: post, initial: initial),
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late List<PostComment> _comments = List.of(widget.initial);
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments = [
        ..._comments,
        PostComment(
          username: 'devplayito',
          text: text,
          createdAt: DateTime.now(),
        ),
      ];
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Text('Comentarios', style: DevTheme.display(size: 17)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DevColors.gold25,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: DevColors.gold40),
                    ),
                    child: Text(
                      '${_comments.length}',
                      style: DevTheme.body(
                        size: 11,
                        w: FontWeight.w700,
                        color: DevColors.goldSoft,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context, _comments),
                    icon: const Icon(Icons.close_rounded,
                        color: DevColors.mutedFg, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mode_comment_outlined,
                              size: 40, color: DevColors.mutedFg),
                          const SizedBox(height: 8),
                          Text(
                            'Sé el primero en comentar 👀',
                            style: DevTheme.body(
                                size: 13, color: DevColors.mutedFg),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserAvatar(
                                username: c.username, size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: DevColors.cardRaised,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: DevColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.username,
                                          style: DevTheme.body(
                                              size: 12,
                                              w: FontWeight.w700),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          timeAgo(c.createdAt),
                                          style: DevTheme.body(
                                              size: 10,
                                              color: DevColors.mutedFg),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(c.text,
                                        style:
                                            DevTheme.body(size: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  const UserAvatar(username: 'devplayito', size: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      style: DevTheme.body(size: 13),
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        hintStyle: DevTheme.body(
                            size: 13, color: DevColors.mutedFg),
                        filled: true,
                        fillColor: DevColors.cardRaised,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                              color: DevColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                              color: DevColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                              color: DevColors.gold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: DevTheme.btnGradient(),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          size: 18, color: Colors.white),
                    ),
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
