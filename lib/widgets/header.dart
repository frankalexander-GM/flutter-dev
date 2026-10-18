import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import 'avatar.dart';

/// Cabecera de DevPlay — logo, buscador, campana con badge real de no
/// leídas y avatar del usuario. El menú lateral hoy expone cerrar sesión.
class DevHeader extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onLogout;
  final int unreadCount;

  const DevHeader({
    super.key,
    this.onNotificationsTap,
    this.onLogout,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(
          bottom: BorderSide(color: DevColors.border, width: 3),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Menu lateral
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_rounded, size: 22),
            color: DevColors.card,
            onSelected: (value) {
              if (value == 'logout') onLogout?.call();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 18, color: DevColors.destructive),
                    const SizedBox(width: 10),
                    Text('Cerrar sesion',
                        style: DevTheme.body(size: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          // Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE08A52), Color(0xFFB8502A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: DevColors.gold35),
                ),
                child: const Icon(Icons.sports_esports_rounded,
                    size: 20, color: DevColors.cream),
              ),
              const SizedBox(width: 8),
              Text(
                'DevPlay',
                style: DevTheme.display(size: 20)
                    .copyWith(letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Buscador
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DevColors.cardRaised,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: DevColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded,
                      size: 18, color: DevColors.mutedFg),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscar juegos, devs, betas...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DevColors.mutedFg,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Campana con badge de no leidas
          InkWell(
            onTap: onNotificationsTap,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    size: 24, color: DevColors.foreground),
                if (unreadCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [DevColors.wine, Color(0xFFB85F3A)]),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: DevTheme.body(
                            size: 9, w: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar del usuario en sesion
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final username = auth.user?.username ?? 'devplayito';
              return UserAvatar(username: username, size: 34);
            },
          ),
        ],
      ),
    );
  }
}
