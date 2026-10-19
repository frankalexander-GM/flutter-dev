import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/post.dart';
import '../../models/trending_game.dart';
import '../../services/post_service.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import 'trending_games_screen.dart';
import '../../widgets/animations.dart';
import '../../widgets/post_card.dart';

/// Pantalla **Descubrir** — Rediseño completo PRD con **scroll único**.
///
/// Estructura (todo en un CustomScrollView):
/// 1. **Juego destacado** (Hero grande con portada, descripción, botones)
/// 2. **Feed de publicaciones** (SliverList integrado en el scroll principal)
/// 3. **Juegos en tendencia** (carrusel horizontal)
/// 4. **En desarrollo** (diarios de dev, prototipos, demos)
/// 5. **Laboratorio de betas** (juegos buscando testers)
class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onCreateTap;
  final void Function(String)? onGameTap;

  const DiscoverScreen({
    super.key,
    this.onCreateTap,
    this.onGameTap,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // Feed principal
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  // Trending games
  List<TrendingGame> _trendingGames = [];
  bool _trendingLoading = true;

  // Juegos en desarrollo (dev logs, prototipos)
  List<Post> _devGames = [];
  bool _devLoading = true;

  // Betas disponibles
  List<Post> _betaGames = [];
  bool _betaLoading = true;

  // Filtro activo
  DiscoverFilter _activeFilter = DiscoverFilter.todo;

  // Juego destacado (hero)
  Post? _featuredGame;

  // Estado de solicitud de beta (evita dobles envíos)
  bool _joiningBeta = false;

  // Keys para navegación suave
  final _feedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadFeaturedGame(),
      _loadTrendingGames(),
      _loadDevGames(),
      _loadBetaGames(),
      _loadPosts(),
    ]);
  }

  // ---------------------------------------------------------
  // 1. Juego Destacado (usando endpoint real GAME_SHOWCASE)
  // ---------------------------------------------------------
  Future<void> _loadFeaturedGame() async {
    try {
      final posts = await PostService.getPosts(
        type: 'GAME_SHOWCASE',
        sort: 'latest',
        limit: 1,
      );
      if (posts.isNotEmpty) {
        setState(() => _featuredGame = posts.first);
      } else {
        // Fallback a un juego de ejemplo si el backend aún no tiene posts showcase
        setState(() => _featuredGame = _mockFeaturedGame());
      }
    } catch (_) {
      // Si falla el backend, usar mock para no romper la UI
      setState(() => _featuredGame = _mockFeaturedGame());
    }
  }

  // ---------------------------------------------------------
  // 2. Juegos en Tendencia (usando posts con sort: trending)
  // ---------------------------------------------------------
  Future<void> _loadTrendingGames() async {
    setState(() => _trendingLoading = true);
    try {
      // Usamos el servicio de posts con sort=trending.
      // El endpoint dedicado /discover/trending aún no existe en backend,
      // así que traemos los posts más populares y los mostramos como "trending".
      final posts = await PostService.getPosts(
        sort: 'trending',
        limit: 8,
      );
      // Ordenar por likes (más populares primero) y mapear a TrendingGame.
      final sorted = [...posts]..sort((a, b) => b.likesCount.compareTo(a.likesCount));
      setState(() {
        _trendingGames = sorted.map((p) {
          final cover = p.game?.coverUrl ??
              (p.media.isNotEmpty ? p.media.first.url : null);
          final label = p.game?.title ??
              (p.content.isNotEmpty
                  ? (p.content.length > 30
                      ? '${p.content.substring(0, 30)}...'
                      : p.content)
                  : 'Publicación');
          return TrendingGame(
            id: p.id,
            name: label,
            version: p.game?.version ?? 'v1.0.0',
            views: compactNumber(p.likesCount),
            isTrending: true,
            imageUrl: cover ?? 'https://picsum.photos/400/225?random=${p.id.hashCode}',
            gradient: const LinearGradient(colors: [Color(0xFFC66E41), Color(0xFFB05A35)]),
          );
        }).toList();
        _trendingLoading = false;
      });
    } catch (_) {
      // Fallback a mock si el servicio falla
      setState(() {
        _trendingGames = _mockTrendingGames();
        _trendingLoading = false;
      });
    }
  }

  Future<void> _loadDevGames() async {
    setState(() => _devLoading = true);
    try {
      final posts = await PostService.getPosts(type: 'DEV_LOG', sort: 'latest', limit: 6);
      setState(() {
        _devGames = posts;
        _devLoading = false;
      });
    } catch (_) {
      setState(() {
        _devGames = _mockDevGames();
        _devLoading = false;
      });
    }
  }

  Future<void> _loadBetaGames() async {
    setState(() => _betaLoading = true);
    try {
      final posts = await PostService.getPosts(type: 'BETA', sort: 'latest', limit: 6);
      setState(() {
        _betaGames = posts;
        _betaLoading = false;
      });
    } catch (_) {
      setState(() {
        _betaGames = _mockBetaGames();
        _betaLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? type;
      String? sort;
      switch (_activeFilter) {
        case DiscoverFilter.todo:
          sort = 'trending';
          break;
        case DiscoverFilter.betas:
          type = 'BETA';
          sort = 'latest';
          break;
        case DiscoverFilter.posts:
          type = 'POST';
          sort = 'latest';
          break;
      }

      final posts = await PostService.getPosts(type: type, sort: sort, limit: 50);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(DiscoverFilter filter) {
    if (filter != _activeFilter) {
      setState(() => _activeFilter = filter);
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. JUEGO DESTACADO (Hero)
            if (_featuredGame != null)
              SliverToBoxAdapter(child: _FeaturedGameHero(
                game: _featuredGame!,
                onDetailTap: widget.onGameTap,
                onPlayTap: () => _openGame(_featuredGame!),
                onBetaTap: () => _openBeta(_featuredGame!),
              )),

            // 2. FEED DE PUBLICACIONES (integrado en el scroll principal)
            SliverToBoxAdapter(child: _buildFeedSection()),

            // 3. JUEGOS EN TENDENCIA
            if (_trendingGames.isNotEmpty)
              SliverToBoxAdapter(child: _buildTrendingSection()),

            // 4. EN DESARROLLO
            if (_devGames.isNotEmpty)
              SliverToBoxAdapter(child: _buildDevSection()),

            // 5. LABORATORIO DE BETAS
            if (_betaGames.isNotEmpty)
              SliverToBoxAdapter(child: _buildBetaLabSection()),

            // Espacio final
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  // ===== SECCIÓN: FEED DE PUBLICACIONES (SLIVER LIST INTEGRADO) =====
  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con filtros
        Container(
          color: DevColors.card,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Feed', style: DevTheme.display(size: 22)),
                  const SizedBox(width: 12),
                  _buildFilterPills(),
                ],
              ),
            ],
          ),
        ),

        // Feed integrado en el scroll principal usando SliverList
        _isLoading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: DevColors.primary)),
              )
            : _error != null
                ? SliverFillRemaining(
                    child: _ErrorView(message: _error!, onRetry: _loadPosts),
                  )
                : _posts.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(
                          icon: Icons.article_outlined,
                          title: 'Sin publicaciones',
                          description: 'Sé el primero en compartir algo.',
                          actionLabel: 'Crear publicación',
                          onAction: widget.onCreateTap,
                        ),
                      )
                    : SliverList.separated(
                        key: _feedKey,
                        itemCount: _posts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: i == 0
                              ? Sheen(child: PostCard(
                                  post: _posts[i],
                                  onCommentTap: widget.onCreateTap,
                                  onGameTap: widget.onGameTap,
                                ))
                              : PostCard(
                                  post: _posts[i],
                                  onCommentTap: widget.onCreateTap,
                                  onGameTap: widget.onGameTap,
                                ),
                        ),
                      ),
      ],
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DiscoverFilter.values.map((filter) {
          final isActive = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isActive ? DevColors.primary : DevColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  filter.icon,
                  size: 14,
                  color: isActive ? Colors.white : DevColors.mutedFg,
                ),
              ),
              label: Text(
                filter.label,
                style: DevTheme.body(
                  size: 12,
                  w: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : DevColors.foreground,
                ),
              ),
              selected: isActive,
              onSelected: (_) => _onFilterChanged(filter),
              selectedColor: DevColors.primary.withValues(alpha: 0.15),
              checkmarkColor: DevColors.primary,
              backgroundColor: DevColors.card,
              side: BorderSide(
                color: isActive ? DevColors.primary : DevColors.border,
                width: isActive ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===== SECCIÓN: JUEGOS EN TENDENCIA =====
  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            children: [
              Text('Juegos en tendencia', style: DevTheme.display(size: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DevColors.destructive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 10, color: DevColors.destructive),
                    const SizedBox(width: 3),
                    Text('HOT', style: DevTheme.body(size: 9, w: FontWeight.w700, color: DevColors.destructive)),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrendingGamesScreen(
                      games: _trendingGames,
                      onGameTap: widget.onGameTap,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chevron_right_rounded, size: 16),
                label: Text('Ver todo', style: DevTheme.body(size: 12, w: FontWeight.w600, color: DevColors.primary)),
                style: TextButton.styleFrom(foregroundColor: DevColors.primary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: _trendingLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 5,
                  itemBuilder: (_, i) => _TrendingGameShimmer(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _trendingGames.length,
                  itemBuilder: (_, i) => _TrendingGameCard(
                    game: _trendingGames[i],
                    onTap: (name) => widget.onGameTap?.call(name),
                  ),
                ),
        ),
      ],
    );
  }

  // ===== SECCIÓN: EN DESARROLLO =====
  Widget _buildDevSection() {
    final devPosts = _devGames.where((p) => p.type == PostType.dev_log || p.type == PostType.update).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DevColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.code_rounded, size: 18, color: DevColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Text('En desarrollo', style: DevTheme.display(size: 20)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _onFilterChanged(DiscoverFilter.posts),
                child: Text('Ver todo', style: DevTheme.body(size: 12, w: FontWeight.w600, color: DevColors.primary)),
              ),
            ],
          ),
        ),
        _devLoading
            ? SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  itemBuilder: (_, i) => _DevGameShimmer(),
                ),
              )
            : devPosts.isEmpty
                ? _EmptyState(
                    icon: Icons.code_rounded,
                    title: 'Sin dev logs por ahora',
                    description: 'Los diarios de desarrollo aparecerán aquí.',
                    actionLabel: 'Ver feed',
                    onAction: () => _onFilterChanged(DiscoverFilter.todo),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: devPosts.length,
                      itemBuilder: (_, i) => _DevGameCard(
                        post: devPosts[i],
                        onTap: () => widget.onGameTap?.call(devPosts[i].game?.title ?? ''),
                      ),
                    ),
                  ),
      ],
    );
  }

  // ===== SECCIÓN: LABORATORIO DE BETAS =====
  Widget _buildBetaLabSection() {
    final betaPosts = _betaGames.where((p) => p.type == PostType.beta).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DevColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.science_rounded, size: 18, color: DevColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text('Laboratorio de betas', style: DevTheme.display(size: 20)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _onFilterChanged(DiscoverFilter.betas),
                child: Text('Ver todas', style: DevTheme.body(size: 12, w: FontWeight.w600, color: DevColors.primary)),
              ),
            ],
          ),
        ),
        _betaLoading
            ? SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  itemBuilder: (_, i) => _BetaCardShimmer(),
                ),
              )
            : betaPosts.isEmpty
                ? _EmptyState(
                    icon: Icons.science_rounded,
                    title: 'Sin betas abiertas',
                    description: 'Cuando haya betas buscando testers aparecerán aquí.',
                    actionLabel: 'Ver feed',
                    onAction: () => _onFilterChanged(DiscoverFilter.todo),
                  )
                : SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: betaPosts.length,
                      itemBuilder: (_, i) => _BetaLabCard(
                        post: betaPosts[i],
                        onTap: () => widget.onGameTap?.call(betaPosts[i].game?.title ?? ''),
                        onJoinTap: () => _joinBeta(betaPosts[i]),
                      ),
                    ),
                  ),
      ],
    );
  }

  // ===== JUEGO DESTACADO (MOCK) =====
  Post _mockFeaturedGame() {
    return Post(
      id: 'featured_1',
      type: PostType.game_showcase,
      author: const PostAuthor(
        id: 'dev_astro',
        username: 'astro_baker',
        fullName: 'Astro Baker',
        avatar: '',
        role: 'DEV',
        bio: 'Making cozy games',
        followersCount: 2100,
        followingCount: 80,
        isVerified: true,
        tags: ['simulation', 'cozy', 'godot'],
      ),
      content:
          '¡Astro Bakery ya está en beta! 🍞 Hornea panes espaciales, gestiona tu panadería interestelar y descubre recetas secretas. ¿Listo para ser el mejor panadero de la galaxia?',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      media: const [
        PostMedia(url: 'https://picsum.photos/1200/400', kind: 'image'),
      ],
      likesCount: 312,
      commentsCount: 45,
      sharesCount: 89,
      savesCount: 156,
      viewsCount: 5600,
      game: GameAttachment(
        id: 'g5',
        title: 'Astro Bakery',
        coverUrl: 'https://picsum.photos/1200/400',
        description: 'Simulación de panadería espacial. Gestiona tu panadería, descubre recetas, explora planetas.',
        developer: 'Astro Baker',
        genre: 'Simulation / Management',
        platform: 'PC, Steam Deck',
        status: 'beta',
        version: 'v0.8.0',
        playUrl: 'https://devplay.gg/beta/astro-bakery',
        storeUrl: 'https://store.steampowered.com/app/astro-bakery',
        tags: ['simulation', 'cozy', 'space', 'management'],
        viewsCount: 12000,
        followersCount: 2100,
      ),
      tags: ['simulation', 'cozy', 'beta', 'space', 'management'],
    );
  }

  List<Post> _mockDevGames() {
    return [
      Post(
        id: 'dev_1',
        type: PostType.dev_log,
        author: const PostAuthor(
          id: 'u6',
          username: 'code_wizard',
          fullName: 'Code Wizard',
          avatar: '',
          role: 'DEV',
          bio: 'Engine programmer',
          followersCount: 980,
          followingCount: 50,
          tags: ['rust', 'bevy', 'engine dev'],
        ),
        content: 'DevLog #42: Reescritura del motor de física. Ahora los colisionadores funcionan correctamente en mundos grandes.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        media: const [PostMedia(url: 'https://picsum.photos/400/225?random=1', kind: 'image')],
        likesCount: 67,
        commentsCount: 12,
        game: GameAttachment(
          id: 'g_dev1',
          title: 'Physics Engine Rewrite',
          coverUrl: 'https://picsum.photos/400/225?random=1',
          description: 'Motor de física determinista para mundos grandes',
          developer: 'Code Wizard',
          genre: 'Engine / Tech',
          status: 'prototype',
          tags: ['rust', 'bevy', 'physics'],
          viewsCount: 1200,
          followersCount: 980,
        ),
        tags: ['dev log', 'physics', 'rust', 'bevy'],
      ),
      Post(
        id: 'dev_2',
        type: PostType.dev_log,
        author: const PostAuthor(
          id: 'u7',
          username: 'pixel_master',
          fullName: 'Pixel Master',
          avatar: '',
          role: 'DEV',
          bio: 'Pixel artist & dev',
          followersCount: 1500,
          followingCount: 100,
          tags: ['pixel art', 'godot', 'indie'],
        ),
        content: 'Nuevo tileset para el bioma volcánico. 32 nuevas variaciones de lava, rocas y cenizas.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        media: const [PostMedia(url: 'https://picsum.photos/400/225?random=2', kind: 'image')],
        likesCount: 234,
        commentsCount: 28,
        game: GameAttachment(
          id: 'g_dev2',
          title: 'Volcanic Biome Tileset',
          coverUrl: 'https://picsum.photos/400/225?random=2',
          description: 'Tileset pixel art para bioma volcánico',
          developer: 'Pixel Master',
          genre: 'Asset Pack',
          status: 'released',
          tags: ['pixel art', 'tileset', 'godot'],
          viewsCount: 3400,
          followersCount: 1500,
        ),
        tags: ['pixel art', 'tileset', 'godot', 'assets'],
      ),
      Post(
        id: 'dev_3',
        type: PostType.update,
        author: const PostAuthor(
          id: 'u8',
          username: 'net_code',
          fullName: 'NetCode',
          avatar: '',
          role: 'DEV',
          bio: 'Network programmer',
          followersCount: 750,
          followingCount: 30,
          tags: ['netcode', 'multiplayer', 'rust'],
        ),
        content: 'v2.1.0: Implementado rollback netcode para fighting game. Latencia percibida < 2 frames.',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likesCount: 89,
        commentsCount: 15,
        game: GameAttachment(
          id: 'g_dev3',
          title: 'FighterZ Rollback',
          coverUrl: 'https://picsum.photos/400/225?random=3',
          description: 'Rollback netcode implementation',
          developer: 'NetCode',
          genre: 'Fighting / Tech',
          status: 'released',
          version: 'v2.1.0',
          tags: ['netcode', 'fighting', 'rollback'],
          viewsCount: 2100,
          followersCount: 750,
        ),
        tags: ['netcode', 'multiplayer', 'rollback', 'fighting'],
      ),
    ];
  }

  List<Post> _mockBetaGames() {
    return [
      Post(
        id: 'beta_1',
        type: PostType.beta,
        author: const PostAuthor(
          id: 'u9',
          username: 'rogue_dev',
          fullName: 'Rogue Dev',
          avatar: '',
          role: 'DEV',
          bio: 'Roguelike enthusiast',
          followersCount: 3200,
          followingCount: 150,
          tags: ['roguelike', 'procedural', 'unity'],
        ),
        content: '¡Dungeon Delver Beta 0.5 ya disponible! Mazmorras infinitas, 50+ items, 12 clases. Buscamos testers hardcore.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        likesCount: 445,
        commentsCount: 67,
        game: GameAttachment(
          id: 'beta_g1',
          title: 'Dungeon Delver',
          coverUrl: 'https://picsum.photos/400/225?random=4',
          description: 'Roguelike de mazmorras infinitas con 12 clases únicas',
          developer: 'Rogue Dev',
          genre: 'Roguelike / RPG',
          platform: 'PC',
          status: 'beta',
          version: 'v0.5.0',
          playUrl: 'https://devplay.gg/beta/dungeon-delver',
          tags: ['roguelike', 'procedural', 'rpg', 'hardcore'],
          viewsCount: 15000,
          followersCount: 3200,
        ),
        beta: BetaInfo(
          id: 'beta_1',
          title: 'Dungeon Delver',
          version: 'v0.5.0',
          genre: 'Roguelike',
          downloads: 3400,
          isOpen: true,
          testersCount: 3400,
          maxTesters: 10000,
        ),
        tags: ['roguelike', 'beta', 'procedural', 'rpg'],
      ),
      Post(
        id: 'beta_2',
        type: PostType.beta,
        author: const PostAuthor(
          id: 'u10',
          username: 'horizon_studios',
          fullName: 'Horizon Studios',
          avatar: '',
          role: 'DEV',
          bio: 'Space sim developers',
          followersCount: 1800,
          followingCount: 80,
          tags: ['space', 'simulation', 'unreal'],
        ),
        content: 'Star Horizon Alpha 2.0: Nuevo sistema de comercio, 50 sistemas estelares, IA mejorada.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likesCount: 289,
        commentsCount: 34,
        game: GameAttachment(
          id: 'beta_g2',
          title: 'Star Horizon',
          coverUrl: 'https://picsum.photos/400/225?random=5',
          description: 'Simulación espacial con comercio, combate y exploración',
          developer: 'Horizon Studios',
          genre: 'Space Sim',
          platform: 'PC',
          status: 'alpha',
          version: 'v2.0.0',
          playUrl: 'https://devplay.gg/beta/star-horizon',
          tags: ['space', 'simulation', 'trading', 'exploration'],
          viewsCount: 8900,
          followersCount: 1800,
        ),
        beta: BetaInfo(
          id: 'beta_2',
          title: 'Star Horizon',
          version: 'v2.0.0',
          genre: 'Space Sim',
          downloads: 1200,
          isOpen: true,
          testersCount: 1200,
          maxTesters: 5000,
        ),
        tags: ['space', 'simulation', 'alpha', 'trading'],
      ),
    ];
  }

  // ===== UTILIDADES =====
  void _openGame(Post post) {
    final game = post.game;
    final url = game?.playUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${game?.title ?? post.title} todavía no tiene enlace jugable'),
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enlace de ${game?.title ?? post.title} copiado')),
    );
  }

  Future<void> _openBeta(Post post) => _joinBeta(post);

  Future<void> _joinBeta(Post post) async {
    final gameId = post.game?.id;
    if (gameId == null || gameId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta beta no tiene un juego asociado')),
      );
      return;
    }
    if (_joiningBeta) return;
    setState(() => _joiningBeta = true);
    try {
      await PostService.joinBeta(gameId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud enviada para ${post.game?.title ?? post.title}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo unir a la beta: $e')),
      );
    } finally {
      if (mounted) setState(() => _joiningBeta = false);
    }
  }

  // Mock data trending
  List<TrendingGame> _mockTrendingGames() {
    return [
      TrendingGame(id: 'g1', name: 'Elden Ring', version: 'v1.1.0', views: '3.4M', isTrending: true, imageUrl: 'https://cdn.akamai.steamstatic.com/steam/apps/1245620/header.jpg', gradient: const LinearGradient(colors: [Color(0xFFC66E41), Color(0xFFB05A35)])),
      TrendingGame(id: 'g2', name: 'Hollow Knight', version: 'v1.5.78', views: '2.1M', isTrending: false, imageUrl: 'https://cdn.akamai.steamstatic.com/steam/apps/367520/header.jpg', gradient: const LinearGradient(colors: [Color(0xFF3C2B23), Color(0xFF2A1F1A)])),
      TrendingGame(id: 'g3', name: 'Stardew Valley', version: 'v1.6.9', views: '912K', isTrending: true, imageUrl: 'https://cdn.akamai.steamstatic.com/steam/apps/413150/header.jpg', gradient: const LinearGradient(colors: [Color(0xFF8FAF4A), Color(0xFF6B8E3A)])),
      TrendingGame(id: 'g4', name: 'Cyberpunk 2077', version: 'v2.1', views: '7.6M', isTrending: true, imageUrl: 'https://cdn.akamai.steamstatic.com/steam/apps/1091500/header.jpg', gradient: const LinearGradient(colors: [Color(0xFFE04E8C), Color(0xFFB83A6A)])),
      TrendingGame(id: 'g5', name: "Baldur's Gate 3", version: 'v4.1.1', views: '5.2M', isTrending: false, imageUrl: 'https://cdn.akamai.steamstatic.com/steam/apps/1086940/header.jpg', gradient: const LinearGradient(colors: [Color(0xFFD9A441), Color(0xFFB8862E)])),
    ];
  }
}

