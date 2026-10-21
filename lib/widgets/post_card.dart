import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/post.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'avatar.dart';
import 'comments_sheet.dart';
import 'console_screen.dart';
import 'share_sheet.dart';

/// Tarjeta de publicación de DevPlay — PostCard de la web mejorada:
/// like con pop + confeti + doble-tap, comentarios reales (sheet),
/// compartir nativo + copiar enlace, guardar (bookmark) y sección beta.
class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late bool _liked = widget.post.liked;
  late int _likes = widget.post.likesCount;
  late bool _saved = widget.post.saved;
  late int _shares = widget.post.sharesCount;
  late int _commentsCount = widget.post.commentsCount;
  late List<PostComment> _comments = _seedComments(widget.post);
  bool _following = false;

  bool _burst = false;
  int _burstTick = 0;
  bool _bigHeart = false;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    lowerBound: 0.8,
    upperBound: 1.25,
  )..value = 1.0;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  static List<PostComment> _seedComments(Post post) {
    if (post.commentsCount == 0) return [];
    // Semilla visual para que el sheet no abra vacío.
    return [
      PostComment(
        username: 'luna_dev',
        text: '¡Buenísimo! Ya lo estoy probando 👀',
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      if (post.commentsCount > 1)
        PostComment(
          username: 'nick_og',
          text: 'Necesito la beta ya mismo 😅',
          createdAt:
              DateTime.now().subtract(const Duration(minutes: 18)),
        ),
    ];
  }

  void _toggleLike({bool fromDoubleTap = false}) {
    setState(() {
      if (_liked && !fromDoubleTap) {
        _liked = false;
        _likes = (_likes - 1).clamp(0, 9999999);
      } else if (!_liked) {
        _liked = true;
        _likes++;
        _burstTick++;
        _burst = true;
        _pop.forward(from: 0.8).then((_) {
          if (mounted) _pop.reverse();
        });
        HapticFeedback.lightImpact();
      } else if (fromDoubleTap) {
        // Ya con like: solo muestra el corazón grande.
        _pop.forward(from: 0.8).then((_) {
          if (mounted) _pop.reverse();
        });
      }
    });
  }

  void _doubleTapLike() {
    setState(() => _bigHeart = true);
    _toggleLike(fromDoubleTap: true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _bigHeart = false);
    });
  }

  Future<void> _openComments() async {
    final updated =
        await CommentsSheet.show(context, widget.post, _comments);
    if (updated != null && mounted) {
      setState(() {
        _comments = updated;
        _commentsCount = updated.length +
            (widget.post.commentsCount - _seedComments(widget.post).length)
                .clamp(0, 99999);
        if (_commentsCount < updated.length) {
          _commentsCount = updated.length;
        }
      });
    }
  }

  Future<void> _openShare() async {
    final shared = await ShareSheet.show(context, widget.post);
    if (shared == true && mounted) {
      setState(() => _shares++);
    }
  }

  void _toggleSave() {
    setState(() => _saved = !_saved);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            content: Text(_saved
                ? 'Guardado en tu colección 📌'
                : 'Eliminado de guardados')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return LayoutBuilder(
      builder: (context, cons) {
        final origin = Offset(30, cons.maxHeight - 26);
        return Stack(
          children: [
            Container(
              decoration: DevTheme.glass(radius: 16).copyWith(
                border: Border.all(
                  color: _liked
                      ? DevColors.likedRed.withValues(alpha: 0.35)
                      : DevColors.border,
                ),
              ),
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    post: post,
                    following: _following,
                    onFollow: () =>
                        setState(() => _following = !_following),
                  ),
                  if (post.content.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        post.content,
                        style: DevTheme.body(size: 14, height: 1.45),
                      ),
                    ),
                  if (post.type == PostType.stream) ...[
                    const SizedBox(height: 10),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16),
                      child: _LiveBadge(),
                    ),
                  ],
                  if (post.media.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onDoubleTap: _doubleTapLike,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _MediaGrid(media: post.media),
                              AnimatedOpacity(
                                opacity: _bigHeart ? 1 : 0,
                                duration: const Duration(
                                    milliseconds: 200),
                                child: AnimatedScale(
                                  scale: _bigHeart ? 1.15 : 0.6,
                                  duration: const Duration(
                                      milliseconds: 280),
                                  curve: Curves.elasticOut,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Doble-tap también sobre el texto para dar like.
                    GestureDetector(
                      onDoubleTap: _doubleTapLike,
                      behavior: HitTestBehavior.translucent,
                      child: const SizedBox(
                          width: double.infinity, height: 6),
                    ),
                  ],
                  if (post.type == PostType.beta &&
                      post.beta != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: _BetaSection(
                        beta: post.beta!,
                        onDownload: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Descargando ${post.beta!.title} ${post.beta!.version} 📥 (demo)'),
                              ),
                            );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _Actions(
                    liked: _liked,
                    likes: _likes,
                    comments: _commentsCount,
                    shares: _shares,
                    downloads: post.beta?.downloads,
                    hasBeta: post.type == PostType.beta,
                    saved: _saved,
                    onLike: () =>
                        _toggleLike(fromDoubleTap: false),
                    onComment: _openComments,
                    onShare: _openShare,
                    onSave: _toggleSave,
                    likePop: _pop,
                  ),
                ],
              ),
            ),
            if (_burst)
              Positioned.fill(
                child: ConfettiBurst(
                  key: ValueKey(_burstTick),
                  tick: _burstTick,
                  origin: origin,
                  onDone: () =>
                      setState(() => _burst = false),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Post post;
  final bool following;
  final VoidCallback onFollow;
  const _Header({
    required this.post,
    required this.following,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final isDev = post.author.role == 'DEV';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDev ? DevColors.gold : DevColors.border,
                width: 2,
              ),
            ),
            child: UserAvatar(
                username: post.author.username,
                avatar: post.author.avatar,
                size: 38),
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
                        post.author.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.body(
                            size: 14, w: FontWeight.w700),
                      ),
                    ),
                    if (isDev) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFE08A52),
                            Color(0xFFB8502A)
                          ]),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEV',
                          style: DevTheme.labelCaps(
                              size: 8, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(post.createdAt),
                  style: DevTheme.body(
                      size: 12, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
          if (!isDev)
            TextButton(
              onPressed: onFollow,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                backgroundColor: following
                    ? DevColors.white08
                    : DevColors.gold25,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(
                      color: DevColors.gold40),
                ),
              ),
              child: Text(
                following ? 'Siguiendo' : 'Seguir',
                style: DevTheme.body(
                  size: 11,
                  w: FontWeight.w700,
                  color: DevColors.goldSoft,
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Opciones del post (demo) ⋯')),
              );
            },
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.more_horiz_rounded,
                size: 20, color: DevColors.mutedFg),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DevColors.destructive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: DevColors.destructive
                .withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: DevColors.destructive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'EN VIVO · únete al stream',
            style: DevTheme.body(
                size: 11,
                w: FontWeight.w700,
                color: DevColors.destructive),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<PostMedia> media;
  const _MediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    final one = media.length == 1;
    return SizedBox(
      height: one ? 210 : 150,
      width: double.infinity,
      child: Row(
        children: [
          for (var i = 0; i < media.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _MediaPlaceholder(media: media[i])),
          ],
        ],
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final PostMedia media;
  const _MediaPlaceholder({required this.media});

  @override
  Widget build(BuildContext context) {
    final isVideo = media.kind == 'video';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVideo
              ? const [Color(0xFF4A2330), Color(0xFF241610)]
              : const [Color(0xFF5A4128), Color(0xFF2E1F15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(color: DevColors.white08),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideo
                    ? Icons.videocam_outlined
                    : Icons.image_outlined,
                size: 42,
                color:
                    DevColors.gold.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 8),
              Text(
                isVideo
                    ? 'video · doble-tap = ❤'
                    : 'imagen · doble-tap = ❤',
                style: DevTheme.labelCaps(
                    size: 9, color: DevColors.mutedFg),
              ),
            ],
          ),
          if (isVideo)
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color:
                    Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: DevColors.white15),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      color != old.color;
}

