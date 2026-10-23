import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../theme.dart';
import 'avatar.dart';

/// Cabecera de DevPlay — PRD 1.1
///
/// - Logo DevPlay
/// - SearchBar: bg #2C231E, border #332722, hint #A0938C
/// - Campana notificaciones con badge (solo usuarios registrados)
/// - Botón "Iniciar sesión / Registrarse" (invitados) o Avatar usuario
/// - Menú hamburguesa (móvil) / opciones (desktop)
class DevHeader extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onLogout;
  final VoidCallback? onMenuTap;
  final ValueChanged<String>? onSearch;
  final int unreadCount;
  final bool showMenu;

  const DevHeader({
    super.key,
    this.onNotificationsTap,
    this.onLogout,
    this.onMenuTap,
    this.onSearch,
    this.unreadCount = 0,
    this.showMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: DevColors.surface,
        border: Border(bottom: BorderSide(color: DevColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menú lateral / Drawer
          if (showMenu)
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                size: 24,
                color: DevColors.foreground,
              ),
              onPressed: onMenuTap,
              tooltip: 'Menú',
            )
          else
            const SizedBox(width: 48),
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
                    colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: DevColors.gold35),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  size: 20,
                  color: DevColors.cream,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DevPlay',
                style: DevTheme.display(size: 20).copyWith(letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Buscador global amplio
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DevColors.cardRaised, // #2C231E
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DevColors.border), // #332722
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: DevColors.mutedFg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: DevTheme.body(
                        size: 13,
                        color: DevColors.foreground,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSearch,
                      decoration: InputDecoration(
                        hintText: 'Buscar proyectos, juegos o @usuarios…',
                        hintStyle: DevTheme.bodySecondary(
                          size: 13,
                          color: DevColors.mutedFg,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sección de autenticación / perfil
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user;
              final isGuest = user == null || user.isGuest;

              if (isGuest) {
                // Invitado: Ocultar notificaciones y mostrar botón claro de Iniciar sesión / Registrarse
                return ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Iniciar sesión / Registrarse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DevColors.accentOrange,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: DevColors.accentOrange.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: DevTheme.body(size: 12, w: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }

              // Usuario registrado normal: Notificaciones + Avatar
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onNotificationsTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 24,
                          color: DevColors.foreground,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [DevColors.wine, Color(0xFF3B82F6)],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: DevTheme.body(
                                  size: 9,
                                  w: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(
                    username: user.username,
                    avatar: user.avatar,
                    size: 34,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
