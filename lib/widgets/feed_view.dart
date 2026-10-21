import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme.dart';
import 'animations.dart';
import 'console_screen.dart';
import 'post_card.dart';

/// Feed principal — PRD 1.1.D
///
/// - Lista de PostCard con StaggeredEntrance + Sheen en el primero
/// - Estado vacío con consola CRT
/// - **Sin filtros propios** (el filtro se maneja en DiscoverScreen)
class FeedView extends StatelessWidget {
  final List<Post> posts;
  const FeedView({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    final posts = this.posts;

    if (posts.isEmpty) {
      return const _Empty();
    }

    return ListView.separated(
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
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sin publicaciones', style: DevTheme.display(size: 18)),
            const SizedBox(height: 4),
            Text(
              'Sé el primero en compartir algo con la comunidad',
              textAlign: TextAlign.center,
              style: DevTheme.bodySecondary(size: 13),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}