import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Tarjeta de un juego publicado por el usuario.
///
/// La publicación es de tipo `GAME_SHOWCASE`. Si el post trae adjunto de
/// juego, se usan su portada y sus metadatos; si no, se usan los de la
/// publicación (todo dato viene de la API real).
class GameCard extends StatelessWidget {
  final Post post;

  const GameCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final game = post.game;
    final title = game?.title ?? post.title;
    final cover = game?.coverUrl ??
        (post.media.isNotEmpty ? post.media.first.url : null);
    final status = game?.status;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cover != null && cover.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                cover,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: DevColors.cardRaised,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    color: DevColors.mutedFg,
                    size: 32,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: DevTheme.body(size: 15, w: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (status != null && status.isNotEmpty)
                      _StatusPill(status: status),
                  ],
                ),
                if (game?.genre != null && game!.genre!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    game.genre!,
                    style: DevTheme.bodySecondary(size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (post.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    style: DevTheme.bodySecondary(size: 12.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (game?.version != null && game!.version!.isNotEmpty)
                      _Meta(
                        icon: Icons.tag_rounded,
                        label: game.version!,
                      ),
                    if (game?.platform != null && game!.platform!.isNotEmpty)
                      _Meta(
                        icon: Icons.computer_rounded,
                        label: game.platform!,
                      ),
                    _Meta(
                      icon: Icons.visibility_rounded,
                      label: '${compactNumber(post.viewsCount)} vistas',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Distintivo de estado del juego (en desarrollo, beta, publicado…).
class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'released' || 'published' => DevColors.consoleGreen,
      'beta' => DevColors.primary,
      'alpha' => DevColors.amber,
      'prototype' => DevColors.gold,
      _ => DevColors.mutedFg,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: DevTheme.labelCaps(size: 9, color: color),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: DevColors.mutedFg),
        const SizedBox(width: 4),
        Text(label, style: DevTheme.bodySecondary(size: 11.5)),
      ],
    );
  }
}

/// Tile de la galería de multimedia. Los videos se marcan con un icono.
class MediaTile extends StatelessWidget {
  final ProfileMedia media;
  final VoidCallback onTap;

  const MediaTile({super.key, required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DevColors.cardRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DevColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              media.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: DevColors.mutedFg,
                  size: 24,
                ),
              ),
            ),
            if (media.isVideo)
              const Center(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0x991C1411),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: DevColors.cream,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bloque con título para la pestaña "Acerca de".
class AboutBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const AboutBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DevColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DevColors.primary),
              const SizedBox(width: 8),
              Text(title, style: DevTheme.display(size: 14)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Enlace externo de la pestaña "Acerca de".
class ExternalLink extends StatelessWidget {
  final String url;

  const ExternalLink({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Text(
      url,
      style: DevTheme.body(size: 13, color: DevColors.primary),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Tarjeta de estadísticas del creador (datos reales de `/users/me/stats`).
class CreatorStatsCard extends StatelessWidget {
  final UserStats stats;

  const CreatorStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final max = stats.activityByDay.isEmpty
        ? 1
        : stats.activityByDay
            .map((d) => d.count)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DevColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 16,
                color: DevColors.gold,
              ),
              const SizedBox(width: 8),
              Text('Estadísticas', style: DevTheme.display(size: 14)),
              const Spacer(),
              Text(
                'Nivel ${stats.level}',
                style: DevTheme.bodySecondary(size: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Vistas de posts',
                  value: stats.totalDownloads,
                ),
              ),
              Expanded(
                child: _StatBox(
                  label: 'Me gusta recibidos',
                  value: stats.totalLikesReceived,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Comentarios',
                  value: stats.totalCommentsReceived,
                ),
              ),
              Expanded(
                child: _StatBox(
                  label: 'Descargas de betas',
                  value: stats.totalDownloads,
                ),
              ),
            ],
          ),
          if (stats.activityByDay.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Actividad (7 días)', style: DevTheme.labelCaps(size: 10)),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: stats.activityByDay
                    .map(
                      (day) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: (day.count / max) * 44,
                                constraints: const BoxConstraints(
                                  minHeight: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: DevColors.primary.withValues(
                                    alpha: 0.75,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day.date.length >= 10
                                    ? day.date.substring(8, 10)
                                    : day.date,
                                style: DevTheme.bodySecondary(size: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: DevColors.cardRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compactNumber(value),
            style: DevTheme.display(size: 17, w: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: DevTheme.bodySecondary(size: 10.5),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
