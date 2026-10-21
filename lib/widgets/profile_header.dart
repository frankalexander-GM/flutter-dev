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

  /// Barra de pestañas opcional, ubicada junto a las acciones del perfil.
  final Widget? tabs;

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
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final bannerHeight = wide ? 205.0 : 160.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portada + avatar superpuesto.
        SizedBox(
          height: bannerHeight + 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _Banner(profile: profile, height: bannerHeight),
              ),
              Positioned(
                left: 16,
                bottom: 0,
                child: _AvatarWithRing(profile: profile, size: wide ? 94 : 84),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide && isOwn)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildIdentity()),
                    const SizedBox(width: 16),
                    _Actions(
                      profile: profile,
                      isOwn: isOwn,
                      followBusy: followBusy,
                      onFollow: onFollow,
                      onEdit: onEdit,
                      onShare: onShare,
                      inline: true,
                    ),
                  ],
                )
              else
                _buildIdentity(),
              if (profile.bio != null && profile.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    profile.bio!,
                    style: DevTheme.body(size: 14, height: 1.35),
                  ),
                ),
              const SizedBox(height: 12),
              _MetaRow(
                profile: profile,
                isOwn: isOwn,
                gamesCount: gamesCount,
                onFollowers: onFollowers,
                onFollowing: onFollowing,
                onPosts: onPosts,
                onGames: onGames,
              ),
              if (!(wide && isOwn)) ...[
                const SizedBox(height: 16),
                _Actions(
                  profile: profile,
                  isOwn: isOwn,
                  followBusy: followBusy,
                  onFollow: onFollow,
                  onEdit: onEdit,
                  onShare: onShare,
                ),
              ],
              if (tabs != null) ...[const SizedBox(height: 12), tabs!],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayName,
          style: DevTheme.display(size: 22, w: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              '@${profile.username}',
              style: DevTheme.bodySecondary(size: 13),
            ),
            if (_profession != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: DevColors.mutedFg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_profession!, style: DevTheme.bodySecondary(size: 12.5)),
                ],
              ),
          ],
        ),
        if (_badges.isNotEmpty || _interestTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._badges,
                for (final tag in _interestTags) _InterestChip(label: tag),
              ],
            ),
          ),
      ],
    );
  }

  String get _displayName {
    if (profile.fullName != null && profile.fullName!.isNotEmpty) {
      return profile.fullName!;
    }
    return profile.username;
  }

  String? get _profession {
    final p = profile.profession;
    if (p == null || p.trim().isEmpty) return null;
    return p.trim();
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
          color: DevColors.accentCyan,
        ),
      );
    }
    return badges;
  }

  /// Intereses visibles junto a las insignias (máximo 6 + contador).
  List<String> get _interestTags {
    final tags = (profile.tags ?? const <String>[])
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    const maxVisible = 6;
    if (tags.length <= maxVisible) return tags;
    return [...tags.take(maxVisible), '+${tags.length - maxVisible}'];
  }
}

/// Portada del perfil. Si no hay banner, muestra un degradado de marca.
class _Banner extends StatelessWidget {
  final ProfileUser profile;
  final double height;

  const _Banner({required this.profile, required this.height});

  @override
  Widget build(BuildContext context) {
    final banner = profile.banner;
    final hasBanner = banner != null && banner.isNotEmpty;

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A101D), Color(0xFF0F172A), Color(0xFF060B14)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBanner)
            Image.network(
              banner,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          else
            Positioned.fill(
              child: CustomPaint(painter: _BannerPatternPainter()),
            ),
          // Luz neón superior izquierda de la portada.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.9, -0.95),
                    radius: 0.85,
                    colors: [Color(0x2400F0FF), Color(0x0000F0FF)],
                  ),
                ),
              ),
            ),
          ),
          // Luz neón detrás del avatar (esquina inferior izquierda).
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.82, 0.9),
                    radius: 0.95,
                    colors: [
                      Color(0x2600F0FF),
                      Color(0x0D00F0FF),
                      Color(0x0000F0FF),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Viñeta inferior: da profundidad y asegura contraste con el avatar.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x66060B14)],
              ),
            ),
          ),
          const Positioned(
            right: 16,
            bottom: 12,
            child: Icon(
              Icons.sports_esports_rounded,
              size: 34,
              color: Color(0x2EE0F7FF),
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
      ..color = const Color(0x14E0F7FF)
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

/// Avatar con anillo de marca.
class _AvatarWithRing extends StatelessWidget {
  final ProfileUser profile;
  final double size;

  const _AvatarWithRing({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: DevColors.btnGradient(),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: DevColors.background,
        ),
        child: UserAvatar(
          username: profile.username,
          avatar: profile.avatar,
          size: size,
        ),
      ),
    );
  }
}

