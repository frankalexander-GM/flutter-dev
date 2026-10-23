import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/beta.dart';
import '../../models/post.dart';
import '../../models/trending_game.dart';
import '../../services/api_service.dart';
import '../../services/beta_service.dart';
import '../../services/post_service.dart';
import '../../theme.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../../utils/format.dart';
import 'trending_games_screen.dart';
import '../../widgets/animations.dart';
import '../../widgets/avatar.dart';
import '../../widgets/game_compose_sheet.dart';
import '../../widgets/hero_3d_shapes.dart';
import '../../widgets/hero_video.dart';
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

  const DiscoverScreen({super.key, this.onCreateTap, this.onGameTap});

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

  // En 'Todo' el feed se corta para que las secciones queden a la vista.
  static const int _feedPreviewCount = 6;
  bool _feedExpanded = false;

  // Devs recomendados y temas populares (GET /discover).
  List<_DiscoverUser> _recommendedUsers = const [];
  List<_DiscoverTag> _popularTags = const [];

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
      _loadDiscover(),
      _loadPosts(),
    ]);
  }

  /// Agregado del backend: devs recomendados y temas populares.
  Future<void> _loadDiscover() async {
    try {
      final data = await ApiService.getJson('/discover');
      if (!mounted) return;
      final users = (data['recommendedUsers'] as List? ?? [])
          .map((e) => _DiscoverUser.fromJson(e as Map<String, dynamic>))
          .where((u) => u.id.isNotEmpty)
          .take(8)
          .toList();
      final tags = (data['popularTags'] as List? ?? [])
          .map((e) => _DiscoverTag.fromJson(e as Map<String, dynamic>))
          .where((t) => t.tag.isNotEmpty)
          .take(14)
          .toList();
      setState(() {
        _recommendedUsers = users;
        _popularTags = tags;
      });
    } catch (_) {
      // Sección opcional: si falla no rompe el resto de Descubrir.
    }
  }

  Future<void> _onPublishGame() async {
    final created = await showGameComposeSheet(context);
    if (created != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Juego publicado! Ya aparece en Descubrir.'),
      ),
    );
    await _loadAll();
  }

  // ---------------------------------------------------------
  // 1. Juego Destacado (usando endpoint real GAME_SHOWCASE)
  // ---------------------------------------------------------
  Future<void> _loadFeaturedGame() async {
    try {
      var posts = await PostService.getPosts(
        type: 'GAME_SHOWCASE',
        sort: 'latest',
        limit: 1,
      );
      if (posts.isEmpty) {
        posts = await PostService.getPosts(
          type: 'BETA',
          sort: 'latest',
          limit: 1,
        );
      }
      if (posts.isEmpty) {
        posts = await PostService.getPosts(
          sort: 'trending',
          limit: 1,
        );
      }
      if (posts.isNotEmpty) {
        setState(() => _featuredGame = posts.first);
      } else {
        setState(() => _featuredGame = null);
      }
    } catch (_) {
      if (mounted) setState(() => _featuredGame = null);
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
      final posts = await PostService.getPosts(sort: 'trending', limit: 14);
      // Solo juegos: showcases, betas o publicaciones con portada. Así no se
      // cuelan encuestas ni posts de texto en "Juegos en tendencia".
      final games = posts
          .where(
            (p) =>
                p.type == PostType.beta ||
                p.type == PostType.game_showcase,
          )
          .toList();
      final sorted = [...games]
        ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
      setState(() {
        _trendingGames = sorted.map((p) {
          final cover =
              p.game?.coverUrl ??
              (p.media.isNotEmpty ? p.media.first.url : null);
          // "Titulo · Genero · vX" es el formato de los showcases.
          final firstLine = p.content.trim().split('\n').first;
          final parts = firstLine
              .split('·')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final label = p.beta?.title ??
              p.game?.title ??
              (parts.isNotEmpty ? parts.first : 'Publicación');
          return TrendingGame(
            id: p.id,
            name: label,
            version: p.beta?.version ?? p.game?.version ?? '',
            views: compactNumber(p.likesCount),
            isTrending: true,
            imageUrl: cover ?? '',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
          );
        }).toList();
        _trendingLoading = false;
      });
    } catch (_) {
      setState(() {
        _trendingGames = [];
        _trendingLoading = false;
      });
    }
  }

  Future<void> _loadDevGames() async {
    setState(() => _devLoading = true);
    try {
      final posts = await PostService.getPosts(
        type: 'DEV_LOG',
        sort: 'latest',
        limit: 6,
      );
      setState(() {
        _devGames = posts;
        _devLoading = false;
      });
    } catch (_) {
      setState(() {
        _devGames = [];
        _devLoading = false;
      });
    }
  }

  Future<void> _loadBetaGames() async {
    setState(() => _betaLoading = true);
    try {
      final posts = await PostService.getPosts(
        type: 'BETA',
        sort: 'latest',
        limit: 6,
      );
      setState(() {
        _betaGames = posts;
        _betaLoading = false;
      });
    } catch (_) {
      setState(() {
        _betaGames = [];
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
        case DiscoverFilter.devLogs:
          type = 'DEV_LOG';
          sort = 'latest';
          break;
        case DiscoverFilter.posts:
          type = 'POST';
          sort = 'latest';
          break;
      }

      final posts = await PostService.getPosts(
        type: type,
        sort: sort,
        limit: 50,
      );
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
      setState(() {
        _activeFilter = filter;
        _feedExpanded = false;
      });
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: DevColors.accentCyan,
          backgroundColor: DevColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. BANNER — título de la sección + accesos rápidos.
              SliverToBoxAdapter(
                child: _DiscoverBanner(
                  featured: _featuredGame,
                  onCreateTap: _onPublishGame,
                  onSearchTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    ),
                  ),
                  onFeaturedTap: () {
                    final game = _featuredGame;
                    if (game != null) _openGame(game);
                  },
                ),
              ),

              // 2. JUEGOS EN TENDENCIA
              if (_trendingLoading || _trendingGames.isNotEmpty)
                SliverToBoxAdapter(child: _buildTrendingSection()),

              // 3. LABORATORIO DE BETAS (lo que se puede probar ya)
              if (_betaLoading || _betaGames.isNotEmpty)
                SliverToBoxAdapter(child: _buildBetaLabSection()),

              // 4. EN DESARROLLO (dev logs)
              if (_devLoading || _devGames.isNotEmpty)
                SliverToBoxAdapter(child: _buildDevSection()),

              // 5. DEVS PARA SEGUIR
              if (_recommendedUsers.isNotEmpty)
                SliverToBoxAdapter(child: _buildDevsSection()),

              // 6. TEMAS POPULARES
              if (_popularTags.isNotEmpty)
                SliverToBoxAdapter(child: _buildTagsSection()),

              // 7. FEED — al final, para que Descubrir sea descubrir.
              SliverToBoxAdapter(child: _buildFeedHeader()),
              ..._buildFeedSlivers(),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ===== SECCIÓN: FEED DE PUBLICACIONES (SLIVER LIST INTEGRADO) =====
  /// Header del feed con el título y los filtros activos.
  Widget _buildFeedHeader() {
    return Container(
      color: DevColors.card,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text('Feed', style: DevTheme.display(size: 22)),
          const SizedBox(width: 12),
          Expanded(child: _buildFilterPills()),
        ],
      ),
    );
  }

  /// Slivers del feed. Se devuelven como lista para poder insertarlos
  /// directamente en el `CustomScrollView` (un sliver no puede ser hijo
  /// de un `Column`).
  List<Widget> _buildFeedSlivers() {
    if (_isLoading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: DevColors.primary),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorView(message: _error!, onRetry: _loadPosts),
        ),
      ];
    }
    if (_posts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.article_outlined,
            title: 'Sin publicaciones',
            description: 'Sé el primero en compartir algo.',
            actionLabel: 'Crear publicación',
            onAction: widget.onCreateTap,
          ),
        ),
      ];
    }
    final collapsed =
        _activeFilter == DiscoverFilter.todo && !_feedExpanded;
    final visible = collapsed
        ? _posts.take(_feedPreviewCount).toList()
        : _posts;
    final hidden = _posts.length - visible.length;

    return [
      SliverList.separated(
        key: _feedKey,
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: i == 0
              ? Sheen(
                  child: PostCard(
                    post: visible[i],
                    onGameTap: widget.onGameTap,
                    onProfileTap: () => _openAuthor(visible[i]),
                  ),
                )
              : PostCard(
                  post: visible[i],
                  onGameTap: widget.onGameTap,
                  onProfileTap: () => _openAuthor(visible[i]),
                ),
        ),
      ),
      if (hidden > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _feedExpanded = true),
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(
                  'Ver $hidden publicaciones más',
                  style: DevTheme.body(size: 13, w: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DevColors.primary,
                  side: BorderSide(
                    color: DevColors.primary.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DiscoverFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterPill(
              filter: filter,
              active: _activeFilter == filter,
              onTap: () => _onFilterChanged(filter),
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
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 10,
                      color: DevColors.destructive,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'HOT',
                      style: DevTheme.body(
                        size: 9,
                        w: FontWeight.w700,
                        color: DevColors.destructive,
                      ),
                    ),
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
                label: Text(
                  'Ver todo',
                  style: DevTheme.body(
                    size: 12,
                    w: FontWeight.w600,
                    color: DevColors.primary,
                  ),
                ),
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

  // ===== SECCIÓN: DEVS PARA SEGUIR =====
  Widget _buildDevsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.people_alt_rounded,
          color: DevColors.accentCyan,
          title: 'Devs para seguir',
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _recommendedUsers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _DevUserCard(
              user: _recommendedUsers[i],
              onTap: () => _openDev(_recommendedUsers[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ===== SECCIÓN: TEMAS POPULARES =====
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.tag_rounded,
          color: DevColors.goldSoft,
          title: 'Temas populares',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _popularTags)
                _TagChip(
                  tag: tag,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(initialQuery: tag.tag),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Cabecera común de sección (icono + título, opcionalmente con acción).
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: DevTheme.display(size: 19),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.chevron_right_rounded, size: 16),
              label: Text(
                actionLabel,
                style: DevTheme.body(
                  size: 12,
                  w: FontWeight.w600,
                  color: DevColors.primary,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: DevColors.primary),
            ),
        ],
      ),
    );
  }

  void _openDev(_DiscoverUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
    );
  }

  // ===== SECCIÓN: EN DESARROLLO =====
  Widget _buildDevSection() {
    final devPosts = _devGames
        .where((p) => p.type == PostType.dev_log || p.type == PostType.update)
        .toList();

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
                    child: Icon(
                      Icons.code_rounded,
                      size: 18,
                      color: DevColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('En desarrollo', style: DevTheme.display(size: 20)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _onFilterChanged(DiscoverFilter.devLogs),
                child: Text(
                  'Ver todo',
                  style: DevTheme.body(
                    size: 12,
                    w: FontWeight.w600,
                    color: DevColors.primary,
                  ),
                ),
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
                    onTap: () =>
                        widget.onGameTap?.call(devPosts[i].game?.title ?? ''),
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
                    child: Icon(
                      Icons.science_rounded,
                      size: 18,
                      color: DevColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Laboratorio de betas',
                    style: DevTheme.display(size: 20),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _onFilterChanged(DiscoverFilter.betas),
                child: Text(
                  'Ver todas',
                  style: DevTheme.body(
                    size: 12,
                    w: FontWeight.w600,
                    color: DevColors.primary,
                  ),
                ),
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
                description:
                    'Cuando haya betas buscando testers aparecerán aquí.',
                actionLabel: 'Ver feed',
                onAction: () => _onFilterChanged(DiscoverFilter.todo),
              )
            : SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: betaPosts.length,
                  itemBuilder: (_, i) => _BetaLabCard(
                    post: betaPosts[i],
                    onTap: () =>
                        widget.onGameTap?.call(betaPosts[i].game?.title ?? ''),
                    onJoinTap: () => _joinBeta(betaPosts[i]),
                  ),
                ),
              ),
      ],
    );
  }

  // ===== UTILIDADES =====
  /// Abre el perfil público del autor de una publicación.
  void _openAuthor(Post post) {
    final authorId = post.author?.id;
    if (authorId == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: authorId)));
  }

  Future<void> _openGame(Post post) async {
    final game = post.game;
    final title = game?.title ?? post.title;
    final url = game?.playUrl ?? _firstUrl(post.content);
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title todavía no tiene enlace jugable')),
      );
      return;
    }

    var opened = false;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: url));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(opened ? 'Abriendo $title…' : 'Enlace de $title copiado'),
      ),
    );
  }

  Future<void> _joinBeta(Post post) async {
    if (_joiningBeta) return;
    setState(() => _joiningBeta = true);
    try {
      // El feed no embebe la beta: la buscamos por su `postId` en `/betas`.
      Beta? beta;
      if (post.beta?.id != null) {
        beta = await BetaService.getBeta(post.beta!.id);
      } else {
        final betas = await BetaService.getBetas(limit: 100);
        for (final candidate in betas) {
          if (candidate.postId == post.id) {
            beta = candidate;
            break;
          }
        }
      }

      if (beta == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta publicación no tiene una beta asociada'),
          ),
        );
        return;
      }

      final result = await BetaService.registerDownload(beta.id);
      final url = (result['url'] ?? '').toString();
      if (url.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La beta todavía no tiene enlace de descarga'),
          ),
        );
        return;
      }

      var opened = false;
      final uri = Uri.tryParse(url);
      if (uri != null) {
        try {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false;
        }
      }
      if (!opened) {
        await Clipboard.setData(ClipboardData(text: url));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Abriendo la beta de ${beta.title}…'
                : 'Enlace de la beta copiado',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir la beta: $e')));
    } finally {
      if (mounted) setState(() => _joiningBeta = false);
    }
  }
}

