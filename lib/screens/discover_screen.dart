import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/beta.dart';
import '../../models/post.dart';
import '../../models/trending_game.dart';
import '../../services/beta_service.dart';
import '../../services/post_service.dart';
import '../../theme.dart';
import 'profile_screen.dart';
import '../../utils/format.dart';
import 'trending_games_screen.dart';
import '../../widgets/animations.dart';
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
      final posts = await PostService.getPosts(
        type: 'GAME_SHOWCASE',
        sort: 'latest',
        limit: 1,
      );
      if (posts.isNotEmpty) {
        setState(() => _featuredGame = posts.first);
      } else {
        setState(() => _featuredGame = null);
      }
    } catch (_) {
      // Sin backend no inventamos un juego: la sección simplemente no se pinta.
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
      final posts = await PostService.getPosts(sort: 'trending', limit: 8);
      // Ordenar por likes (más populares primero) y mapear a TrendingGame.
      final sorted = [...posts]
        ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
      setState(() {
        _trendingGames = sorted.map((p) {
          final cover =
              p.game?.coverUrl ??
              (p.media.isNotEmpty ? p.media.first.url : null);
          final label =
              p.game?.title ??
              (p.content.isNotEmpty
                  ? (p.content.length > 30
                        ? '${p.content.substring(0, 30)}...'
                        : p.content)
                  : 'Publicación');
          return TrendingGame(
            id: p.id,
            name: label,
            version: p.game?.version ?? '',
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
            // Si la API no tiene showcases publicados, se muestra el hero con
            // video y un estado honesto en vez de dejar un hueco vacío.
            SliverToBoxAdapter(
              child: _featuredGame != null
                  ? _FeaturedGameHero(
                      game: _featuredGame!,
                      onDetailTap: widget.onGameTap,
                      onPlayTap: () => _openGame(_featuredGame!),
                      onBetaTap: () => _openBeta(_featuredGame!),
                    )
                  : _DiscoverHeroFallback(onCreateTap: _onPublishGame),
            ),

            // 2. FEED DE PUBLICACIONES (integrado en el scroll principal)
            // El header va en su propio SliverToBoxAdapter y la lista se
            // agrega como sliver real: un SliverList nunca puede vivir
            // dentro de un Column (RenderFlex).
            SliverToBoxAdapter(child: _buildFeedHeader()),
            ..._buildFeedSlivers(),

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
    return [
      SliverList.separated(
        key: _feedKey,
        itemCount: _posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: i == 0
              ? Sheen(
                  child: PostCard(
                    post: _posts[i],
                    onGameTap: widget.onGameTap,
                    onProfileTap: () => _openAuthor(_posts[i]),
                  ),
                )
              : PostCard(
                  post: _posts[i],
                  onGameTap: widget.onGameTap,
                  onProfileTap: () => _openAuthor(_posts[i]),
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
                height: 240,
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

  Future<void> _openBeta(Post post) => _joinBeta(post);

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
                    ? Container(
                        color: DevColors.muted,
                        child: Icon(
                          Icons.image,
                          color: DevColors.mutedFg,
                          size: 32,
                        ),
                      )
                    : Image.network(
                        game.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: DevColors.muted,
                          child: Icon(
                            Icons.image,
                            color: DevColors.mutedFg,
                            size: 32,
                          ),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF0F172A), const Color(0xFF060B14)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Video 3D en loop como base del hero (mismo asset que Inicio).
          Positioned.fill(
            child: HeroVideo(
              videoAsset: 'assets/videos/hero_loop_crystal_loop',
              posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
              autoPlay: true,
              mute: true,
              shapeOpacity: 0.35,
              shapeStyle: Hero3DStyle.home,
              enablePointerInterceptor: false,
              scrimOpacity: 0.20,
            ),
          ),
          // Fondo con imagen del juego (real, de la API) sobre el video.
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  game.media.isNotEmpty && game.media.first.url.isNotEmpty
                      ? Opacity(
                          opacity: 0.72,
                          child: Image.network(
                            game.media.first.url,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(color: DevColors.card),
                  // Gradiente overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF060B14).withValues(alpha: 0.9),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(game.game!.status!)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor(game.game!.status!),
                      ),
                    ),
                    child: Text(
                      game.game!.status!.toUpperCase(),
                      style: DevTheme.labelCaps(
                        size: 10,
                        color: _statusColor(game.game!.status!),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Título
                Text(
                  game.game?.title ?? _postLabel(game, max: 50),
                  style: DevTheme.display(size: 32, w: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Desarrollador + género
                if (game.game != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        game.game!.developer ?? '',
                        style: DevTheme.bodySecondary(size: 13),
                      ),
                      if (game.game!.genre != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.category_rounded,
                          size: 14,
                          color: DevColors.mutedFg,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          game.game!.genre!,
                          style: DevTheme.bodySecondary(size: 13),
                        ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          side: const BorderSide(
                            color: DevColors.primary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        _DetailChip(
                          icon: Icons.tag_rounded,
                          label: game.game!.version!,
                        ),
                      if (game.game!.platform != null)
                        _DetailChip(
                          icon: Icons.computer_rounded,
                          label: game.game!.platform!,
                        ),
                      _DetailChip(
                        icon: Icons.visibility_rounded,
                        label: '${compactNumber(game.viewsCount)} vistas',
                      ),
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
      case 'released':
        return DevColors.olive;
      case 'beta':
        return DevColors.primary;
      case 'alpha':
        return DevColors.amber;
      case 'prototype':
        return DevColors.gold;
      default:
        return DevColors.mutedFg;
    }
  }
}

/// Hero de respaldo de Descubrir.
///
/// Cuando la API todavía no tiene publicaciones de tipo `GAME_SHOWCASE`, el
/// hero de juego destacado no puede mostrarse. En vez de dejar un hueco en la
/// parte superior de la vista, se muestra el mismo fondo de video con un
/// mensaje honesto y una acción útil.
class _DiscoverHeroFallback extends StatelessWidget {
  final VoidCallback? onCreateTap;

  const _DiscoverHeroFallback({this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF060B14)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Mismo video 3D en loop que el resto de heroes.
          const Positioned.fill(
            child: HeroVideo(
              videoAsset: 'assets/videos/hero_loop_crystal_loop',
              posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
              autoPlay: true,
              mute: true,
              shapeOpacity: 0.35,
              shapeStyle: Hero3DStyle.home,
              enablePointerInterceptor: false,
              scrimOpacity: 0.20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: DevColors.accentCyan.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DevColors.accentCyan.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    'DESCUBRIR',
                    style: DevTheme.labelCaps(
                      size: 10,
                      color: DevColors.accentCyan,
                    ).copyWith(letterSpacing: 1.6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aún no hay juegos destacados',
                  style: DevTheme.display(size: 26, w: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Publica un showcase y aparecerá aquí como juego destacado.',
                  style: DevTheme.bodySecondary(size: 13),
                ),
                const SizedBox(height: 16),
                if (onCreateTap != null)
                  _GlowGradientButton(
                    onTap: onCreateTap,
                    icon: Icons.add_rounded,
                    label: 'Publicar un juego',
                    colors: const [Color(0xFFFF5E00), Color(0xFFFF8700)],
                    glow: const Color(0xFFFF5E00),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
                          Icons.science_rounded,
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
                          color: beta?.isOpen == true
                              ? DevColors.primary.withValues(alpha: 0.15)
                              : DevColors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          beta?.isOpen == true ? 'ABIERTA' : 'CERRADA',
                          style: DevTheme.labelCaps(
                            size: 9,
                            color: beta?.isOpen == true
                                ? DevColors.primary
                                : DevColors.mutedFg,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (beta?.version != null)
                        Text(
                          'v${beta!.version}',
                          style: DevTheme.bodySecondary(
                            size: 10,
                            color: DevColors.gold,
                          ),
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
                  const SizedBox(height: 10),
                  if (beta != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 13,
                          color: DevColors.mutedFg,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${beta.testersCount}/${beta.maxTesters} testers',
                          style: DevTheme.bodySecondary(size: 11),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.download_rounded,
                          size: 13,
                          color: DevColors.mutedFg,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${beta.downloads} descargas',
                          style: DevTheme.bodySecondary(size: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Botón unirse
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onJoinTap,
                        icon: const Icon(Icons.science_rounded, size: 18),
                        label: Text(
                          beta.isOpen ? 'Unirse a la beta' : 'Beta cerrada',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: beta.isOpen
                              ? DevColors.primary
                              : DevColors.muted,
                          foregroundColor: beta.isOpen
                              ? Colors.white
                              : DevColors.mutedFg,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