/// Ubicación, web, fecha de incorporación y contadores sociales.
class _MetaRow extends StatelessWidget {
  final ProfileUser profile;
  final bool isOwn;
  final int gamesCount;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onPosts;
  final VoidCallback onGames;

  const _MetaRow({
    required this.profile,
    required this.isOwn,
    required this.gamesCount,
    required this.onFollowers,
    required this.onFollowing,
    required this.onPosts,
    required this.onGames,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (profile.location != null && profile.location!.isNotEmpty) {
      items.add(
        _MetaChip(icon: Icons.location_on_outlined, label: profile.location!),
      );
    }
    if (profile.website != null && profile.website!.isNotEmpty) {
      items.add(
        _MetaChip(icon: Icons.link_rounded, label: _shortUrl(profile.website!)),
      );
    }
    items.add(
      _MetaChip(
        icon: Icons.calendar_today_rounded,
        label: _joinDate(profile.createdAt),
      ),
    );
    if (isOwn) {
      items.add(
        _MetaChip(
          icon: Icons.people_outline_rounded,
          label: '${compactNumber(profile.followersCount)} seguidores',
          onTap: onFollowers,
        ),
      );
      items.add(
        _MetaChip(
          icon: Icons.person_outline_rounded,
          label: '${compactNumber(profile.followingCount)} siguiendo',
          onTap: onFollowing,
        ),
      );
      if (gamesCount > 0) {
        items.add(
          _MetaChip(
            icon: Icons.sports_esports_outlined,
            label:
                '${compactNumber(gamesCount)} ${gamesCount == 1 ? 'juego' : 'juegos'}',
            onTap: onGames,
          ),
        );
      }
      if (profile.postsCount > 0) {
        items.add(
          _MetaChip(
            icon: Icons.article_outlined,
            label:
                '${compactNumber(profile.postsCount)} ${profile.postsCount == 1 ? 'post' : 'posts'}',
            onTap: onPosts,
          ),
        );
      }
    }

    return Wrap(spacing: 14, runSpacing: 6, children: items);
  }

  static String _shortUrl(String url) {
    final cleaned = url.replaceFirst(RegExp(r'^https?://'), '');
    return cleaned.length > 28 ? '${cleaned.substring(0, 28)}…' : cleaned;
  }

  static String _joinDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MetaChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Row(
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

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: content,
      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: DevTheme.body(size: 11, w: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

/// Chip compacto de interés mostrado junto a las insignias del perfil.
class _InterestChip extends StatelessWidget {
  final String label;

  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DevColors.accentCyan.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: DevColors.accentCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag_rounded,
            size: 11,
            color: DevColors.accentCyan.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: DevTheme.body(
              size: 11,
              w: FontWeight.w500,
              color: DevColors.mutedFg,
            ),
          ),
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
  final bool inline;

  const _Actions({
    required this.profile,
    required this.isOwn,
    required this.followBusy,
    required this.onFollow,
    required this.onEdit,
    required this.onShare,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwn) {
      return Row(
        mainAxisSize: inline ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _GradientButton(
            icon: Icons.edit_outlined,
            label: 'Editar perfil',
            onTap: onEdit,
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onShare,
            tooltip: 'Compartir perfil',
            icon: const Icon(Icons.ios_share_rounded, color: DevColors.mutedFg),
            style: IconButton.styleFrom(
              side: const BorderSide(color: DevColors.border),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
          Expanded(
            child: ElevatedButton.icon(
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón principal con el degradado de marca.
class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DevColors.cyanGradient(),
        borderRadius: BorderRadius.circular(8),
        boxShadow: DevColors.cyanGlow(alpha: 0.28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: DevTheme.body(
                    size: 13,
                    w: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