class _BetaSection extends StatelessWidget {
  final BetaInfo beta;
  final VoidCallback onDownload;
  const _BetaSection({required this.beta, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2617), Color(0xFF2E1F15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0x59DC7A44), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: DevTheme.btnGradient(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_esports_rounded,
                size: 26, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(beta.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DevTheme.body(
                              size: 14, w: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DevColors.gold25,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: DevColors.gold40),
                      ),
                      child: Text(
                        beta.version,
                        style: DevTheme.body(
                            size: 11,
                            w: FontWeight.w700,
                            color: DevColors.goldSoft),
                      ),
                    ),
                  ],
                ),
                if (beta.genre != null)
                  Text(
                    '${beta.genre} · ${compactNumber(beta.downloads)} descargas',
                    style: DevTheme.body(
                        size: 11,
                        color: DevColors.mutedFg),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.primary,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('Beta',
                style: DevTheme.body(
                    size: 12,
                    w: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool liked;
  final int likes;
  final int comments;
  final int shares;
  final int? downloads;
  final bool hasBeta;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final Animation<double> likePop;
  const _Actions({
    required this.liked,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.downloads,
    required this.hasBeta,
    required this.saved,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.likePop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: likePop,
            child: _ActionButton(
              icon: liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              active: liked,
              activeColor: DevColors.likedRed,
              label: compactNumber(likes),
              onTap: onLike,
            ),
          ),
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            label: compactNumber(comments),
            onTap: onComment,
          ),
          _ActionButton(
            icon: Icons.share_outlined,
            label: compactNumber(shares),
            onTap: onShare,
          ),
          if (hasBeta && downloads != null)
            Expanded(
              child: _ActionButton(
                icon: Icons.download_rounded,
                label: compactNumber(downloads!),
              ),
            )
          else
            const Spacer(),
          _ActionButton(
            icon: saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            active: saved,
            activeColor: DevColors.gold,
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.icon,
    this.label,
    this.active = false,
    this.activeColor = DevColors.likedRed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : DevColors.mutedFg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Icon(icon,
                  key: ValueKey('${icon.codePoint}_$active'),
                  size: 19,
                  color: color),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: DevTheme.body(
                    size: 12, w: FontWeight.w600, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
