import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'avatar.dart';

/// Encabezado del perfil: portada, avatar, identidad, insignias, acciones y
/// resumen de actividad. Se adapta a móvil y escritorio.
class ProfileHeader extends StatelessWidget {
  final ProfileUser profile;
  final bool isOwn;
  final bool followBusy;

  /// Número de juegos publicados (dato real de la API).
  final int gamesCount;

  final VoidCallback onFollow;
  final VoidCallback onEdit;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onPosts;
  final VoidCallback onGames;
  final VoidCallback onShare;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwn,
    required this.followBusy,
    required this.gamesCount,
    required this.onFollow,
    required this.onEdit,
    required this.onFollowers,
    required this.onFollowing,
    required this.onPosts,
    required this.onGames,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Banner(profile: profile),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -26),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AvatarWithRing(profile: profile),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.fullName != null &&
                                      profile.fullName!.isNotEmpty
                                  ? profile.fullName!
                                  : profile.username,
                              style: DevTheme.display(size: 20, w: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${profile.username}',
                              style: DevTheme.bodySecondary(size: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_badges.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _badges,
                        ),
                      ),
                    if (profile.bio != null && profile.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          profile.bio!,
                          style: DevTheme.body(size: 14),
                        ),
                      ),
                    _MetaRow(profile: profile),
                    const SizedBox(height: 14),
                    _Actions(
                      profile: profile,
                      isOwn: isOwn,
                      followBusy: followBusy,
                      onFollow: onFollow,
                      onEdit: onEdit,
                      onShare: onShare,
                    ),
                    const SizedBox(height: 16),
                    _ActivityRow(
                      profile: profile,
                      gamesCount: gamesCount,
                      onFollowers: onFollowers,
                      onFollowing: onFollowing,
                      onPosts: onPosts,
                      onGames: onGames,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> get _badges {
    final badges = <Widget>[];
    if (profile.role == 'ADMIN' || profile.role == 'DEV') {
      badges.add(
        _Badge(
          icon: Icons.verified_rounded,
          label: profile.role == 'ADMIN' ? 'Admin' : 'Dev',
          color: DevColors.gold,
        ),
      );
    }
    if (profile.isGuest) {
      badges.add(
        const _Badge(
          icon: Icons.person_outline_rounded,
          label: 'Invitado',
          color: DevColors.mutedFg,
        ),
      );
    }
    return badges;
  }
}

/// Portada del perfil. Si no hay banner, muestra un degradado de marca.
class _Banner extends StatelessWidget {
  final ProfileUser profile;
  const _Banner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final banner = profile.banner;
    return Container(
      width: double.infinity,
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A2E21), Color(0xFF2A1F1A), Color(0xFF1C1411)],
        ),
      ),
      child: banner != null && banner.isNotEmpty
          ? Image.network(
              banner,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          : Stack(
              children: [
                // Patrón de líneas diagonales muy sutil (identidad retro).
                Positioned.fill(
                  child: CustomPaint(painter: _BannerPatternPainter()),
                ),
                const Positioned(
                  right: 16,
                  bottom: 12,
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: 34,
                    color: Color(0x1FFBF3E4),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FBF3E4)
      ..strokeWidth = 1;
    const step = 14.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar con anillo de marca y presencia.
class _AvatarWithRing extends StatelessWidget {
  final ProfileUser profile;
  const _AvatarWithRing({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: DevColors.btnGradient(),
      ),
      child: UserAvatar(
        username: profile.username,
        avatar: profile.avatar,
        size: 78,
      ),
    );
  }
}

/// Ubicación, web y fecha de incorporación.
class _MetaRow extends StatelessWidget {
  final ProfileUser profile;
  const _MetaRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (profile.location != null && profile.location!.isNotEmpty) {
      items.add(_MetaChip(
        icon: Icons.location_on_outlined,
        label: profile.location!,
      ));
    }
    if (profile.website != null && profile.website!.isNotEmpty) {
      items.add(_MetaChip(
        icon: Icons.link_rounded,
        label: _shortUrl(profile.website!),
      ));
    }
    items.add(
      _MetaChip(
        icon: Icons.calendar_today_rounded,
        label: _joinDate(profile.createdAt),
      ),
    );

    return Wrap(spacing: 14, runSpacing: 6, children: items);
  }

  static String _shortUrl(String url) {
    final cleaned = url.replaceFirst(RegExp(r'^https?://'), '');
    return cleaned.length > 28 ? '${cleaned.substring(0, 28)}…' : cleaned;
  }

  static String _joinDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DevColors.mutedFg),
        const SizedBox(width: 4),
        Text(
          label,
          style: DevTheme.bodySecondary(size: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Botón de insignia (rol, verificado, invitado).
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: DevTheme.body(size: 11, color: color)),
        ],
      ),
    );
  }
}

/// Acciones del encabezado: seguir / editar / compartir.
class _Actions extends StatelessWidget {
  final ProfileUser profile;
  final bool isOwn;
  final bool followBusy;
  final VoidCallback onFollow;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const _Actions({
    required this.profile,
    required this.isOwn,
    required this.followBusy,
    required this.onFollow,
    required this.onEdit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwn) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DevColors.foreground,
                side: const BorderSide(color: DevColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (profile.isFollowing)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: followBusy ? null : onFollow,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Siguiendo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DevColors.foreground,
                side: const BorderSide(color: DevColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: followBusy ? null : onFollow,
            icon: followBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Seguir'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onShare,
          tooltip: 'Compartir perfil',
          icon: const Icon(Icons.ios_share_rounded, color: DevColors.mutedFg),
          style: IconButton.styleFrom(
            side: const BorderSide(color: DevColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Resumen de actividad: seguidores, seguidos, juegos y publicaciones.
class _ActivityRow extends StatelessWidget {
  final ProfileUser profile;

  /// Número de juegos publicados (posts de tipo showcase). Viene de la API.
  final int gamesCount;

  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onPosts;
  final VoidCallback onGames;

  const _ActivityRow({
    required this.profile,
    required this.gamesCount,
    required this.onFollowers,
    required this.onFollowing,
    required this.onPosts,
    required this.onGames,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActivityItem(
            label: 'Seguidores',
            value: profile.followersCount,
            onTap: onFollowers,
          ),
        ),
        Expanded(
          child: _ActivityItem(
            label: 'Siguiendo',
            value: profile.followingCount,
            onTap: onFollowing,
          ),
        ),
        Expanded(
          child: _ActivityItem(
            label: 'Juegos',
            value: gamesCount,
            onTap: onGames,
          ),
        ),
        Expanded(
          child: _ActivityItem(
            label: 'Publicaciones',
            value: profile.postsCount,
            onTap: onPosts,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              compactNumber(value),
              style: DevTheme.display(size: 17, w: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: DevTheme.labelCaps(size: 10)),
          ],
        ),
      ),
    );
  }
}
