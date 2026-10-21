import 'package:flutter/material.dart';

import '../../models/trending_game.dart';
import '../../theme.dart';

/// Pantalla completa de **Juegos en tendencia** — accesible desde "Ver todo" en Descubrir.
class TrendingGamesScreen extends StatelessWidget {
  final List<TrendingGame> games;
  final void Function(String)? onGameTap;

  const TrendingGamesScreen({super.key, required this.games, this.onGameTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.card,
        elevation: 0,
        title: Text('Juegos en tendencia', style: DevTheme.display(size: 20)),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: DevColors.foreground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: games.isEmpty
          ? _buildEmpty()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${games.length} juegos en tendencia',
                      style: DevTheme.bodySecondary(size: 14),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _TrendingGameGridCard(
                        game: games[i],
                        onTap: () => onGameTap?.call(games[i].name),
                      ),
                      childCount: games.length,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DevColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videogame_asset_rounded,
                size: 36,
                color: DevColors.mutedFg,
              ),
            ),
            const SizedBox(height: 20),
            Text('Sin juegos en tendencia', style: DevTheme.display(size: 18)),
            const SizedBox(height: 8),
            Text(
              'Cuando haya datos de tendencia aparecerán aquí.',
              style: DevTheme.bodySecondary(size: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card para grid (2 columnas) en la pantalla completa
class _TrendingGameGridCard extends StatelessWidget {
  final TrendingGame game;
  final VoidCallback onTap;

  const _TrendingGameGridCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: DevTheme.trendingCard(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de portada
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      game.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: DevColors.muted,
                        child: Icon(
                          Icons.videogame_asset_rounded,
                          size: 32,
                          color: DevColors.mutedFg,
                        ),
                      ),
                    ),
                  ),
                ),
                // Badge TENDENCIA
                if (game.isTrending)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DevColors.destructive,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'TENDENCIA',
                            style: DevTheme.body(
                              size: 9,
                              w: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Info del juego
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: DevTheme.body(size: 14, w: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        game.version,
                        style: DevTheme.bodySecondary(size: 11),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.visibility_rounded,
                        size: 12,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 3),
                      Text(game.views, style: DevTheme.bodySecondary(size: 11)),
                    ],
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
