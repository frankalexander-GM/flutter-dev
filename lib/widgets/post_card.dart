import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'animations.dart';
import 'avatar.dart';
import 'console_screen.dart';

/// Tarjeta de publicación de DevPlay — calca la PostCard de la web:
/// cabecera con autor, contenido, media, sección de beta y barra de
/// acciones (like con confeti, comentarios, descargas, compartir).
class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked = widget.post.liked;
  late int _likes = widget.post.likesCount;
  bool _burst = false;
  int _burstTick = 0;
  bool _liking = false;

  /// `POST /posts/{id}/likes` → `{active, count}` (toggle real en la API).
  Future<void> _toggleLike() async {
    if (_liking) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likes = _likes + (wasLiked ? -1 : 1);
      if (!wasLiked) {
        _burstTick++;
        _burst = true;
      }
    });
    _liking = true;
    try {
      final result = await PostService.toggleLike(widget.post.id);
      if (!mounted) return;
      setState(() {
        _liked = result['active'] as bool? ?? _liked;
        _likes = result['count'] as int? ?? _likes;
      });
    } catch (_) {
      // Revierte el optimista si la API falló (p. ej. invitado).
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likes = widget.post.likesCount;
          _burst = false;
        });
      }
    } finally {
      _liking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return LayoutBuilder(
      builder: (context, cons) {
        // Origen del confeti: desde el corazón (barra de acciones).
        final origin = Offset(30, cons.maxHeight - 26);
        return Stack(
          children: [
            Container(
              decoration: DevTheme.glass(radius: 8),
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(post: post),
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        post.content,
                        style: DevTheme.body(size: 14, height: 1.4),
                      ),
                    ),
                  if (post.media.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _MediaGrid(media: post.media),
                  ],
                  if (post.type == PostType.beta && post.beta != null) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _BetaSection(beta: post.beta!),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _Actions(
                    liked: _liked,
                    likes: _likes,
                    comments: post.commentsCount,
                    downloads: post.beta?.downloads,
                    hasBeta: post.type == PostType.beta,
                    onLike: _toggleLike,
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
                  onDone: () => setState(() => _burst = false),
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
  const _Header({required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final username = author?.username ?? 'anónimo';
    final isDev = author?.role == 'DEV';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          UserAvatar(username: username, avatar: author?.avatar, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.body(size: 14, w: FontWeight.w600),
                      ),
                    ),
                    if (isDev) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: DevColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: DevColors.border),
                        ),
                        child: Text(
                          'DEV',
                          style: DevTheme.labelCaps(size: 8, color: DevColors.foreground),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(post.createdAt),
                  style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
          IconButton(
            // Solo visible cuando el autor es el usuario actual (en la maqueta se oculta)
            onPressed: null,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.more_horiz_rounded, size: 20, color: DevColors.mutedFg),
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
      height: one ? 200 : 150,
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
              ? const [Color(0xFF3C1F1F), Color(0xFF241610)]
              : const [Color(0xFF4A3520), Color(0xFF2E1F15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // cuadrícula pixel sutil (textura)
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(color: DevColors.white08),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                size: 40,
                color: DevColors.gold.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                isVideo ? 'video' : 'imagen',
                style: DevTheme.labelCaps(size: 10, color: DevColors.mutedFg),
              ),
            ],
          ),
          if (isVideo)
            Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DevColors.white15),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
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
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => color != old.color;
}

class _BetaSection extends StatelessWidget {
  final BetaInfo beta;
  const _BetaSection({required this.beta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DevColors.cardRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x33DC7A44), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DevColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_esports_rounded, size: 26, color: DevColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(beta.title, style: DevTheme.body(size: 14, w: FontWeight.w700)),
                if (beta.genre != null)
                  Text(
                    'Género: ${beta.genre}',
                    style: DevTheme.body(size: 11, color: DevColors.mutedFg),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: DevColors.gold25,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: DevColors.gold40),
            ),
            child: Text(
              beta.version ?? '',
              style: DevTheme.body(size: 11, w: FontWeight.w700, color: DevColors.goldSoft),
            ),
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
  final int? downloads;
  final bool hasBeta;
  final VoidCallback onLike;
  const _Actions({
    required this.liked,
    required this.likes,
    required this.comments,
    required this.downloads,
    required this.hasBeta,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: Row(
        children: [
          PopScale(
            trigger: likes,
            child: _ActionButton(
              icon: liked ? Icons.favorite : Icons.favorite_border,
              active: liked,
              activeColor: DevColors.likedRed,
              label: '$likes',
              onTap: onLike,
            ),
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            label: '$comments',
          ),
          if (hasBeta && downloads != null) ...[
            const SizedBox(width: 4),
            Expanded(
              child: _ActionButton(
                icon: Icons.download_rounded,
                label: compactNumber(downloads!),
              ),
            ),
          ] else
            const Spacer(),
          _ActionButton(
            icon: Icons.share_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado 🔗')),
              );
            },
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
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: DevTheme.body(size: 12, w: FontWeight.w600, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}