// Shimmer para juegos en tendencia
class _TrendingGameShimmer extends StatelessWidget {
  const _TrendingGameShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DevColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: 120,
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card para juegos en tendencia
class _TrendingGameCard extends StatelessWidget {
  final TrendingGame game;
  final void Function(String)? onTap;

  const _TrendingGameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(game.name),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: DevColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DevColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  game.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: DevColors.muted,
                    child: Icon(Icons.image, color: DevColors.mutedFg, size: 32),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: DevTheme.body(size: 12, w: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${game.views} vistas',
                    style: DevTheme.bodySecondary(size: 10),
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

// ===== WIDGETS AUXILIARES =====

/// Juego destacado (Hero grande)
class _FeaturedGameHero extends StatelessWidget {
  final Post game;
  final void Function(String)? onDetailTap;
  final VoidCallback onPlayTap;
  final VoidCallback onBetaTap;

  const _FeaturedGameHero({
    required this.game,
    this.onDetailTap,
    required this.onPlayTap,
    required this.onBetaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2A1F1A), const Color(0xFF1C1411)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Fondo con imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  game.media.isNotEmpty && game.media.first.url.isNotEmpty
                      ? Image.network(game.media.first.url, fit: BoxFit.cover)
                      : Container(color: DevColors.card),
                  // Gradiente overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1C1411).withValues(alpha: 0.9),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge estado
                if (game.game?.status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(game.game!.status!).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor(game.game!.status!)),
                    ),
                    child: Text(
                      game.game!.status!.toUpperCase(),
                      style: DevTheme.labelCaps(size: 10, color: _statusColor(game.game!.status!)),
                    ),
                  ),
                const SizedBox(height: 12),
                // Título
                Text(
                  game.game?.title ?? game.content.substring(0, 50),
                  style: DevTheme.display(size: 32, w: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Desarrollador + género
                if (game.game != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 14, color: DevColors.mutedFg),
                      const SizedBox(width: 4),
                      Text(game.game!.developer ?? '', style: DevTheme.bodySecondary(size: 13)),
                      if (game.game!.genre != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.category_rounded, size: 14, color: DevColors.mutedFg),
                        const SizedBox(width: 4),
                        Text(game.game!.genre!, style: DevTheme.bodySecondary(size: 13)),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPlayTap,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Jugar ahora'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onBetaTap,
                        icon: const Icon(Icons.science_rounded, size: 20),
                        label: const Text('Unirse a beta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DevColors.primary,
                          side: const BorderSide(color: DevColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Detalles
                if (game.game != null) ...[
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (game.game!.version != null)
                        _DetailChip(icon: Icons.tag_rounded, label: game.game!.version!),
                      if (game.game!.platform != null)
                        _DetailChip(icon: Icons.computer_rounded, label: game.game!.platform!),
                      _DetailChip(icon: Icons.visibility_rounded, label: '${compactNumber(game.viewsCount)} vistas'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'released': return DevColors.olive;
      case 'beta': return DevColors.primary;
      case 'alpha': return DevColors.amber;
      case 'prototype': return DevColors.gold;
      default: return DevColors.mutedFg;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DevColors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DevColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DevColors.mutedFg),
          const SizedBox(width: 4),
          Text(label, style: DevTheme.bodySecondary(size: 11)),
        ],
      ),
    );
  }
}

/// Sección En Desarrollo - Card
class _DevGameCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const _DevGameCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: DevTheme.glass(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: post.media.isNotEmpty && post.media.first.url.isNotEmpty
                    ? Image.network(post.media.first.url, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: DevColors.muted, child: Icon(Icons.code_rounded, size: 32, color: DevColors.mutedFg)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: DevColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('DevLog', style: DevTheme.labelCaps(size: 9, color: DevColors.gold)),
                      ),
                      const Spacer(),
                      Text(timeAgo(post.createdAt), style: DevTheme.bodySecondary(size: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.game?.title ?? post.content.substring(0, 30), style: DevTheme.body(size: 15, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (post.game?.developer != null)
                    Text('por ${post.game!.developer}', style: DevTheme.bodySecondary(size: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 13, color: DevColors.likedRed),
                      const SizedBox(width: 3),
                      Text('${post.likesCount}', style: DevTheme.bodySecondary(size: 11)),
                      const SizedBox(width: 12),
                      Icon(Icons.mode_comment_outlined, size: 13, color: DevColors.mutedFg),
                      const SizedBox(width: 3),
                      Text('${post.commentsCount}', style: DevTheme.bodySecondary(size: 11)),
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

/// Shimmer para dev games
class _DevGameShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: DevTheme.glass(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: DevColors.muted, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 14, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 120, height: 16, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 60, height: 12, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Beta Lab Card
class _BetaLabCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onJoinTap;

  const _BetaLabCard({required this.post, required this.onTap, required this.onJoinTap});

  @override
  Widget build(BuildContext context) {
    final beta = post.beta;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: DevTheme.glass(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: post.media.isNotEmpty && post.media.first.url.isNotEmpty
                    ? Image.network(post.media.first.url, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: DevColors.muted, child: Icon(Icons.science_rounded, size: 32, color: DevColors.mutedFg)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: beta?.isOpen == true ? DevColors.primary.withValues(alpha: 0.15) : DevColors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          beta?.isOpen == true ? 'ABIERTA' : 'CERRADA',
                          style: DevTheme.labelCaps(size: 9, color: beta?.isOpen == true ? DevColors.primary : DevColors.mutedFg),
                        ),
                      ),
                      const Spacer(),
                      if (beta?.version != null)
                        Text('v${beta!.version}', style: DevTheme.bodySecondary(size: 10, color: DevColors.gold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.game?.title ?? post.content.substring(0, 30), style: DevTheme.body(size: 15, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (post.game?.developer != null)
                    Text('por ${post.game!.developer}', style: DevTheme.bodySecondary(size: 11)),
                  const SizedBox(height: 10),
                  if (beta != null) ...[
                    Row(
                      children: [
                        Icon(Icons.people_rounded, size: 13, color: DevColors.mutedFg),
                        const SizedBox(width: 3),
                        Text('${beta.testersCount}/${beta.maxTesters} testers', style: DevTheme.bodySecondary(size: 11)),
                        const SizedBox(width: 12),
                        Icon(Icons.download_rounded, size: 13, color: DevColors.mutedFg),
                        const SizedBox(width: 3),
                        Text('${beta.downloads} descargas', style: DevTheme.bodySecondary(size: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Botón unirse
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onJoinTap,
                        icon: const Icon(Icons.science_rounded, size: 18),
                        label: Text(beta?.isOpen == true ? 'Unirse a la beta' : 'Beta cerrada'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: beta?.isOpen == true ? DevColors.primary : DevColors.muted,
                          foregroundColor: beta?.isOpen == true ? Colors.white : DevColors.mutedFg,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer para beta cards
class _BetaCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: DevTheme.glass(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: DevColors.muted, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 60, height: 18, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 120, height: 16, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 80, height: 12, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                Container(width: 100, height: 40, decoration: BoxDecoration(color: DevColors.muted, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: DevColors.muted, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: DevColors.mutedFg),
            ),
            const SizedBox(height: 20),
            Text(title, style: DevTheme.display(size: 18), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(description, style: DevTheme.bodySecondary(size: 14), textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(actionLabel, style: DevTheme.body(size: 13, w: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DevColors.primary,
                  side: const BorderSide(color: DevColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: DevColors.mutedFg),
            const SizedBox(height: 12),
            Text('Error cargando contenido', style: DevTheme.display(size: 16)),
            const SizedBox(height: 8),
            Text(message, style: DevTheme.bodySecondary(color: DevColors.destructive), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Filtros
enum DiscoverFilter {
  todo('Todo', Icons.grid_view_rounded),
  betas('Betas', Icons.sports_esports_rounded),
  posts('Posts', Icons.article_rounded);

  const DiscoverFilter(this.label, this.icon);
  final String label;
  final IconData icon;
}