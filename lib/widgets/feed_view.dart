import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme.dart';
import 'animations.dart';
import 'console_screen.dart';
import 'glass_card.dart';
import 'post_card.dart';

enum FeedFilter { all, live, betas, posts }

/// Feed principal — FeedView mejorado: filtros en tarjeta vidrio,
/// pull-to-refresh y estado vacío con consola CRT.
class FeedView extends StatefulWidget {
  final List<Post> posts;
  final FeedFilter initialFilter;
  const FeedView(
      {super.key, required this.posts, this.initialFilter = FeedFilter.all});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late FeedFilter _filter = widget.initialFilter;

  @override
  void didUpdateWidget(covariant FeedView old) {
    super.didUpdateWidget(old);
    if (old.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
    }
  }

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

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Feed actualizado ✨ (demo local)')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: GlassCard(
            radius: 14,
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                for (final f in FeedFilter.values) ...[
                  if (f != FeedFilter.values.first)
                    const SizedBox(width: 2),
                  Expanded(
                      child: _FilterTab(
                          f: f,
                          active: _filter == f,
                          onTap: () =>
                              setState(() => _filter = f))),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: DevColors.gold,
            backgroundColor: DevColors.card,
            child: posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 150),
                    children: [_Empty(filter: _filter)],
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 150),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 14),
                    itemBuilder: (_, i) => StaggeredEntrance(
                      index: i,
                      child: i == 0
                          ? Sheen(child: PostCard(post: posts[i]))
                          : PostCard(post: posts[i]),
                    ),
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
  const _FilterTab(
      {required this.f, required this.active, required this.onTap});

  static const _meta = {
    FeedFilter.all: (Icons.auto_awesome_rounded, 'Todo'),
    FeedFilter.live: (Icons.radio_rounded, 'En vivo'),
    FeedFilter.betas: (Icons.sports_esports_rounded, 'Betas'),
    FeedFilter.posts: (Icons.article_outlined, 'Posts'),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _meta[f]!;
    final color = active ? Colors.white : DevColors.mutedFg;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 40,
        decoration: BoxDecoration(
          gradient: active ? DevTheme.btnGradient() : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: DevColors.gold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
              style: DevTheme.body(size: 12, w: FontWeight.w700, color: color),
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
              child: Icon(Icons.radio_rounded,
                  size: 44, color: DevColors.likedRed),
            ),
            const SizedBox(height: 12),
            Text('No hay directos ahora mismo',
                style: DevTheme.body(size: 16, w: FontWeight.w700)),
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
          Text('Aún no hay publicaciones',
              style: DevTheme.display(size: 18)),
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
