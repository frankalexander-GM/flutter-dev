import 'package:flutter/material.dart';

import 'models/post.dart';
import 'theme.dart';
import 'widgets/feed_view.dart';
import 'widgets/header.dart';
import 'widgets/hero_banner.dart';
import 'widgets/hero_ticker.dart';

/// Pantalla principal: header + cinta de juegos + feed + barra inferior +
/// dock de crear (misma estructura que la web).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static const _nav = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.explore_outlined, 'Explorar'),
    (Icons.auto_awesome_outlined, 'Descubrir'),
    (Icons.sports_esports_outlined, 'Betas'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DevHeader(),
            // Hero pixel-art: mando retro, título, chips y cinta.
            // Margen para que respire entre el header y el ticker.
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: HeroBanner(
                onCreateTap: () => _openCreate(context),
                onGameTap: (name) =>
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name - pronto')),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            const HeroTicker(games: mockGames),
            Expanded(child: FeedView(posts: mockPosts)),
          ],
        ),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: DevColors.card,
        border: const Border(
          top: BorderSide(color: DevColors.border, width: 3),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < _nav.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _navIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _nav[i].$1,
                          size: 22,
                          color: i == _navIndex ? DevColors.gold : DevColors.mutedFg,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nav[i].$2,
                          style: DevTheme.body(
                            size: 10,
                            w: i == _navIndex ? FontWeight.w700 : FontWeight.w400,
                            color: i == _navIndex ? DevColors.gold : DevColors.mutedFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menú de creación (hoja inferior) — lo abre el botón Crear del hero.
Future<void> _openCreate(BuildContext context) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: DevColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: DevColors.muted,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Crear contenido', style: DevTheme.display(size: 16)),
            ),
          ),
          const _Option(icon: Icons.sports_esports_rounded, iconColor: DevColors.amber, label: 'Subir Beta'),
          const _Option(icon: Icons.videocam_outlined, iconColor: DevColors.wine, label: 'Subir Video'),
          const _Option(icon: Icons.bar_chart_rounded, iconColor: DevColors.olive, label: 'Encuesta'),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (action != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action - pronto')));
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _Option({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Text(label, style: DevTheme.body(size: 14)),
          ],
        ),
      ),
    );
  }
}