import 'package:flutter/material.dart';

import '../theme.dart';
import 'animations.dart';
import 'avatar.dart';

/// Cabecera de DevPlay — Header de la web mejorado:
/// buscador funcional, campana con panel de notificaciones y avatar.
class DevHeader extends StatelessWidget {
  const DevHeader({super.key});

  void _openNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Notificaciones',
                    style: DevTheme.display(size: 17)),
              ),
            ),
            for (final n in _fakeNotifs)
              ListTile(
                leading: UserAvatar(username: n.$1, size: 34),
                title: Text(n.$2, style: DevTheme.body(size: 13)),
                subtitle: Text(n.$3,
                    style: DevTheme.body(
                        size: 11, color: DevColors.mutedFg)),
                trailing: n.$4
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DevColors.gold,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DevColors.card,
        border: const Border(
          bottom: BorderSide(color: DevColors.border, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 14,
              offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Sheen(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE08A52), Color(0xFFB8502A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: DevColors.gold35),
                boxShadow: [
                  BoxShadow(
                    color: DevColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.sports_esports_rounded,
                  size: 20, color: DevColors.cream),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'DevPlay',
            style: DevTheme.display(size: 20)
                .copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(width: 12),
          // Buscador funcional
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                onSubmitted: (q) {
                  if (q.trim().isEmpty) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                        content: Text(
                            'Buscando "$q" 🔎 (demo local)')));
                },
                style: DevTheme.body(size: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar juegos, devs, betas...',
                  hintStyle: DevTheme.body(
                      size: 12, color: DevColors.mutedFg),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: DevColors.mutedFg),
                  filled: true,
                  fillColor: DevColors.cardRaised,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DevColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DevColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: DevColors.gold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Campana con badge
          InkWell(
            onTap: () => _openNotifications(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 24, color: DevColors.foreground),
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          DevColors.wine,
                          Color(0xFFB85F3A)
                        ]),
                        borderRadius:
                            BorderRadius.circular(999),
                        border: Border.all(
                            color: DevColors.card, width: 1.5),
                      ),
                      child: Text(
                        '3',
                        style: DevTheme.body(
                            size: 9,
                            w: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          const UserAvatar(username: 'devplayito', size: 34),
        ],
      ),
    );
  }
}

const _fakeNotifs = [
  (
    'luna_dev',
    'luna_dev le dio like a tu beta ❤️',
    'hace 5 min',
    true
  ),
  (
    'dev_pixel',
    'Nueva beta: Pixel Dash v0.4.2 🕹️',
    'hace 1 h',
    true
  ),
  (
    'raikoh',
    'raikoh está en vivo 🔴',
    'hace 2 h',
    false
  ),
];
