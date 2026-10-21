import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../theme.dart';
import '../utils/dev_link.dart';
import '../utils/format.dart';
import 'avatar.dart';
import 'comments_sheet.dart';
import 'post_poll.dart';
import 'report_dialog.dart';

/// Tarjeta de publicación de DevPlay.
///
/// Reutilizable en Inicio, Descubrir y Perfil. Las interacciones (like,
/// comentar, repost y encuestas) se envían a la API real. Compartir copia la
/// publicación al portapapeles: el backend no tiene endpoint de shares.
class PostCard extends StatefulWidget {
  final Post post;
  final bool compact;
  final VoidCallback? onProfileTap;
  final void Function(String)? onGameTap;

  /// Se dispara cuando el visitante repostea la publicación, para que el
  /// resto de la app pueda refrescar el feed.
  final VoidCallback? onReposted;

  /// Muestra el botón de guardar (colección privada del visitante).
  ///
  /// El feed general lo deja oculto (el perfil sí lo muestra, según su PRD).
  final bool showSave;

  const PostCard({
    super.key,
    required this.post,
    this.compact = false,
    this.onProfileTap,
    this.onGameTap,
    this.onReposted,
    this.showSave = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool _liked = widget.post.liked;
  late int _likes = widget.post.likesCount;
  late int _comments = widget.post.commentsCount;

  /// Estado del repost: evita dobles envíos.
  bool _reposting = false;
  bool _reposted = false;

  /// Estado de "guardado" (colección privada del visitante).
  late bool _bookmarked = widget.post.bookmarked;
  bool _saving = false;

  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _likeScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _liked = widget.post.liked;
      _likes = widget.post.likesCount;
      _comments = widget.post.commentsCount;
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}m';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'ahora';
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked;
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    if (_liked) _likeController.forward(from: 0.0);
    try {
      final res = await PostService.toggleLike(widget.post.id);
      if (!mounted) return;
      setState(() {
        _liked = res['active'] as bool? ?? _liked;
        _likes = res['count'] as int? ?? _likes;
      });
    } catch (_) {
      if (!mounted) return;
      // Revertir si el backend rechaza (p. ej. sin sesión).
      setState(() {
        _liked = wasLiked;
        _likes += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _share() async {
    final username = widget.post.author?.username ?? 'DevPlay';
    final content = widget.post.content.trim();
    final link = DevLink.profileUrl(username);
    final text = content.isEmpty
        ? 'Mira esta publicación de @$username en DevPlay\n$link'
        : '$content\n\n— @$username en DevPlay\n$link';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publicación copiada al portapapeles')),
    );
  }

  /// Guarda o quita la publicación de la colección privada del visitante
  /// (`POST /posts/{id}/bookmarks`).
  Future<void> _toggleSave() async {
    if (_saving) return;
    _saving = true;
    final wasSaved = _bookmarked;
    setState(() => _bookmarked = !_bookmarked);
    try {
      final res = await PostService.toggleBookmark(widget.post.id);
      if (!mounted) return;
      setState(() => _bookmarked = res['active'] as bool? ?? _bookmarked);
    } catch (e) {
      if (!mounted) return;
      setState(() => _bookmarked = wasSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
          backgroundColor: DevColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Repostea la publicación (`POST /posts/{id}/repost`).
  Future<void> _repost() async {
    if (_reposting) return;
    setState(() => _reposting = true);
    try {
      await PostService.repost(widget.post.id);
      if (!mounted) return;
      setState(() => _reposted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repost publicado en tu perfil'),
          backgroundColor: DevColors.consoleGreen,
        ),
      );
      widget.onReposted?.call();
    } catch (e) {
      if (!mounted) return;
      final already = e.toString().contains('409');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            already
                ? 'Ya habías reposteado esta publicación'
                : 'No se pudo repostear: $e',
          ),
          backgroundColor: already ? DevColors.muted : DevColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _reposting = false);
    }
  }

  void _openComments() {
    showCommentsSheet(
      context,
      post: widget.post,
      onCountChanged: (count) {
        if (!mounted) return;
        setState(() => _comments = count);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final compact = widget.compact;
    final author = post.author;
    final username = author?.username ?? 'devplayito';

    // Cover: media propia o portada del juego adjunto.
    final cover = post.media.isNotEmpty && post.media.first.url.isNotEmpty
        ? post.media.first.url
        : post.game?.coverUrl;

    return Container(
      decoration: BoxDecoration(
        color: compact ? DevColors.cardRaised : DevColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Atribución: si es un repost, se muestra de quién es el original.
          if (post.originalPost != null) _buildRepostAttribution(),
          if (cover != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                cover,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: DevColors.muted,
                  child: Icon(
                    Icons.image_rounded,
                    color: DevColors.mutedFg,
                    size: compact ? 28 : 36,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(username, author),
                const SizedBox(height: 10),
                if (post.title.isNotEmpty)
                  Text(
                    post.title,
                    style: DevTheme.body(
                      size: compact ? 13 : 15,
                      w: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (post.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    post.content,
                    style: DevTheme.bodySecondary(size: compact ? 11 : 12.5),
                    maxLines: compact ? 2 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.tags
                        .take(4)
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: DevColors.muted,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: DevColors.border),
                              ),
                              child: Text(
                                '#$tag',
                                style: DevTheme.body(
                                  size: 10,
                                  color: DevColors.mutedFg,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (post.type == PostType.poll) ...[
                  const SizedBox(height: 10),
                  PostPollView(postId: post.id, initialPoll: post.poll),
                ],
                const SizedBox(height: 12),
                const Divider(color: DevColors.border, height: 1),
                const SizedBox(height: 8),
                _buildActions(compact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cabecera de un repost: "X ha republicado esto" con acceso al original.
  Widget _buildRepostAttribution() {
    final original = widget.post.originalPost!;
    final author = original.author;
    final username = author?.username ?? 'desconocido';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 10 : 14,
        widget.compact ? 8 : 12,
        14,
        0,
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded, size: 15, color: DevColors.consoleGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Republicado de @$username',
              style: DevTheme.bodySecondary(size: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String username, PostAuthor? author) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onProfileTap,
          child: UserAvatar(username: username, avatar: author?.avatar, size: 36),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: widget.onProfileTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author?.fullName?.isNotEmpty == true
                      ? author!.fullName!
                      : username,
                  style: DevTheme.body(size: 13, w: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@$username · ${_timeAgo(widget.post.createdAt)}',
                  style: DevTheme.bodySecondary(size: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _TypeBadge(type: widget.post.type),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.more_vert_rounded, color: DevColors.mutedFg),
          onSelected: (value) {
            if (value == 'report') {
              showReportDialog(
                context,
                entityId: widget.post.id,
                entityType: 'POST',
                entityLabel: widget.post.content,
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'report',
              child: Text('Reportar publicación'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(bool compact) {
    return Row(
      children: [
        _ActionButton(
          icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _liked ? DevColors.likedRed : DevColors.mutedFg,
          label: compactNumber(_likes),
          onTap: _toggleLike,
          animated: _liked,
          scale: _likeScale,
        ),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: compactNumber(_comments),
          onTap: _openComments,
        ),
        _ActionButton(
          icon: _reposted
              ? Icons.repeat_rounded
              : Icons.repeat_on_rounded,
          color: _reposted ? DevColors.consoleGreen : DevColors.mutedFg,
          onTap: _reposting || _reposted ? null : _repost,
        ),
        _ActionButton(
          icon: Icons.ios_share_rounded,
          onTap: _share,
        ),
        if (widget.showSave) ...[
          const Spacer(),
          _ActionButton(
            icon: _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _bookmarked ? DevColors.gold : DevColors.mutedFg,
            onTap: _saving ? null : _toggleSave,
          ),
        ],
      ],
    );
  }
}

/// Botón de acción con icono y contador opcional.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;
  final bool animated;
  final Animation<double>? scale;

  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
    this.animated = false,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, size: 18, color: color ?? DevColors.mutedFg);
    if (animated && scale != null) {
      iconWidget = ScaleTransition(scale: scale!, child: iconWidget);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label!,
                style: DevTheme.bodySecondary(size: 11, color: color ?? DevColors.mutedFg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge que indica el tipo de publicación.
class _TypeBadge extends StatelessWidget {
  final PostType type;

  const _TypeBadge({required this.type});

  static const _icons = {
    PostType.game_showcase: Icons.sports_esports_rounded,
    PostType.beta: Icons.science_rounded,
    PostType.dev_log: Icons.code_rounded,
    PostType.update: Icons.update_rounded,
    PostType.stream: Icons.videocam_rounded,
    PostType.poll: Icons.quiz_rounded,
    PostType.announcement: Icons.campaign_rounded,
    PostType.post: Icons.article_rounded,
  };

  static const _labels = {
    PostType.game_showcase: 'Juego',
    PostType.beta: 'Beta',
    PostType.dev_log: 'DevLog',
    PostType.update: 'Update',
    PostType.stream: 'Stream',
    PostType.poll: 'Encuesta',
    PostType.announcement: 'Anuncio',
    PostType.post: 'Post',
  };

  @override
  Widget build(BuildContext context) {
    final color = type == PostType.dev_log || type == PostType.update
        ? DevColors.gold
        : DevColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[type] ?? Icons.article_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _labels[type] ?? 'Post',
            style: DevTheme.labelCaps(size: 8, color: color),
          ),
        ],
      ),
    );
  }
}
