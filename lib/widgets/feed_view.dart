import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme.dart';
import 'animations.dart';
import 'console_screen.dart';
import 'glass_card.dart';
import 'post_card.dart';

enum FeedFilter { all, live, betas, posts }

/// Feed principal — calca el FeedView de la web: fichas de filtro en tarjeta
/// vidrio, lista de tarjetas y estado vacío con consola CRT.
class FeedView extends StatefulWidget {
  final List<Post> posts;
  const FeedView({super.key, required this.posts});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  FeedFilter _filter = FeedFilter.all;

  List<Post> get _filtered {
    switch (_filter) {
      case FeedFilter.all:
        return widget.posts;
      case FeedFilter.live:
        return widget.posts.where((p) => p.type == PostType.stream).toList();
      case FeedFilter.betas:
        return widget.posts.where((p) => p.type == PostType.beta).toList();
      case FeedFilter.posts:
        return widget.posts.where((p) => p.type == PostType.post).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GlassCard(
            radius: 8,
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (final f in FeedFilter.values) ...[
                  if (f != FeedFilter.values.first) const SizedBox(width: 2),
                  Expanded(child: _FilterTab(f: f, active: _filter == f, onTap: () => setState(() => _filter = f))),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: posts.isEmpty
              ? _Empty(filter: _filter)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 150),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => StaggeredEntrance(
                    index: i,
                    child: i == 0
                        ? Sheen(child: PostCard(post: posts[i]))
                        : PostCard(post: posts[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final FeedFilter f;
  final bool active;
  final VoidCallback onTap;
  const _FilterTab({required this.f, required this.active, required this.onTap});

  static const _meta = {
    FeedFilter.all: (Icons.auto_awesome_rounded, 'Todo'),
    FeedFilter.live: (Icons.radio_rounded, 'En vivo'),
    FeedFilter.betas: (Icons.sports_esports_rounded, 'Betas'),
    FeedFilter.posts: (Icons.article_outlined, 'Posts'),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _meta[f]!;
    final color = active ? DevColors.primaryFg : DevColors.mutedFg;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 38,
        decoration: BoxDecoration(
          gradient: active ? DevTheme.btnGradient() : null,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: DevColors.gold.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: DevTheme.body(size: 12, w: FontWeight.w600, color: color),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final FeedFilter filter;
  const _Empty({required this.filter});

  @override
  Widget build(BuildContext context) {
    if (filter == FeedFilter.live) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const LivePulse(
              child: Icon(Icons.radio_rounded, size: 44, color: DevColors.likedRed),
            ),
            const SizedBox(height: 12),
            Text('No hay directos ahora mismo', style: DevTheme.body(size: 16, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Sigue a tus devs favoritos para recibir notificaciones cuando estén en vivo',
              textAlign: TextAlign.center,
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
            ),
          ],
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Text('Aún no hay publicaciones', style: DevTheme.display(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Sé el primero en compartir algo con la comunidad',
            textAlign: TextAlign.center,
            style: DevTheme.body(size: 13, color: DevColors.mutedFg),
          ),
          const ConsoleScreen(
            lines: [
              r'$ devplay feed',
              r'$ 0 posts',
              r'$ esperando a alguien que publique...',
              r'$ _',
            ],
          ),
        ],
      ),
    );
  }
}