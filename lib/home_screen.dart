import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/navigation.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../screens/betas_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reports_screen.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/beta_compose_sheet.dart';
import '../widgets/drawer.dart';
import '../widgets/header.dart';
import '../widgets/post_card.dart';
import '../widgets/sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewId _currentView = ViewId.explore;
  List<Post> _posts = [];
  List<GameAttachment> _featuredGames = [];
  int _betasVersion = 0;
  bool _isLoading = true;
  String? _error;
  int _unread = 0;
  bool _drawerOpen = false;
  bool _showAllFeed = false;

  // Breakpoint para sidebar (desktop >= 800px)
  static const double _sidebarBreakpoint = 800;

  // Keys para el Tour guiado
  final _heroKey = GlobalKey();
  final _tickerKey = GlobalKey();
  final _feedKey = GlobalKey();
  final _createKey = GlobalKey();
  final _sidebarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Determinar filtro y orden según la vista activa
      String? type;
      String? sort;
      switch (_currentView) {
        case ViewId.discover:
          sort = 'trending'; // trending = likes + recencia
          break;
        case ViewId.explore:
          sort = 'latest';   // cronológico
          break;
        case ViewId.betas:
          type = 'BETA';
          sort = 'latest';
          break;
        case ViewId.chat:
          type = 'STREAM';
          sort = 'latest';
          break;
        default:
          sort = 'latest';
      }

      final posts = await PostService.getPosts(type: type, sort: sort);

      // Juegos recomendados: showcases reales del backend (sin datos inventados).
      List<GameAttachment> games = [];
      try {
        final showcases = await PostService.getPosts(
          type: 'GAME_SHOWCASE',
          sort: 'trending',
          limit: 4,
        );
        games = showcases
            .map((p) => p.game)
            .whereType<GameAttachment>()
            .toList();
      } catch (_) {
        // Aún no hay showcases publicados: la sección muestra su estado vacío.
      }

      int unread = 0;
      try {
        unread = await UserService.getUnreadCount();
      } catch (_) {
        // Invitado sin notificaciones: badge en 0.
      }
      _posts = posts;
      _featuredGames = games;
      _unread = unread;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onViewChanged(ViewId view) {
    setState(() => _currentView = view);
    // Recargar feed según la vista (futuro: cada vista su endpoint)
    _load();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted) {
      try {
        _unread = await UserService.getUnreadCount();
        setState(() {});
      } catch (_) {
        // sin sesión: se ignora
      }
    }
  }

  Future<void> _openProfile() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
      );
      if (mounted) _load();
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _onCreatePost() {
    _CreateDock(onCreated: _load)._open(context);
  }

  Future<void> _onCreateBeta() async {
    final created = await showBetaComposeSheet(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Beta publicada!')),
      );
      setState(() => _betasVersion++);
      _load();
    }
  }

  void _onCreatePoll() {
    _CreateDock(onCreated: _load, startWithPoll: true)._open(context);
  }

  void _onStartTour() {
    _startTour();
  }

  /// La tienda todavía está en construcción: en vez de abrir la pantalla se
  /// muestra un letrero honesto de "no disponible".
  void _openStore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: DevColors.border),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: DevColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8862E), Color(0xFF9D6B1F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DevColors.gold.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: DevColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: DevColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'NO DISPONIBLE',
                  style: DevTheme.labelCaps(size: 9.5, color: DevColors.goldSoft),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tienda en construcción',
                style: DevTheme.display(size: 20, w: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  'Estamos preparando la tienda de DevPlay: power-ups, '
                  'cosméticos y más. Muy pronto estará disponible.',
                  style: DevTheme.body(
                    size: 13,
                    color: DevColors.mutedFg,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DevColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReports() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  Future<void> _searchUser(String raw) async {
    final username = raw.trim().replaceFirst(RegExp(r'^@'), '');
    if (username.isEmpty) return;
    try {
      final id = await UserService.getUserIdByUsername(username);
      if (!mounted) return;
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No existe el usuario @$username')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(userId: id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo buscar: $e')),
      );
    }
  }

  void _showGameDetails(GameAttachment game) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (game.coverUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      game.coverUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) =>
                          Container(color: DevColors.muted),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game.title,
                      style: DevTheme.display(size: 20, w: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded,
                        color: DevColors.mutedFg),
                  ),
                ],
              ),
              if (game.developer != null)
                Text(
                  'por ${game.developer}',
                  style: DevTheme.bodySecondary(size: 12),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (game.genre != null) _tagPill(game.genre!),
                  if (game.status != null) _tagPill(game.status!),
                  if (game.version != null) _tagPill(game.version!),
                ],
              ),
              if (game.description != null && game.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(game.description!, style: DevTheme.body(size: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DevColors.muted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DevColors.border),
      ),
      child: Text(label, style: DevTheme.body(size: 11, color: DevColors.mutedFg)),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DevColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE08A52), Color(0xFFB8502A)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_esports_rounded, color: DevColors.cream, size: 24),
            ),
            const SizedBox(width: 12),
            Text('DevPlay', style: DevTheme.display(size: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión 1.0.0 MVP', style: DevTheme.body(size: 14, w: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('La comunidad para devs indie y jugadores.', style: DevTheme.body(size: 13, color: DevColors.mutedFg)),
            const SizedBox(height: 16),
            const Divider(color: DevColors.border),
            const SizedBox(height: 8),
            _AboutRow(icon: Icons.code_rounded, label: 'Frontend', value: 'Flutter Web'),
            _AboutRow(icon: Icons.storage_rounded, label: 'Backend', value: 'FastAPI + PostgreSQL'),
            _AboutRow(icon: Icons.design_services_rounded, label: 'Diseño', value: 'Paleta cálida + Glassmorphism'),
            const SizedBox(height: 8),
            Text('Hecho con ❤️ para devs indie', style: DevTheme.body(size: 12, color: DevColors.mutedFg, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar', style: DevTheme.body(color: DevColors.mutedFg))),
        ],
      ),
    );
  }

  void _startTour() {
    final steps = [
      TourStep(targetKey: _heroKey, title: 'Hero Pixel-Art', description: 'Acceso rápido a crear contenido y juegos destacados.', icon: Icons.sports_esports_rounded),
      TourStep(targetKey: _tickerKey, title: 'Ticker de Juegos', description: 'Juegos trending en scroll horizontal infinito.', icon: Icons.videogame_asset_rounded),
      TourStep(targetKey: _feedKey, title: 'Feed Principal', description: 'Posts, betas y streams de la comunidad.', icon: Icons.feed_rounded),
      TourStep(targetKey: _createKey, title: 'Botón Crear', description: 'Publica posts, sube betas o crea encuestas.', icon: Icons.add_rounded),
      TourStep(targetKey: _sidebarKey, title: 'Navegación', description: 'Cambia entre Inicio, Betas, Chat, Tienda y más.', icon: Icons.menu_rounded),
    ];
    _TourOverlay(steps: steps).show(context);
  }

  void _openAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _sidebarBreakpoint;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                // Layout principal
                if (isDesktop)
                  Row(
                    children: [
                      // Sidebar fijo
                      DevSidebar(
                        currentView: _currentView,
                        onViewChanged: _onViewChanged,
                        onProfileTap: _openProfile,
                        onSettingsTap: _showAbout,
                        onCreatePost: _onCreatePost,
                        onCreateBeta: _onCreateBeta,
                        onCreatePoll: _onCreatePoll,
                        onStartTour: _onStartTour,
                        onLogout: _logout,
                        onOpenStore: _openStore,
                        onOpenReports: _openReports,
                        onShowAbout: _showAbout,
                      ),
                      // Contenido principal con header global
                      Expanded(
                        child: Column(
                          children: [
                            DevHeader(
                              unreadCount: _unread,
                              onNotificationsTap: _openNotifications,
                              onLogout: _logout,
                              onSearch: _searchUser,
                              showMenu: false,
                            ),
                            Expanded(child: _buildContent()),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Móvil: header global con botón de menú + contenido
                  Column(
                    children: [
                      DevHeader(
                        unreadCount: _unread,
                        onNotificationsTap: _openNotifications,
                        onLogout: _logout,
                        onMenuTap: _openDrawer,
                        onSearch: _searchUser,
                        showMenu: true,
                      ),
                      Expanded(child: _buildContent()),
                    ],
                  ),

                // Drawer móvil
                if (!isDesktop)
                  DevDrawer(
                    open: _drawerOpen,
                    onClose: _closeDrawer,
                    currentView: _currentView,
                    onViewChanged: _onViewChanged,
                    onProfileTap: _openProfile,
                    onCreatePost: _onCreatePost,
                    onCreateBeta: _onCreateBeta,
                    onCreatePoll: _onCreatePoll,
                    onStartTour: _onStartTour,
                    onOpenAuth: _openAuth,
                    onLogout: _logout,
                    onOpenStore: _openStore,
                    onOpenReports: _openReports,
                    onShowAbout: _showAbout,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    // Vista Betas: laboratorio de builds tempranas
    if (_currentView == ViewId.betas) {
      return BetasScreen(refreshToken: _betasVersion);
    }

    // Vista Chat Mundial: sala general en vivo + mensajes directos
    if (_currentView == ViewId.chat) {
      return ChatScreen(onOpenAuth: _openAuth);
    }

    // Vista Descubrir: pantalla dedicada con hero, carrusel, filtros y feed filtrado
    if (_currentView == ViewId.discover) {
      return DiscoverScreen(
        onCreateTap: _onCreatePost,
        onGameTap: (name) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name - pronto')),
          );
        },
      );
    }

    // Layout principal de Inicio — diseño PRD profesional
    return CustomScrollView(
      slivers: [
        // 1. HERO — identidad retro gamer de DevPlay
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: _HomeHero(
              onCreatePost: _onCreatePost,
              onExplore: () => _onViewChanged(ViewId.discover),
            ),
          ),
        ),

        // 2. Juegos recomendados — DISEÑO MEJORADO
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono y acción "Ver todos"
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DevColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.videogame_asset_rounded, size: 18, color: DevColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Juegos que deberías conocer',
                        style: DevTheme.display(size: 18, w: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onViewChanged(ViewId.discover),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Ver todos', style: DevTheme.body(size: 12, w: FontWeight.w600, color: DevColors.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: DevColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Fila de tarjetas de juegos (2 en desktop, 1 en móvil)
                if (_featuredGames.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DevColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DevColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.videogame_asset_outlined,
                          size: 32,
                          color: DevColors.mutedFg,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aún no hay juegos publicados',
                          style: DevTheme.body(size: 13, w: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comparte tu proyecto para aparecer aquí.',
                          style: DevTheme.bodySecondary(size: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _onCreatePost,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Publicar mi juego'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DevColors.primary,
                            side: const BorderSide(color: DevColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 800;
                      final gap = isWide ? 16.0 : 12.0;
                      final cardWidth = isWide
                          ? (constraints.maxWidth - gap) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: _featuredGames
                            .take(4)
                            .map((game) => SizedBox(
                                  width: cardWidth,
                                  child: _GameCard(
                                    game: game,
                                    onTap: () => _showGameDetails(game),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        // 3. Cuadro compacto para publicar — DISEÑO MEJORADO
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: DevColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DevColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila superior: avatar + texto clicable
                    Row(
                      children: [
                        // Avatar real del usuario en sesión
                        UserAvatar(
                          username:
                              context.watch<AuthProvider>().user?.username ??
                                  'dev',
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        // Texto clicable para crear publicación
                        Expanded(
                          child: InkWell(
                            onTap: _onCreatePost,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: DevColors.muted.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: DevColors.border),
                              ),
                              child: Text(
                                '¿Qué estás creando hoy?',
                                style: DevTheme.body(size: 13, color: DevColors.mutedFg),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: DevColors.border, height: 1),
                    const SizedBox(height: 12),
                    // Chips de tipos de contenido (Wrap responsive)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChipOption(
                          icon: Icons.text_fields,
                          label: 'Texto',
                          onTap: _onCreatePost,
                        ),
                        _ChipOption(
                          icon: Icons.image,
                          label: 'Imagen',
                          onTap: _onCreatePost,
                        ),
                        _ChipOption(
                          icon: Icons.video_library,
                          label: 'Video',
                          onTap: _onCreatePost,
                        ),
                        _ChipOption(
                          icon: Icons.code,
                          label: 'Avance',
                          onTap: _onCreatePost,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Feed de la comunidad — DISEÑO MEJORADO
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DevColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.forum_rounded, size: 18, color: DevColors.gold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Actividad de la comunidad',
                        style: DevTheme.display(size: 18, w: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Feed principal con publicaciones destacadas
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: DevColors.primary),
                    ),
                  )
                else if (_posts.isEmpty)
                  _EmptyState(
                    icon: _error != null
                        ? Icons.cloud_off_rounded
                        : Icons.article_outlined,
                    title: _error != null
                        ? 'No se pudo cargar el feed'
                        : 'Sin publicaciones',
                    description: _error != null
                        ? '¿Está corriendo el backend en :8000?'
                        : 'Sé el primero en compartir algo.',
                    actionLabel: _error != null ? 'Reintentar' : 'Crear publicación',
                    onAction: _error != null ? _load : _onCreatePost,
                  )
                else
                  ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _showAllFeed
                            ? _posts.length
                            : (_posts.length > 5 ? 5 : _posts.length),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PostCard(
                            post: _posts[i],
                            onProfileTap: () {
                              final authorId = _posts[i].author?.id;
                              if (authorId == null) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: authorId),
                                ),
                              );
                            },
                            onGameTap: (name) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$name - detalles')),
                              );
                            },
                          ),
                        ),
                      ),
                // Botón "Ver todo el feed" con mejor diseño
                if (_posts.isNotEmpty && !_showAllFeed) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showAllFeed = true),
                      icon: const Icon(Icons.dynamic_feed_rounded, size: 16),
                      label: Text('Ver todo el feed', style: DevTheme.body(size: 13, w: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DevColors.primary,
                        side: BorderSide(color: DevColors.primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de juego individual para la sección "Juegos que deberías conocer".
class _GameCard extends StatelessWidget {
  final GameAttachment game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image con badge de estado
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: game.coverUrl != null
                        ? Image.network(
                            game.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: DevColors.muted,
                              child: Icon(Icons.image, color: DevColors.mutedFg, size: 32),
                            ),
                          )
                        : Container(
                            color: DevColors.muted,
                            child: Icon(Icons.videogame_asset_rounded, size: 32, color: DevColors.mutedFg),
                          ),
                  ),
                  // Badge de estado (arriba-derecha)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DevColors.background.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DevColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        (game.status ?? 'prototype').toUpperCase(),
                        style: DevTheme.labelCaps(size: 8, color: DevColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              // Info del juego
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: DevTheme.body(size: 14, w: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.category_rounded, size: 12, color: DevColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            game.genre ?? 'Sin género',
                            style: DevTheme.bodySecondary(size: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (game.developer != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 12, color: DevColors.mutedFg),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              game.developer!,
                              style: DevTheme.bodySecondary(size: 11, color: DevColors.mutedFg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Hero de Inicio — banner principal con identidad retro gamer de DevPlay.
class _HomeHero extends StatelessWidget {
  final VoidCallback onCreatePost;
  final VoidCallback onExplore;

  const _HomeHero({required this.onCreatePost, required this.onExplore});

  static Widget _pixel(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2419), Color(0xFF2A1F1A), Color(0xFF1F1714)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: DevColors.primary.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Resplandor cálido superior derecho
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DevColors.gold.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Trama de píxeles decorativa (esquina superior derecha)
          Positioned(
            top: 24,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _pixel(DevColors.gold, 10, 0.45),
                    const SizedBox(width: 6),
                    _pixel(DevColors.primary, 10, 0.55),
                    const SizedBox(width: 6),
                    _pixel(DevColors.gold, 6, 0.30),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pixel(DevColors.primary, 6, 0.35),
                    const SizedBox(width: 6),
                    _pixel(DevColors.gold, 10, 0.55),
                    const SizedBox(width: 6),
                    _pixel(DevColors.primary, 10, 0.35),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pixel(DevColors.gold, 6, 0.25),
                    const SizedBox(width: 6),
                    _pixel(DevColors.primary, 6, 0.30),
                    const SizedBox(width: 6),
                    _pixel(DevColors.gold, 10, 0.45),
                  ],
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 560;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de sección
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DevColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: DevColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: DevColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'COMUNIDAD INDIE · DESARROLLO EN PÚBLICO',
                            style: DevTheme.labelCaps(size: 10, color: DevColors.goldSoft),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Título con degradado
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [DevColors.foreground, DevColors.goldSoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(r),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'Tu próximo proyecto\nempieza aquí',
                        style: DevTheme.display(size: wide ? 40 : 28, w: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        'Publica avances de tu juego, comparte betas y encuentra testers '
                        'en una comunidad hecha para desarrolladores.',
                        style: DevTheme.body(
                          size: wide ? 15 : 13.5,
                          color: DevColors.mutedFg,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Píldoras de características
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _HeroFeature(icon: Icons.auto_awesome_rounded, label: 'Publica avances'),
                        _HeroFeature(icon: Icons.science_rounded, label: 'Comparte betas'),
                        _HeroFeature(icon: Icons.people_alt_rounded, label: 'Encuentra testers'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Acciones principales — responsive
                    if (wide)
                      Row(
                        children: [
                          _primaryCta(),
                          const SizedBox(width: 12),
                          _secondaryCta(),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(width: double.infinity, child: _primaryCta()),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: _secondaryCta()),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta() {
    return ElevatedButton.icon(
      onPressed: onCreatePost,
      icon: const Icon(Icons.add_chart_rounded, size: 20),
      label: Text(
        'Crear publicación',
        style: DevTheme.body(size: 14, w: FontWeight.w700, color: DevColors.primaryFg),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: DevColors.primary,
        foregroundColor: DevColors.primaryFg,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Widget _secondaryCta() {
    return OutlinedButton.icon(
      onPressed: onExplore,
      icon: const Icon(Icons.explore_rounded, size: 20),
      label: Text(
        'Explorar juegos',
        style: DevTheme.body(size: 14, w: FontWeight.w700, color: DevColors.goldSoft),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: DevColors.goldSoft,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        side: BorderSide(color: DevColors.gold.withValues(alpha: 0.6), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}

/// Píldora de característica del hero.
class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DevColors.white08,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DevColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DevColors.primary),
          const SizedBox(width: 7),
          Text(label, style: DevTheme.body(size: 12, w: FontWeight.w600, color: DevColors.foreground)),
        ],
      ),
    );
  }
}

/// Chip seleccional para los tipos de contenido en el cuadro de publicar.
class _ChipOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChipOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DevColors.muted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DevColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: DevColors.primary),
            const SizedBox(width: 6),
            Text(label, style: DevTheme.body(size: 11, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío para pantallas sin contenido
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
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
        ),
      ),
    );
  }
}

/// Fila de detalle para el diálogo "Acerca de".
class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DevColors.primary),
          const SizedBox(width: 10),
          Text(label, style: DevTheme.body(size: 13, color: DevColors.mutedFg)),
          const Spacer(),
          Text(value, style: DevTheme.body(size: 13, w: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Dock "Crear" (bottom-center): abre un sheet con las opciones de contenido
/// y las crea vía `POST /posts`.
class _CreateDock extends StatelessWidget {
  final VoidCallback onCreated;
  final bool startWithPoll;

  const _CreateDock({required this.onCreated, this.startWithPoll = false});

  Future<void> _open(BuildContext context) async {
    if (startWithPoll) {
      await _openPollComposer(context);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Crear contenido', style: DevTheme.display(size: 16)),
              ),
            ),
            const SizedBox(height: 6),
            _Option(
              icon: Icons.article_outlined,
              iconColor: DevColors.primary,
              label: 'Publicar Post',
              type: 'POST',
            ),
            _Option(
              icon: Icons.sports_esports_rounded,
              iconColor: DevColors.amber,
              label: 'Subir Beta',
              type: 'BETA',
            ),
            _Option(
              icon: Icons.videocam_outlined,
              iconColor: DevColors.wine,
              label: 'Subir Stream',
              type: 'STREAM',
            ),
            _Option(
              icon: Icons.insights_rounded,
              iconColor: DevColors.consoleGreen,
              label: 'Registro de desarrollo',
              type: 'DEV_LOG',
            ),
            _Option(
              icon: Icons.poll_outlined,
              iconColor: DevColors.gold,
              label: 'Crear encuesta',
              type: 'POLL',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (action != null && context.mounted) {
      // Las betas usan su propio formulario (crea ficha + post en el backend).
      if (action == 'BETA') {
        final created = await showBetaComposeSheet(context);
        if (created == true) {
          onCreated();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Beta publicada!')),
            );
          }
        }
        return;
      }
      if (action == 'POLL') {
        await _openPollComposer(context);
        return;
      }
      final content = await showDialog<String>(
        context: context,
        builder: (ctx) => _ComposeDialog(type: action),
      );
      if (content != null && content.isNotEmpty && context.mounted) {
        try {
          await PostService.createPost(content: content, type: action);
          onCreated();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Publicado!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$e')));
          }
        }
      }
    }
  }

  Future<void> _openPollComposer(BuildContext context) async {
    final draft = await showDialog<_PollDraft>(
      context: context,
      builder: (_) => const _PollComposeDialog(),
    );
    if (draft == null || !context.mounted) return;
    try {
      await PostService.createPoll(
        question: draft.question,
        options: draft.options,
        allowMultiple: draft.allowMultiple,
      );
      onCreated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Encuesta publicada!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear la encuesta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: DevTheme.btnGradient(),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: DevColors.gold.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Crear',
              style: DevTheme.body(
                size: 14,
                w: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollDraft {
  final String question;
  final List<String> options;
  final bool allowMultiple;

  const _PollDraft({
    required this.question,
    required this.options,
    required this.allowMultiple,
  });
}

class _PollComposeDialog extends StatefulWidget {
  const _PollComposeDialog();

  @override
  State<_PollComposeDialog> createState() => _PollComposeDialogState();
}

class _PollComposeDialogState extends State<_PollComposeDialog> {
  final _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _multiple = false;
  String? _error;

  @override
  void dispose() {
    _question.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length >= 10) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() => _options.removeAt(index).dispose());
  }

  void _submit() {
    final question = _question.text.trim();
    final options = _options
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      setState(() => _error = 'Escribe la pregunta');
      return;
    }
    if (options.length < 2) {
      setState(() => _error = 'Añade al menos 2 opciones');
      return;
    }
    if (options.toSet().length != options.length) {
      setState(() => _error = 'Las opciones no pueden repetirse');
      return;
    }

    Navigator.pop(
      context,
      _PollDraft(
        question: question,
        options: options,
        allowMultiple: _multiple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DevColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Nueva encuesta', style: DevTheme.display(size: 16)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _question,
                autofocus: true,
                maxLength: 500,
                style: DevTheme.body(size: 13.5),
                decoration: _decoration('¿Qué quieres preguntar?'),
              ),
              const SizedBox(height: 6),
              ...List.generate(_options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _options[index],
                          maxLength: 200,
                          style: DevTheme.body(size: 13),
                          decoration: _decoration('Opción ${index + 1}'),
                        ),
                      ),
                      if (_options.length > 2)
                        IconButton(
                          tooltip: 'Quitar opción',
                          onPressed: () => _removeOption(index),
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 18, color: DevColors.destructive),
                        ),
                    ],
                  ),
                );
              }),
              if (_options.length < 10)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Añadir opción',
                      style: DevTheme.body(size: 12)),
                ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _multiple,
                activeThumbColor: DevColors.primary,
                title: Text('Permitir varios votos',
                    style: DevTheme.body(size: 12.5)),
                onChanged: (value) => setState(() => _multiple = value),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: DevTheme.body(size: 11.5, color: DevColors.destructive),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar',
              style: DevTheme.body(color: DevColors.mutedFg)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DevColors.primary,
            foregroundColor: DevColors.primaryFg,
            elevation: 0,
          ),
          child: const Text('Publicar'),
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: DevTheme.body(size: 12.5, color: DevColors.mutedFg),
        filled: true,
        fillColor: DevColors.cardRaised,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DevColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DevColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DevColors.primary),
        ),
      );
}

class _ComposeDialog extends StatefulWidget {
  final String type;
  const _ComposeDialog({required this.type});

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DevColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Nueva publicación', style: DevTheme.display(size: 16)),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        style: DevTheme.body(size: 14),
        decoration: InputDecoration(
          hintText: '¿Qué está pasando en tu proyecto?',
          hintStyle: DevTheme.body(size: 13, color: DevColors.mutedFg),
          filled: true,
          fillColor: DevColors.cardRaised,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: DevColors.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: DevTheme.body(color: DevColors.mutedFg)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: DevColors.primary,
            foregroundColor: DevColors.primaryFg,
          ),
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String type;

  const _Option({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, type),
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

/// Paso del tour guiado.
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Overlay del tour guiado: resalta el widget objetivo (si está montado)
/// y muestra una tarjeta con título/descripción y navegación.
class _TourOverlay {
  final List<TourStep> steps;

  _TourOverlay({required this.steps});

  void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tour',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _TourContent(steps: steps),
    );
  }
}

class _TourContent extends StatefulWidget {
  final List<TourStep> steps;
  const _TourContent({required this.steps});

  @override
  State<_TourContent> createState() => _TourContentState();
}

class _TourContentState extends State<_TourContent> {
  int _index = 0;

  Rect? _targetRect() {
    final ctx = widget.steps[_index].targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _next() {
    if (_index < widget.steps.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final rect = _targetRect();
    final size = MediaQuery.of(context).size;

    const cardWidth = 320.0;
    double cardLeft = (size.width - cardWidth) / 2;
    double cardTop = size.height / 2 - 80;

    if (rect != null) {
      cardLeft = rect.left.clamp(16.0, (size.width - cardWidth - 16).clamp(16.0, size.width));
      final below = rect.bottom + 16;
      cardTop = below + 170 > size.height ? (rect.top - 186) : below;
      if (cardTop < 16) cardTop = 16;
    }

    return Stack(
      children: [
        // Anillo resaltado alrededor del objetivo
        if (rect != null)
          Positioned(
            left: rect.left - 6,
            top: rect.top - 6,
            child: IgnorePointer(
              child: Container(
                width: rect.width + 12,
                height: rect.height + 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DevColors.gold, width: 2),
                  boxShadow: [
                    BoxShadow(color: DevColors.gold.withValues(alpha: 0.35), blurRadius: 18),
                  ],
                ),
              ),
            ),
          ),
        // Tarjeta del paso
        Positioned(
          left: cardLeft,
          top: cardTop,
          width: cardWidth,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DevColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DevColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: DevColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(step.icon, size: 18, color: DevColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(step.title, style: DevTheme.display(size: 15, w: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(step.description, style: DevTheme.bodySecondary(size: 13)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${_index + 1} / ${widget.steps.length}',
                        style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                      ),
                      const Spacer(),
                      if (_index > 0)
                        TextButton(
                          onPressed: _prev,
                          child: Text('Atrás', style: DevTheme.body(size: 13, color: DevColors.mutedFg)),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text('Saltar', style: DevTheme.body(size: 13, color: DevColors.mutedFg)),
                      ),
                      ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DevColors.primary,
                          foregroundColor: DevColors.primaryFg,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _index < widget.steps.length - 1 ? 'Siguiente' : 'Listo',
                          style: DevTheme.body(size: 13, w: FontWeight.w600, color: DevColors.primaryFg),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}