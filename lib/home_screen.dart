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
  FeedFilter _filter = FeedFilter.all;

  static const _nav = [
    (Icons.home_rounded, 'Inicio', FeedFilter.all),
    (Icons.explore_outlined, 'Explorar', FeedFilter.all),
    (Icons.auto_awesome_outlined, 'Descubrir', FeedFilter.live),
    (Icons.sports_esports_outlined, 'Betas', FeedFilter.betas),
    (Icons.person_outline_rounded, 'Perfil', FeedFilter.posts),
  ];

  void _onNav(int i) {
    setState(() {
      _navIndex = i;
      _filter = _nav[i].$3;
    });
    if (i == 4) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Perfil demo 👤 (pronto)')),
        );
    }
  }

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
            Expanded(
              child: FeedView(
                key: ValueKey(_filter),
                posts: mockPosts,
                initialFilter: _filter,
              ),
            ),
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
          top: BorderSide(color: DevColors.border, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _nav.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _onNav(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: i == _navIndex
                                ? DevColors.gold25
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(999),
                          ),
                          child: Icon(
                            _nav[i].$1,
                            size: 22,
                            color: i == _navIndex
                                ? DevColors.gold
                                : DevColors.mutedFg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nav[i].$2,
                          style: DevTheme.body(
                            size: 10,
                            w: i == _navIndex
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i == _navIndex
                                ? DevColors.gold
                                : DevColors.mutedFg,
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
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
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Crear contenido',
                style: DevTheme.display(size: 17),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const _Option(
              icon: Icons.sports_esports_rounded,
              iconColor: DevColors.amber,
              label: 'Subir Beta',
              desc: 'Comparte tu juego con la comunidad'),
          const _Option(
              icon: Icons.videocam_outlined,
              iconColor: DevColors.wine,
              label: 'Subir Video',
              desc: 'Gameplay, devlog o tráiler'),
          const _Option(
              icon: Icons.bar_chart_rounded,
              iconColor: DevColors.olive,
              label: 'Encuesta',
              desc: 'Pregunta a tus jugadores'),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (action != null && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$action — pronto 😉')));
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String desc;
  const _Option(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, label),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: DevTheme.body(
                          size: 14, w: FontWeight.w700)),
                  Text(desc,
                      style: DevTheme.body(
                          size: 11,
                          color: DevColors.mutedFg)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DevColors.mutedFg),
          ],
        ),
      ),
    );
  }
}