/// Título legible para un post sin metadatos de juego (el feed no embebe
/// `game`), evitando `substring` fuera de rango en textos cortos.
String _postLabel(Post post, {int max = 40}) {
  final title = post.game?.title;
  if (title != null && title.trim().isNotEmpty) return title;
  final text = post.content.trim();
  if (text.isEmpty) {
    return post.media.isNotEmpty ? 'Publicación con imagen' : 'Publicación';
  }
  final firstLine = text.split(RegExp(r'\r?\n')).first.trim();
  final label = firstLine.isEmpty ? text : firstLine;
  return label.length > max ? '${label.substring(0, max)}…' : label;
}

String? _firstUrl(String text) {
  final match = RegExp(r'https?://[^\s]+').firstMatch(text);
  return match?.group(0);
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

  Widget _trendingFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152238), Color(0xFF2A1B4A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 30,
          color: DevColors.accentCyan.withValues(alpha: 0.45),
        ),
      ),
    );
  }

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: game.imageUrl.isEmpty
                    ? _trendingFallback()
                    : Image.network(
                        game.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _trendingFallback(),
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
                    '${game.views} me gusta',
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
/// Banner compacto de la pantalla Descubrir.
///
/// Antes el hero ocupaba media pantalla y mostraba el juego destacado tan
/// grande que parecia que estabas dentro de una ficha de juego. Ahora es una
/// banda de ~200 px con el titulo de la seccion, un resumen y dos accesos,
/// mas una tarjeta pequena con el destacado.
class _DiscoverBanner extends StatelessWidget {
  final Post? featured;
  final VoidCallback onCreateTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFeaturedTap;

  const _DiscoverBanner({
    required this.featured,
    required this.onCreateTap,
    required this.onSearchTap,
    required this.onFeaturedTap,
  });

  String get _featuredTitle {
    final post = featured;
    if (post == null) return '';
    final beta = post.beta;
    if (beta != null && beta.title.trim().isNotEmpty) return beta.title.trim();
    final firstLine = post.content.trim().split('\n').first;
    final parts = firstLine
        .split('·')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.first : 'Juego destacado';
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      height: wide ? 190 : 214,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF081221)],
        ),
        border: Border.all(color: DevColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: HeroVideo(
                videoAsset: 'assets/videos/hero_loop_crystal_loop',
                posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
                shapeStyle: Hero3DStyle.discover,
                shapeOpacity: 0.20,
                scrimOpacity: 0.58,
                enablePointerInterceptor: false,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 24 : 18,
              16,
              wide ? 20 : 18,
              16,
            ),
            child: wide
                ? Row(
                    children: [
                      Expanded(child: _copy(context)),
                      if (featured != null) ...[
                        const SizedBox(width: 20),
                        _featuredMini(context),
                      ],
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_copy(context)],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _copy(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DevColors.accentCyan.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: DevColors.accentCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'DESCUBRIR',
                style: DevTheme.labelCaps(
                  size: 8.5,
                  color: DevColors.accentCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Descubre tu próximo juego',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DevTheme.display(size: 26, w: FontWeight.w800).copyWith(
            height: 1.1,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Betas abiertas, juegos en desarrollo y devs de la comunidad.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DevTheme.body(size: 12.5, color: DevColors.mutedFg),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _bannerButton(
              icon: Icons.add_rounded,
              label: 'Publicar juego',
              onTap: onCreateTap,
              primary: true,
            ),
            _bannerButton(
              icon: Icons.search_rounded,
              label: 'Buscar juegos',
              onTap: onSearchTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _bannerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return SizedBox(
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: primary
                  ? const LinearGradient(
                      colors: [Color(0xFF00C8E0), Color(0xFF3B82F6)],
                    )
                  : null,
              color: primary
                  ? null
                  : DevColors.cardRaised.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primary
                    ? Colors.transparent
                    : DevColors.accentCyan.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: DevTheme.body(
                    size: 12,
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

  /// Tarjeta pequena con el juego destacado (solo escritorio).
  Widget _featuredMini(BuildContext context) {
    final post = featured!;
    final cover = post.media.isNotEmpty ? post.media.first.url : '';
    final version = post.beta?.version ?? post.game?.version ?? '';

    return SizedBox(
      width: 262,
      height: 78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onFeaturedTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DevColors.card.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DevColors.accentCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: cover.isEmpty
                        ? _bannerFallback()
                        : Image.network(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _bannerFallback(),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESTACADO',
                        style: DevTheme.labelCaps(
                          size: 8,
                          color: DevColors.accentCyan,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _featuredTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.body(size: 13, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        version.isEmpty ? 'Ver ficha' : 'v$version · Ver ficha',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.bodySecondary(size: 10.5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: DevColors.mutedFg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152238), Color(0xFF2A1B4A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 24,
          color: DevColors.accentCyan.withValues(alpha: 0.5),
        ),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: post.media.isNotEmpty && post.media.first.url.isNotEmpty
                    ? Image.network(
                        post.media.first.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: DevColors.muted,
                        child: Icon(
                          Icons.code_rounded,
                          size: 32,
                          color: DevColors.mutedFg,
                        ),
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DevColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DevLog',
                          style: DevTheme.labelCaps(
                            size: 9,
                            color: DevColors.gold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeAgo(post.createdAt),
                        style: DevTheme.bodySecondary(size: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.game?.title ?? _postLabel(post, max: 30),
                    style: DevTheme.body(size: 15, w: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (post.game?.developer != null)
                    Text(
                      'por ${post.game!.developer}',
                      style: DevTheme.bodySecondary(size: 11),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: DevColors.likedRed,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${post.likesCount}',
                        style: DevTheme.bodySecondary(size: 11),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 13,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${post.commentsCount}',
                        style: DevTheme.bodySecondary(size: 11),
                      ),
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
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
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

  const _BetaLabCard({
    required this.post,
    required this.onTap,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final beta = post.beta;
    final isOpen = beta?.isOpen ?? false;
    final title = beta?.title ??
        post.game?.title ??
        _postLabel(post, max: 28);
    final genre = (beta?.genre ?? '').trim();
    final version = (beta?.version ?? '').trim();
    final meta = [
      if (genre.isNotEmpty) genre,
      if (version.isNotEmpty) 'v$version',
    ].join(' · ');
    final cover = post.media.isNotEmpty ? post.media.first.url : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 272,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: DevTheme.glass(radius: 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 62,
                height: 62,
                child: cover.isNotEmpty
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _coverFallback(),
                      )
                    : _coverFallback(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? DevColors.primary.withValues(alpha: 0.16)
                              : DevColors.muted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isOpen ? 'ABIERTA' : 'CERRADA',
                          style: DevTheme.labelCaps(
                            size: 8.5,
                            color: isOpen
                                ? DevColors.primary
                                : DevColors.mutedFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DevTheme.bodySecondary(size: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 12,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${beta?.downloads ?? 0}',
                        style: DevTheme.bodySecondary(size: 11),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 26,
                        child: TextButton(
                          onPressed: isOpen ? onJoinTap : null,
                          style: TextButton.styleFrom(
                            backgroundColor: isOpen
                                ? DevColors.primary
                                : DevColors.muted,
                            foregroundColor: isOpen
                                ? Colors.white
                                : DevColors.mutedFg,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isOpen ? 'Unirse' : 'Cerrada',
                            style: DevTheme.body(size: 11, w: FontWeight.w700),
                          ),
                        ),
                      ),
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

  Widget _coverFallback() {
    return Container(
      color: DevColors.muted,
      child: const Icon(
        Icons.science_rounded,
        size: 22,
        color: DevColors.mutedFg,
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
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 18,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DevColors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
              decoration: BoxDecoration(
                color: DevColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: DevColors.mutedFg),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: DevTheme.display(size: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: DevTheme.bodySecondary(size: 14),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              _GlowGradientButton(
                onTap: onAction,
                icon: Icons.explore_rounded,
                label: actionLabel,
                colors: const [DevColors.accentCyan, DevColors.primary],
                glow: DevColors.accentCyan,
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
            Text(
              message,
              style: DevTheme.bodySecondary(color: DevColors.destructive),
              textAlign: TextAlign.center,
            ),
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
  devLogs('Dev logs', Icons.code_rounded),
  posts('Posts', Icons.article_rounded);

  const DiscoverFilter(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Píldora de filtro con estética neón/glass.
///
/// Activa: cian translúcido + borde cian + halo. Inactiva: superficie oscura
/// translúcida con texto apagado que sube de contraste al pasar el mouse.
class _FilterPill extends StatefulWidget {
  final DiscoverFilter filter;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.filter,
    required this.active,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    const cyan = DevColors.accentCyan;
    const slate800 = Color(0xFF1E293B);
    const slate400 = Color(0xFF94A3B8);
    final active = widget.active;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? cyan.withValues(alpha: 0.15)
                : const Color(0xFF0F172A)
                      .withValues(alpha: _hover ? 0.75 : 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? cyan
                  : (_hover ? slate400.withValues(alpha: 0.4) : slate800),
              width: active ? 1.5 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: cyan.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.filter.icon,
                size: 14,
                color: active ? cyan : slate400,
              ),
              const SizedBox(width: 6),
              Text(
                widget.filter.label,
                style: DevTheme.body(
                  size: 12,
                  w: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? cyan
                      : (_hover ? DevColors.foreground : slate400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón CTA con gradiente y glow, usado en el banner y el estado vacío.
class _GlowGradientButton extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final List<Color> colors;
  final Color glow;

  const _GlowGradientButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.colors,
    required this.glow,
  });

  @override
  State<_GlowGradientButton> createState() => _GlowGradientButtonState();
}

class _GlowGradientButtonState extends State<_GlowGradientButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.03 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: _hover ? 0.28 : 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glow.withValues(alpha: _hover ? 0.6 : 0.4),
                  blurRadius: _hover ? 22 : 15,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DevTheme.body(
                      size: 14,
                      w: FontWeight.w700,
                      color: Colors.white,
                    ),
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

// ===== WIDGETS: DESCUBRIR =====

/// Tarjeta de un dev recomendado.
class _DevUserCard extends StatelessWidget {
  final _DiscoverUser user;
  final VoidCallback onTap;

  const _DevUserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.isNotEmpty ? user.fullName : user.username;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 236,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DevColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DevColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                username: user.username,
                avatar: user.avatar,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DevTheme.body(size: 13, w: FontWeight.w700),
                    ),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DevTheme.bodySecondary(size: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.bio.isEmpty ? 'Dev en DevPlay' : user.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DevTheme.body(
                        size: 11,
                        height: 1.35,
                        color: DevColors.mutedFg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 11,
                          color: DevColors.mutedFg,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${compactNumber(user.followersCount)} seguidores',
                          style: DevTheme.bodySecondary(size: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de tema popular.
class _TagChip extends StatelessWidget {
  final _DiscoverTag tag;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DevColors.card,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: DevColors.accentCyan.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#${tag.tag}',
                style: DevTheme.body(
                  size: 12,
                  w: FontWeight.w600,
                  color: DevColors.foreground,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: DevColors.accentCyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${tag.count}',
                  style: DevTheme.body(
                    size: 9.5,
                    w: FontWeight.w700,
                    color: DevColors.accentCyan,
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

/// Usuario recomendado que llega de `/discover`.
class _DiscoverUser {
  final String id;
  final String username;
  final String fullName;
  final String bio;
  final String? avatar;
  final int followersCount;

  const _DiscoverUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.bio,
    required this.followersCount,
    this.avatar,
  });

  factory _DiscoverUser.fromJson(Map<String, dynamic> json) => _DiscoverUser(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
        bio: json['bio'] as String? ?? '',
        avatar: json['avatar'] as String?,
        followersCount:
            (json['followersCount'] ?? json['followers_count'] ?? 0) as int,
      );
}

/// Tema popular que llega de `/discover`.
class _DiscoverTag {
  final String tag;
  final int count;

  const _DiscoverTag({required this.tag, required this.count});

  factory _DiscoverTag.fromJson(Map<String, dynamic> json) => _DiscoverTag(
        tag: json['tag'] as String? ?? '',
        count: (json['count'] ?? 0) as int,
      );
}
