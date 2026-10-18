import 'package:flutter/material.dart';

import '../theme.dart';
import 'animations.dart';
import 'avatar.dart';

/// Cabecera de DevPlay — calca el Header de la web: menú, logo con
/// tipografía display, buscador, campana con badge y avatar.
class DevHeader extends StatelessWidget {
  const DevHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DevColors.card,
        border: const Border(
          bottom: BorderSide(color: DevColors.border, width: 3),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Menú
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Menú lateral próximo 🕹️')));
            },
            icon: const Icon(Icons.menu_rounded, size: 22),
            color: DevColors.foreground,
          ),
          const SizedBox(width: 2),
          // Logo
          Row(
            children: [
              Sheen(
                child: Container(
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
                  child: const Icon(Icons.sports_esports_rounded, size: 20, color: DevColors.cream),
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
              child: Row(
                children: const [
                  Icon(Icons.search_rounded, size: 18, color: DevColors.mutedFg),
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
          // Campana con badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 24, color: DevColors.foreground),
              Positioned(
                right: -8,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [DevColors.wine, Color(0xFFB85F3A)]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '9+',
                    style: DevTheme.body(size: 9, w: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Avatar
          const UserAvatar(username: 'devplayito', size: 34),
        ],
      ),
    );
  }
}