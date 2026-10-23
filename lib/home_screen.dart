import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/navigation.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../screens/about_screen.dart';
import '../screens/betas_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/search_screen.dart';
import '../services/media_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/dev_link.dart';
import '../widgets/avatar.dart';
import '../widgets/beta_compose_sheet.dart';
import '../widgets/drawer.dart';
import '../widgets/header.dart';
import '../widgets/hero_3d_shapes.dart';
import '../widgets/hero_video.dart';
import '../widgets/post_card.dart';
import '../widgets/sidebar.dart';
import '../widgets/tour_spotlight.dart';

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
  final _gamesKey = GlobalKey();
  final _feedKey = GlobalKey();
  final _createKey = GlobalKey();
  final _sidebarKey = GlobalKey();
  final _headerKey = GlobalKey();
  final _tourHelpKey = GlobalKey();
  final _homeScrollController = ScrollController();
  final _inlinePostController = TextEditingController();
  final _inlinePostFocusNode = FocusNode();
  String _selectedContentType = 'Texto';
  bool _isSubmittingInlinePost = false;
  String _activeFeedTab = 'Recientes';

  @override
  void initState() {
    super.initState();
    _load();
    _openDeepLink();
  }

  /// Abre el perfil indicado en la URL (`?user=usuario`) al entrar en la app.
  ///
  /// Es lo que hace que el enlace copiado desde "Compartir perfil" lleve al
  /// perfil correcto. Si el usuario no existe, se avisa y se sigue en Inicio.
  Future<void> _openDeepLink() async {
    final username = DevLink.currentUsername();
    if (username == null || username.isEmpty) return;
    final id = await DevLink.resolveUserId(username);
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No existe el usuario @$username')),
      );
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: id)));
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _inlinePostController.dispose();
    _inlinePostFocusNode.dispose();
    super.dispose();
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
          sort = 'latest'; // cronológico
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
            .map(_gameFromPost)
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
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    if (mounted) {
      try {
        _unread = await UserService.getUnreadCount();
        setState(() {});
      } catch (_) {
        // sin sesión: se ignora
      }
    }
  }

  Future<void> _openProfile([int initialTab = 0]) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: user.id,
            initialTab: initialTab,
            onCreatePost: _onCreatePost,
          ),
        ),
      );
      if (mounted) _load();
    }
  }

  /// Abre el perfil propio en modo ajustes (editar perfil / preferencias).
  ///
  /// Antes el engranaje del sidebar abría "Acerca de DevPlay", lo que
  /// confundía: pulsar el perfil te llevaba a la pantalla equivocada.
  Future<void> _openProfileSettings() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: user.id,
          openSettings: true,
          onCreatePost: _onCreatePost,
        ),
      ),
    );
    if (mounted) _load();
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

  void _scrollToCreateBox() {
    if (_currentView != ViewId.explore) {
      _onViewChanged(ViewId.explore);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_createKey.currentContext != null) {
        Scrollable.ensureVisible(
          _createKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
        _inlinePostFocusNode.requestFocus();
      } else {
        _onCreatePost();
      }
    });
  }

  Future<void> _submitInlinePost() async {
    final text = _inlinePostController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo antes de publicar.')),
      );
      _inlinePostFocusNode.requestFocus();
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || (auth.user?.isGuest ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para publicar en la comunidad.')),
      );
      return;
    }

    setState(() => _isSubmittingInlinePost = true);
    try {
      await PostService.createPost(content: text, type: 'POST');
      _inlinePostController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicación creada con éxito!')),
      );
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingInlinePost = false);
    }
  }

  /// Abre el compositor completo (texto + imágenes/vídeos) y publica.
  Future<void> _openComposer(String type) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || (auth.user?.isGuest ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para publicar en la comunidad.')),
      );
      return;
    }

    final draft = await showDialog<_ComposeResult>(
      context: context,
      builder: (_) => _ComposeDialog(type: type),
    );
    if (draft == null || !mounted) return;
    if (draft.content.isEmpty && draft.media.isEmpty) return;

    try {
      await PostService.createPost(
        content: draft.content,
        type: type,
        media: draft.media,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $e')),
      );
    }
  }

  List<Post> get _filteredPosts {
    if (_activeFeedTab == 'Destacados') {
      final list = List<Post>.from(_posts);
      list.sort((a, b) => (b.likesCount + b.commentsCount).compareTo(a.likesCount + a.commentsCount));
      return list;
    } else if (_activeFeedTab == 'Siguiendo') {
      return _posts.where((p) => p.author?.username != null).toList();
    }
    return _posts;
  }

  Widget _buildGameSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: DevColors.cardRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DevColors.border.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: DevColors.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.sports_esports_outlined, size: 14, color: DevColors.mutedFg),
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: DevColors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: DevColors.muted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab(String label, IconData icon) {
    final active = _activeFeedTab == label;
    return InkWell(
      onTap: () => setState(() => _activeFeedTab = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? DevColors.primary.withValues(alpha: 0.15)
              : DevColors.cardRaised.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? DevColors.primary : DevColors.border,
            width: active ? 1.5 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: DevColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? DevColors.primary : DevColors.mutedFg,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: DevTheme.body(
                size: 12,
                w: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? DevColors.primary : DevColors.mutedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCreatePost() async {
    await _CreateDock(onCreated: _load)._open(context);
  }

  Future<void> _onCreateBeta() async {
    final created = await showBetaComposeSheet(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('¡Beta publicada!')));
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
                    colors: [Color(0xFF6D28D9), Color(0xFF0EA5E9)],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DevColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: DevColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'NO DISPONIBLE',
                  style: DevTheme.labelCaps(
                    size: 9.5,
                    color: DevColors.goldSoft,
                  ),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  /// Convierte un showcase en tarjeta de juego. La API todavía no manda el
  /// objeto `game`, así que se deriva del post (título, portada y beta).
  GameAttachment? _gameFromPost(Post post) {
    if (post.game != null) return post.game;
    final beta = post.beta;
    final firstLine = post.content.trim().split('\n').first.trim();
    // Los showcases sembrados llevan "Titulo · Genero · vX.Y.Z" en la 1a linea.
    final parts = firstLine.split('·').map((s) => s.trim()).toList();
    final title = (beta?.title ?? parts.first).trim();
    if (title.isEmpty) return null;
    final genre = beta?.genre ?? (parts.length >= 2 && parts[1].isNotEmpty ? parts[1] : null);
    final version = beta?.version ??
        (parts.length >= 3 ? parts[2].replaceFirst('v', '') : null);
    return GameAttachment(
      id: post.id,
      title: title,
      coverUrl: post.media.isNotEmpty ? post.media.first.url : null,
      description: post.content.trim(),
      developer: post.author?.fullName ?? post.author?.username,
      genre: genre,
      version: version,
      status: (beta?.isOpen ?? false) ? 'Beta abierta' : null,
      viewsCount: post.likesCount,
    );
  }

  /// Abre el buscador global (juegos, usuarios y publicaciones).
  void _openSearch(String raw) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: raw.trim()),
      ),
    );
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
                    icon: const Icon(
                      Icons.close_rounded,
                      color: DevColors.mutedFg,
                    ),
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
      child: Text(
        label,
        style: DevTheme.body(size: 11, color: DevColors.mutedFg),
      ),
    );
  }

  void _showAbout() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<void> _startTour() async {
    // El tour explica la pantalla de Inicio. Si se lanza desde otra vista,
    // primero volvemos a Inicio y esperamos a que se monte su contenido.
    if (_currentView != ViewId.explore) {
      setState(() => _currentView = ViewId.explore);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    // El tour empieza por el hero. Volvemos arriba para que todos los pasos
    // (incluida la caja de publicar) estén montados y se puedan medir.
    if (_homeScrollController.hasClients && _homeScrollController.offset > 0) {
      _homeScrollController.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= _sidebarBreakpoint;
    final steps = <TourStep>[
      TourStep(
        targetKey: _heroKey,
        title: 'Bienvenido a DevPlay',
        description: 'Este es tu punto de partida: descubre la comunidad, crea contenido y encuentra nuevos proyectos indie.',
        icon: Icons.sports_esports_rounded,
      ),
      TourStep(
        targetKey: _gamesKey,
        title: 'Juegos que deberías conocer',
        description: 'Aquí aparecen los proyectos y showcases publicados por la comunidad. Abre una tarjeta para ver sus detalles.',
        icon: Icons.videogame_asset_rounded,
      ),
      TourStep(
        targetKey: _createKey,
        title: 'Publica en segundos',
        description: 'Desde este cuadro puedes compartir un post, una imagen, un avance o una encuesta con la comunidad.',
        icon: Icons.edit_note_rounded,
      ),
      TourStep(
        targetKey: _feedKey,
        title: 'Actividad de la comunidad',
        description: 'El feed reúne publicaciones, betas y devlogs. Usa los botones de cada tarjeta para reaccionar, guardar o comentar.',
        icon: Icons.forum_rounded,
        focusMinHeight: 260,
      ),
      TourStep(
        targetKey: isDesktop ? _sidebarKey : _headerKey,
        title: isDesktop ? 'Navegación lateral' : 'Menú principal',
        description: isDesktop
            ? 'Cambia entre Inicio, Betas, Chat Mundial y Tienda. La sección de ayuda incluye este tour cuando quieras repetirlo.'
            : 'Toca el menú para moverte entre Inicio, Betas, Chat Mundial y Tienda. También puedes repetir este tour desde Ayuda.',
        icon: Icons.menu_rounded,
      ),
      if (isDesktop)
        TourStep(
          targetKey: _tourHelpKey,
          title: 'Ayuda y tour guiado',
          description: 'Aquí puedes repetir este tour cuando quieras y abrir los términos, la privacidad y las normas de la comunidad.',
          icon: Icons.tour_rounded,
        ),
    ];

    _TourOverlay(steps: steps).show(context);
  }

  void _openAuth() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                        key: _sidebarKey,
                        helpTourKey: _tourHelpKey,
                        currentView: _currentView,
                        onViewChanged: _onViewChanged,
                        onSettingsTap: _openProfileSettings,
                        onProfileTap: _openProfile,
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
                              key: _headerKey,
                              unreadCount: _unread,
                              onNotificationsTap: _openNotifications,
                              onLogout: _logout,
                              onSearch: _openSearch,
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
                        key: _headerKey,
                        unreadCount: _unread,
                        onNotificationsTap: _openNotifications,
                        onLogout: _logout,
                        onMenuTap: _openDrawer,
                        onSearch: _openSearch,
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
                    onProfileTap: (tab) => _openProfile(tab),
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$name - pronto')));
        },
      );
    }



    // Layout principal de Inicio — diseño PRD profesional.
    // cacheExtent alto: el tour necesita que las secciones de abajo ya estén
    // montadas para poder medirlas y hacer scroll hasta ellas.
    return CustomScrollView(
      controller: _homeScrollController,
      scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
      slivers: [
        // 1. HERO — identidad retro gamer de DevPlay
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: _HomeHero(
              key: _heroKey,
              onCreatePost: _scrollToCreateBox,
              onExplore: () => _onViewChanged(ViewId.discover),
            ),
          ),
        ),

        // 2. Juegos recomendados — DISEÑO MEJORADO
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              key: _gamesKey,
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
                      child: Icon(
                        Icons.videogame_asset_rounded,
                        size: 18,
                        color: DevColors.primary,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver todos',
                            style: DevTheme.body(
                              size: 12,
                              w: FontWeight.w600,
                              color: DevColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: DevColors.primary,
                          ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DevColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DevColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: DevColors.accentOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '¡Espacio disponible!',
                                      style: DevTheme.body(
                                        size: 10,
                                        w: FontWeight.w700,
                                        color: DevColors.accentOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aún no hay juegos publicados',
                                style: DevTheme.body(size: 12, w: FontWeight.w700),
                              ),
                              Text(
                                'Sé el primero en compartir tu proyecto aquí.',
                                style: DevTheme.bodySecondary(size: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _onCreateBeta,
                                icon: const Icon(Icons.sports_esports_rounded, size: 14),
                                label: const Text('Publicar mi juego'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DevColors.accentOrange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: DevTheme.body(size: 11, w: FontWeight.w700),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 72,
                            child: Row(
                              children: [
                                Expanded(child: _buildGameSkeletonCard()),
                                const SizedBox(width: 8),
                                Expanded(child: _buildGameSkeletonCard()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 620 ? 2 : 1;
                      final gap = columns == 1 ? 0.0 : 12.0;
                      final cardWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: _featuredGames
                            .take(6)
                            .map(
                              (game) => SizedBox(
                                width: cardWidth,
                                child: _GameCard(
                                  game: game,
                                  onTap: () => _showGameDetails(game),
                                ),
                              ),
                            )
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
              key: _createKey,
              decoration: BoxDecoration(
                color: DevColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DevColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila superior: avatar + campo de texto interactivo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          username:
                              context.watch<AuthProvider>().user?.username ??
                              'dev',
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: DevColors.cardRaised,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _inlinePostFocusNode.hasFocus
                                    ? DevColors.accentOrange
                                    : DevColors.border,
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: TextField(
                              controller: _inlinePostController,
                              focusNode: _inlinePostFocusNode,
                              maxLines: 3,
                              minLines: 1,
                              style: DevTheme.body(
                                size: 13,
                                color: DevColors.foreground,
                              ),
                              decoration: InputDecoration(
                                hintText: _selectedContentType == 'Texto'
                                    ? '¿Qué estás creando hoy? Comparte tus avances…'
                                    : _selectedContentType == 'Imagen'
                                    ? 'Escribe sobre la captura o arte de tu juego…'
                                    : _selectedContentType == 'Video'
                                    ? 'Describe el gameplay o trailer que vas a compartir…'
                                    : 'Comparte el log de desarrollo o avance técnico…',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: DevColors.border, height: 1),
                    const SizedBox(height: 10),
                    // Fila inferior: Chips de tipo con estado activo y Botón explícito de Publicar
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ChipOption(
                                icon: Icons.text_fields,
                                label: 'Texto',
                                isSelected: _selectedContentType == 'Texto',
                                onTap: () => setState(() => _selectedContentType = 'Texto'),
                              ),
                              _ChipOption(
                                icon: Icons.image,
                                label: 'Imagen',
                                isSelected: _selectedContentType == 'Imagen',
                                onTap: () {
                                  setState(() => _selectedContentType = 'Imagen');
                                  _openComposer('POST');
                                },
                              ),
                              _ChipOption(
                                icon: Icons.video_library,
                                label: 'Video',
                                isSelected: _selectedContentType == 'Video',
                                onTap: () {
                                  setState(() => _selectedContentType = 'Video');
                                  _openComposer('POST');
                                },
                              ),
                              _ChipOption(
                                icon: Icons.code,
                                label: 'Avance',
                                isSelected: _selectedContentType == 'Avance',
                                onTap: () => setState(() => _selectedContentType = 'Avance'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSubmittingInlinePost ? null : _submitInlinePost,
                          icon: _isSubmittingInlinePost
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 15),
                          label: Text(
                            'Publicar',
                            style: DevTheme.body(
                              size: 12,
                              w: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DevColors.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            elevation: 2,
                            shadowColor: DevColors.accentOrange.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
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
                // Header con icono y selector de secciones / tabs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      key: _feedKey,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: DevColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.forum_rounded,
                            size: 18,
                            color: DevColors.gold,
                          ),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFeedTab('Recientes', Icons.access_time_rounded),
                          const SizedBox(width: 8),
                          _buildFeedTab('Destacados', Icons.local_fire_department_rounded),
                          const SizedBox(width: 8),
                          _buildFeedTab('Siguiendo', Icons.people_outline_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Feed principal filtrado
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DevColors.primary,
                      ),
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
                    actionLabel: _error != null
                        ? 'Reintentar'
                        : 'Crear publicación',
                    onAction: _error != null ? _load : _scrollToCreateBox,
                  )
                else
                  Builder(
                    builder: (context) {
                      final displayPosts = _filteredPosts;
                      if (displayPosts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              _activeFeedTab == 'Siguiendo'
                                  ? 'Aún no sigues a ningún creador.'
                                  : 'Sin publicaciones en esta sección.',
                              style: DevTheme.bodySecondary(size: 13),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _showAllFeed
                            ? displayPosts.length
                            : (displayPosts.length > 5 ? 5 : displayPosts.length),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PostCard(
                            post: displayPosts[i],
                            onProfileTap: () {
                              final authorId = displayPosts[i].author?.id;
                              if (authorId == null) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: authorId),
                                ),
                              );
                            },
                            onGameTap: (name) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('\ - detalles')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                if (_posts.isNotEmpty && !_showAllFeed) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showAllFeed = true),
                      icon: const Icon(Icons.dynamic_feed_rounded, size: 16),
                      label: Text(
                        'Ver todo el feed',
                        style: DevTheme.body(size: 13, w: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DevColors.primary,
                        side: BorderSide(
                          color: DevColors.primary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
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
    final cover = game.coverUrl ?? '';
    final status = (game.status ?? '').trim();
    final meta = [
      if ((game.genre ?? '').isNotEmpty) game.genre!,
      if ((game.version ?? '').isNotEmpty) 'v${game.version}',
    ].join(' \u00b7 ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: DevColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DevColors.border),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 92,
                  height: 76,
                  child: cover.isEmpty
                      ? _fallback()
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallback(),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.isEmpty ? 'Juego de la comunidad' : meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DevTheme.bodySecondary(size: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 11,
                          color: DevColors.mutedFg,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            (game.developer ?? '').trim().isEmpty
                                ? 'DevPlay'
                                : game.developer!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DevTheme.bodySecondary(size: 10.5),
                          ),
                        ),
                        if (status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: DevColors.accentCyan.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: DevTheme.labelCaps(
                                size: 7.5,
                                color: DevColors.accentCyan,
                              ),
                            ),
                          ),
                      ],
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
    );
  }

  Widget _fallback() {
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
          color: DevColors.accentCyan.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

/// Hero de Inicio — banner principal con identidad retro gamer de DevPlay.
class _HomeHero extends StatelessWidget {
  final VoidCallback onCreatePost;
  final VoidCallback onExplore;

  const _HomeHero({
    super.key,
    required this.onCreatePost,
    required this.onExplore,
  });

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
          colors: [Color(0xFF0A101D), Color(0xFF0F172A), Color(0xFF0A101D)],
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
          // Video 3D en loop. El asset ya viene ligeramente desenfocado para
          // que no compita con el texto y para que el hero no pierda fluidez.
          // El propio HeroVideo ya superpone el adorno 3D (Hero3DShapes).
          Positioned.fill(
            child: HeroVideo(
              videoAsset: 'assets/videos/hero_loop_crystal_loop',
              posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
              autoPlay: true,
              mute: true,
              shapeOpacity: 0.35,
              shapeStyle: Hero3DStyle.home,
              enablePointerInterceptor: true,
              scrimOpacity: 0.26,
            ),
          ),
          // Panel de cristal sobre la zona del texto. Deja respirar el video
          // en la derecha y mantiene legible el contenido de la izquierda.
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // En pantallas estrechas el panel cubre todo el ancho para
                  // que el texto nunca quede sobre la parte más brillante.
                  final wide = constraints.maxWidth >= 760;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: wide ? 0.70 : 1.0,
                      heightFactor: 1.0,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x8C060B14),
                              Color(0x59060B14),
                              Color(0x00060B14),
                            ],
                            stops: [0.0, 0.58, 1.0],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.09),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Velo cálido muy suave: unifica el video con la paleta sin apagarlo.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0x2E060B14),
                      const Color(0x1A060B14),
                      const Color(0x0D060B14),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Sombra vertical suave para separar el hero del feed.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x1F060B14),
                      Colors.transparent,
                      const Color(0x66060B14),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DevColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: DevColors.gold.withValues(alpha: 0.4),
                        ),
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
                            style: DevTheme.labelCaps(
                              size: 10,
                              color: DevColors.goldSoft,
                            ),
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
                        style: DevTheme.display(
                          size: wide ? 40 : 28,
                          w: FontWeight.w800,
                        ),
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
                        _HeroFeature(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Publica avances',
                        ),
                        _HeroFeature(
                          icon: Icons.science_rounded,
                          label: 'Comparte betas',
                        ),
                        _HeroFeature(
                          icon: Icons.people_alt_rounded,
                          label: 'Encuentra testers',
                        ),
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
                          SizedBox(
                            width: double.infinity,
                            child: _primaryCta(),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _secondaryCta(),
                          ),
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
        style: DevTheme.body(
          size: 14,
          w: FontWeight.w700,
          color: DevColors.primaryFg,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: DevColors.accentOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        elevation: 0,
        shadowColor: DevColors.accentOrange.withValues(alpha: 0.4),
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
        style: DevTheme.body(
          size: 14,
          w: FontWeight.w700,
          color: DevColors.goldSoft,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: DevColors.goldSoft,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        side: BorderSide(
          color: DevColors.gold.withValues(alpha: 0.6),
          width: 2,
        ),
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
          Text(
            label,
            style: DevTheme.body(
              size: 12,
              w: FontWeight.w600,
              color: DevColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip seleccional para los tipos de contenido en el cuadro de publicar.
class _ChipOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DevColors.accentOrange.withValues(alpha: 0.16)
              : DevColors.muted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DevColors.accentOrange : DevColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DevColors.accentOrange.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? DevColors.accentOrange : DevColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: DevTheme.body(
                size: 11,
                w: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? DevColors.accentOrange : DevColors.foreground,
              ),
            ),
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
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: Text(
                actionLabel,
                style: DevTheme.body(size: 13, w: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DevColors.primary,
                side: const BorderSide(color: DevColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
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
                child: Text(
                  'Crear contenido',
                  style: DevTheme.display(size: 16),
                ),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('¡Beta publicada!')));
          }
        }
        return;
      }
      if (action == 'POLL') {
        await _openPollComposer(context);
        return;
      }
      final draft = await showDialog<_ComposeResult>(
        context: context,
        builder: (ctx) => _ComposeDialog(type: action),
      );
      if (draft != null && context.mounted) {
        if (draft.content.isEmpty && draft.media.isEmpty) return;
        try {
          await PostService.createPost(
            content: draft.content,
            type: action,
            media: draft.media,
          );
          onCreated();
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('¡Publicado!')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Encuesta publicada!')));
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
          color: DevColors.accentOrange,
          borderRadius: BorderRadius.circular(999),
          boxShadow: DevColors.orangeGlow(),
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

    if (question.length < 3) {
      setState(() => _error = 'Escribe una pregunta (mínimo 3 letras)');
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

  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: DevTheme.body(size: 12.5, color: DevColors.disabled),
      filled: true,
      fillColor: DevColors.background.withValues(alpha: 0.5),
      isDense: true,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(DevColors.border),
      enabledBorder: border(DevColors.border),
      focusedBorder: border(DevColors.accentCyan.withValues(alpha: 0.7), 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: DevColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DevColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: DevColors.gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: DevColors.gold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.poll_rounded,
                        size: 16,
                        color: DevColors.gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva encuesta',
                            style: DevTheme.display(
                              size: 16,
                              w: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Pregunta a la comunidad en el feed',
                            style: DevTheme.bodySecondary(size: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: DevColors.mutedFg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _question,
                  autofocus: true,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  style: DevTheme.body(size: 13.5, height: 1.4),
                  cursorColor: DevColors.accentCyan,
                  decoration: _decoration('¿Qué quieres preguntar?'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('OPCIONES', style: DevTheme.labelCaps(size: 9)),
                    const SizedBox(width: 6),
                    Text(
                      '${_options.length}/10',
                      style: DevTheme.bodySecondary(size: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DevColors.cardRaised,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: DevColors.border),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: DevTheme.body(
                              size: 10.5,
                              w: FontWeight.w700,
                              color: DevColors.mutedFg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _options[index],
                            maxLength: 120,
                            style: DevTheme.body(size: 13),
                            cursorColor: DevColors.accentCyan,
                            decoration: _decoration('Opción ${index + 1}'),
                          ),
                        ),
                        if (_options.length > 2)
                          IconButton(
                            tooltip: 'Quitar opción',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _removeOption(index),
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 18,
                              color: DevColors.destructive,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (_options.length < 10)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'Añadir opción',
                      style: DevTheme.body(
                        size: 12.5,
                        w: FontWeight.w600,
                        color: DevColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: DevColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 34),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
                  decoration: BoxDecoration(
                    color: DevColors.background.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: DevColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.how_to_vote_rounded,
                        size: 15,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Permitir varios votos',
                          style: DevTheme.body(size: 12.5),
                        ),
                      ),
                      Switch.adaptive(
                        value: _multiple,
                        activeThumbColor: DevColors.primary,
                        onChanged: (value) =>
                            setState(() => _multiple = value),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: DevColors.destructive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DevColors.destructive.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: DevTheme.body(
                        size: 12,
                        color: DevColors.destructive,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: DevTheme.body(
                          size: 13,
                          color: DevColors.mutedFg,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C8E0), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _submit,
                            borderRadius: BorderRadius.circular(11),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.send_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Publicar',
                                    style: DevTheme.body(
                                      size: 13,
                                      w: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposeDialog extends StatefulWidget {
  final String type;
  const _ComposeDialog({required this.type});

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  final _controller = TextEditingController();

  /// Archivos ya subidos (URL pública + tipo) adjuntos a la publicación.
  final List<Map<String, String>> _media = [];
  bool _uploading = false;

  static const int _maxMedia = 4;
  static const int _maxChars = 5000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case 'STREAM':
        return 'Nuevo directo';
      case 'DEV_LOG':
        return 'Nueva bitácora';
      default:
        return 'Nueva publicación';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case 'STREAM':
        return Icons.videocam_rounded;
      case 'DEV_LOG':
        return Icons.code_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  Color get _accent {
    switch (widget.type) {
      case 'STREAM':
        return DevColors.wine;
      case 'DEV_LOG':
        return DevColors.consoleGreen;
      default:
        return DevColors.primary;
    }
  }

  bool get _canPublish =>
      _controller.text.trim().isNotEmpty || _media.isNotEmpty;

  /// Sube un archivo del dispositivo y lo adjunta a la publicación.
  Future<void> _attach({required bool video}) async {
    if (_uploading || _media.length >= _maxMedia) return;
    setState(() => _uploading = true);
    try {
      final uploaded = await MediaService.pickAndUpload(allowVideo: video);
      if (!mounted) return;
      if (uploaded != null) {
        setState(() {
          _media.add({'url': uploaded.url, 'kind': uploaded.kind});
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo subir: $e'),
          backgroundColor: DevColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: DevTheme.body(size: 13, color: DevColors.disabled),
      filled: true,
      fillColor: DevColors.background.withValues(alpha: 0.5),
      isDense: true,
      counterText: '',
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      border: border(DevColors.border),
      enabledBorder: border(DevColors.border),
      focusedBorder: border(DevColors.accentCyan.withValues(alpha: 0.7), 1.5),
      errorBorder: border(DevColors.destructive.withValues(alpha: 0.6)),
      errorStyle: DevTheme.body(size: 11, color: DevColors.destructive),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: DevColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DevColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(_icon, size: 16, color: _accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: DevTheme.display(
                              size: 16,
                              w: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Se verá en tu perfil y en el feed',
                            style: DevTheme.bodySecondary(size: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: DevColors.mutedFg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Texto
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 6,
                  minLines: 4,
                  maxLength: _maxChars,
                  onChanged: (_) => setState(() {}),
                  style: DevTheme.body(size: 14, height: 1.45),
                  cursorColor: DevColors.accentCyan,
                  decoration: _fieldDecoration(
                    '¿Qué está pasando en tu proyecto?',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 13,
                      color: DevColors.mutedFg,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Sé concreto: qué avanzaste, qué probaste, qué falta.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.bodySecondary(size: 10.5),
                      ),
                    ),
                    Text(
                      '${_controller.text.length}/$_maxChars',
                      style: DevTheme.bodySecondary(size: 10.5),
                    ),
                  ],
                ),

                // Adjuntos
                if (_media.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'ADJUNTOS · ${_media.length}/$_maxMedia',
                    style: DevTheme.labelCaps(size: 9),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _media.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _thumbnail(i),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    _attachButton(
                      icon: Icons.image_outlined,
                      label: 'Imagen',
                      onTap: () => _attach(video: false),
                    ),
                    const SizedBox(width: 8),
                    _attachButton(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      onTap: () => _attach(video: true),
                    ),
                    if (_uploading) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Subiendo…',
                        style: DevTheme.bodySecondary(size: 11),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: DevTheme.body(
                          size: 13,
                          color: DevColors.mutedFg,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _canPublish && !_uploading
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF00C8E0),
                                    Color(0xFF3B82F6),
                                  ],
                                )
                              : null,
                          color: _canPublish && !_uploading
                              ? null
                              : DevColors.muted,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_canPublish && !_uploading)
                                ? () => Navigator.pop(
                                    context,
                                    _ComposeResult(
                                      content: _controller.text.trim(),
                                      media: List.of(_media),
                                    ),
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(11),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 16,
                                    color: _canPublish && !_uploading
                                        ? Colors.white
                                        : DevColors.disabled,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Publicar',
                                    style: DevTheme.body(
                                      size: 13,
                                      w: FontWeight.w700,
                                      color: _canPublish && !_uploading
                                          ? Colors.white
                                          : DevColors.disabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attachButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final enabled = !_uploading && _media.length < _maxMedia;
    return SizedBox(
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: DevColors.cardRaised.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DevColors.accentCyan.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: enabled ? DevColors.accentCyan : DevColors.disabled,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: DevTheme.body(
                    size: 12,
                    w: FontWeight.w600,
                    color: enabled ? DevColors.foreground : DevColors.disabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(int index) {
    final item = _media[index];
    final isVideo = item['kind'] == 'video';
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 84,
              height: 84,
              child: isVideo
                  ? Container(
                      color: DevColors.cardRaised,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          size: 26,
                          color: DevColors.accentCyan,
                        ),
                      ),
                    )
                  : Image.network(
                      item['url']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: DevColors.cardRaised,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 22,
                          color: DevColors.mutedFg,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () => setState(() => _media.removeAt(index)),
              child: const CircleAvatar(
                radius: 9,
                backgroundColor: Color(0xCC060B14),
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: DevColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resultado del dialogo de composicion: texto + archivos adjuntos.
class _ComposeResult {
  final String content;
  final List<Map<String, String>> media;

  const _ComposeResult({required this.content, required this.media});
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

  /// Altura mínima del área enfocada. Sirve para pasos cuyo objetivo natural
  /// es una franja pequeña (por ejemplo, el título del feed) pero que deben
  /// mostrar también su contenido inmediato.
  final double? focusMinHeight;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    this.focusMinHeight,
  });
}

/// Overlay del tour guiado: oscurece el fondo, ilumina el objetivo y muestra
/// una tarjeta contextual con navegación paso a paso.
class _TourOverlay {
  final List<TourStep> steps;

  _TourOverlay({required this.steps});

  void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Tour guiado',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _TourContent(steps: steps),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
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
  bool _moving = false;

  TourStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusStep(0, animate: false);
    });
  }

  Rect? _targetRect() {
    final ctx = _step.targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? _focusRect(Size size) {
    var rect = _targetRect();
    if (rect == null) return null;

    final minHeight = _step.focusMinHeight;
    if (minHeight != null && rect.height < minHeight) {
      final extra = minHeight - rect.height;
      final maxTop = size.height - minHeight;
      final top = (rect.top - extra / 2)
          .clamp(0.0, maxTop < 0 ? 0.0 : maxTop)
          .toDouble();
      rect = Rect.fromLTWH(rect.left, top, rect.width, minHeight);
    }

    rect = rect.intersect(Offset.zero & size);
    if (rect.width <= 1 || rect.height <= 1) return null;
    return rect;
  }

  Future<void> _focusStep(int index, {bool animate = true}) async {
    if (!mounted || index < 0 || index >= widget.steps.length) return;
    setState(() => _moving = true);

    // Primero desplazamos el objetivo. Si cambiáramos el índice antes, el
    // overlay podría quedar completamente oscuro durante la animación.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final ctx = widget.steps[index].targetKey.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: animate ? const Duration(milliseconds: 320) : Duration.zero,
          curve: Curves.easeOutCubic,
          alignment: 0.18,
        );
      } catch (_) {
        // Si el objetivo no está dentro de un scroll, seguimos con el paso.
      }
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) return;
    setState(() {
      _index = index;
      _moving = false;
    });
  }

  void _next() {
    if (_index < widget.steps.length - 1) {
      _focusStep(_index + 1);
    } else {
      _close();
    }
  }

  void _prev() {
    if (_index > 0) _focusStep(_index - 1);
  }

  void _close() => Navigator.of(context).maybePop();

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_moving) return KeyEventResult.handled;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter) {
      _next();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _prev();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final size = MediaQuery.sizeOf(context);
    final rect = _focusRect(size);

    final cardWidth = size.width < 560
        ? (size.width - 32).clamp(280.0, 380.0).toDouble()
        : 380.0;
    final cardHeightHint = 230.0;

    double cardTop;
    double cardLeft = (size.width - cardWidth) / 2;

    if (rect == null) {
      cardTop = (size.height - cardHeightHint) / 2;
    } else {
      final spaceBelow = size.height - rect.bottom - 24;
      final spaceAbove = rect.top - 24;
      final fitsRight = rect.right + 16 + cardWidth <= size.width - 16;
      final fitsLeft = rect.left - 16 - cardWidth >= 16;

      if (spaceBelow >= cardHeightHint) {
        cardTop = rect.bottom + 16;
      } else if (spaceAbove >= cardHeightHint) {
        cardTop = rect.top - cardHeightHint - 16;
      } else if (fitsRight && rect.width < size.width * 0.58) {
        // Sidebar u objetivo estrecho: tarjeta al lado, no encima.
        cardLeft = rect.right + 16;
        cardTop = (size.height - cardHeightHint) / 2;
      } else if (fitsLeft && rect.width < size.width * 0.58) {
        cardLeft = rect.left - cardWidth - 16;
        cardTop = (size.height - cardHeightHint) / 2;
      } else if (rect.top > size.height / 2) {
        cardTop = 16;
      } else {
        cardTop = size.height - cardHeightHint - 16;
      }
    }

    cardTop = cardTop.clamp(16.0, size.height - 16).toDouble();
    if (cardLeft < 16) cardLeft = 16;
    final maxLeft = size.width - cardWidth - 16;
    if (maxLeft >= 16 && cardLeft > maxLeft) cardLeft = maxLeft;

    final availableHeight = (size.height - cardTop - 16)
        .clamp(180.0, size.height)
        .toDouble();

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Stack(
        children: [
          // Oscurece todo excepto la zona del objetivo (spotlight).
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: TourSpotlightPainter(target: rect)),
            ),
          ),

          // Borde tipo cristal alrededor del objetivo (sin tinte amarillo).
          if (rect != null)
            Positioned(
              left: rect.left - 10,
              top: rect.top - 10,
              child: IgnorePointer(
                child: Container(
                  width: rect.width + 20,
                  height: rect.height + 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.62),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

          // Tarjeta contextual del paso actual.
          Positioned(
            left: cardLeft,
            top: cardTop,
            width: cardWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: availableHeight),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DevColors.card.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.13),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: DevColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      step.icon,
                                      size: 20,
                                      color: DevColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PASO ${_index + 1} DE ${widget.steps.length}',
                                          style: DevTheme.labelCaps(
                                            size: 9,
                                            color: DevColors.cream.withValues(
                                              alpha: 0.78,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          step.title,
                                          style: DevTheme.display(
                                            size: 16,
                                            w: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _close,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: DevColors.mutedFg,
                                    ),
                                    tooltip: 'Saltar tour',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: List.generate(widget.steps.length, (
                                  i,
                                ) {
                                  final active = i == _index;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: active ? 18 : 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? DevColors.cream
                                          : Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                step.description,
                                style: DevTheme.bodySecondary(size: 13),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    '${_index + 1} de ${widget.steps.length}',
                                    style: DevTheme.body(
                                      size: 11,
                                      color: DevColors.mutedFg,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_index > 0)
                                    TextButton(
                                      onPressed: _moving ? null : _prev,
                                      child: Text(
                                        'Anterior',
                                        style: DevTheme.body(
                                          size: 12.5,
                                          color: DevColors.mutedFg,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: _moving ? null : _next,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DevColors.primary,
                                      foregroundColor: DevColors.primaryFg,
                                      disabledBackgroundColor: DevColors.muted,
                                      disabledForegroundColor:
                                          DevColors.mutedFg,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      _index < widget.steps.length - 1
                                          ? 'Siguiente'
                                          : 'Finalizar',
                                      style: DevTheme.body(
                                        size: 12.5,
                                        w: FontWeight.w600,
                                        color: _moving
                                            ? DevColors.mutedFg
                                            : DevColors.primaryFg,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
