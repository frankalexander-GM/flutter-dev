import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/media_service.dart';
import '../services/post_service.dart';
import '../services/security_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/dev_link.dart';
import '../widgets/glass_card.dart';
import '../widgets/post_card.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/profile_followers_sheet.dart';
import '../widgets/profile_header.dart';

/// Perfil de usuario con las 5 pestañas del PRD:
/// Publicaciones · Juegos · Multimedia · Me gusta · Acerca de.
class ProfileScreen extends StatefulWidget {
  final String userId;
  final int initialTab;

  /// Abre el diálogo de ajustes del perfil al entrar (para el perfil propio).
  final bool openSettings;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
    this.openSettings = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Las pestañas del perfil.
enum ProfileTab {
  posts('Publicaciones', Icons.article_rounded),
  games('Juegos', Icons.sports_esports_rounded),
  media('Multimedia', Icons.perm_media_rounded),
  likes('Me gusta', Icons.favorite_rounded),
  about('Acerca de', Icons.info_outline_rounded);

  const ProfileTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Tipos de error del perfil, cada uno con su estado visual.
enum _ProfileError { none, notFound, private, connection }

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  ProfileUser? _profile;
  List<Post> _posts = [];
  List<Post> _likedPosts = [];
  List<ProfileMedia> _media = [];
  UserStats? _stats;

  /// Número de juegos publicados (posts de tipo showcase). Dato real.
  int get _gamesCount =>
      _posts.where((p) => p.type == PostType.game_showcase).length;

  bool _isLoading = true;
  String? _error;

  /// Tipo de error, para mostrar el estado visual adecuado.
  _ProfileError _errorKind = _ProfileError.none;

  /// Estado de la acción de seguir (evita pulsaciones duplicadas).
  bool _followBusy = false;

  /// Visibilidad del perfil propio (se sincroniza con la API).
  bool _isPrivate = false;

  /// Estado de la subida de archivos a la galería.
  bool _uploadingMedia = false;

  /// Los ajustes se pidieron antes de que el perfil terminara de cargar.
  bool _pendingSettings = false;

  @override
  void initState() {
    super.initState();
    final initialTab = widget.initialTab.clamp(0, ProfileTab.values.length - 1);
    _tabController = TabController(
      length: ProfileTab.values.length,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(_onTabChanged);
    _load();
    if (widget.openSettings) {
      // Abre los ajustes del perfil en cuanto se cargan los datos.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openSettings());
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
      _loadTabData(_tabController.index);
    }
  }

  bool get _isOwnProfile {
    final auth = context.read<AuthProvider>();
    return auth.user?.id == widget.userId;
  }

  // ------------------------------- Carga -----------------------------------

  Future<void> _load({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorKind = _ProfileError.none;
      });
    }
    try {
      final (user, posts) = await UserService.getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = user;
        _posts = posts;
        _isLoading = false;
        _error = null;
        _errorKind = _ProfileError.none;
      });
      // Las pestañas que dependen de la red se cargan después del encabezado.
      _loadTabData(_tabController.index);
      if (_isOwnProfile) {
        _loadStats();
        _loadPrivacy();
        // Si se pidieron ajustes antes de cargar, se abren ahora.
        if (_pendingSettings) {
          _pendingSettings = false;
          _openSettings();
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // 404 = el usuario no existe; 403 = perfil privado.
        _errorKind = switch (e.statusCode) {
          404 => _ProfileError.notFound,
          403 => _ProfileError.private,
          _ => _ProfileError.connection,
        };
        _error = e.detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorKind = _ProfileError.connection;
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await UserService.getMyStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {
      // Las estadísticas son un extra: si fallan, el perfil sigue siendo útil.
    }
  }

  /// Sincroniza la visibilidad del perfil propio con la API.
  Future<void> _loadPrivacy() async {
    try {
      final me = await UserService.getMe();
      if (!mounted) return;
      setState(() => _isPrivate = me.isPrivate);
    } catch (_) {
      // Si no se puede leer, se mantiene el valor por defecto.
    }
  }

  /// Carga los datos de la pestaña activa (solo si aún no están cargados).
  Future<void> _loadTabData(int index) async {
    try {
      switch (ProfileTab.values[index]) {
        case ProfileTab.likes:
          if (_likedPosts.isEmpty) {
            final items = await UserService.getLikedPosts(widget.userId);
            if (!mounted) return;
            setState(() => _likedPosts = items);
          }
        case ProfileTab.media:
          if (_media.isEmpty) {
            final items = await UserService.getMedia(widget.userId);
            if (!mounted) return;
            setState(() => _media = items);
          }
        case ProfileTab.posts:
        case ProfileTab.games:
        case ProfileTab.about:
          break;
      }
    } catch (e) {
      // Un error al cargar una pestaña no debe tumbar el perfil: se muestra
      // el estado vacío de esa pestaña.
    }
  }

  // ----------------------------- Acciones ----------------------------------

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _followBusy) return;

    // Dejar de seguir pide confirmación (seguir es inmediato).
    if (profile.isFollowing) {
      final confirmed = await _confirmUnfollow(profile);
      if (confirmed != true || !mounted) return;
    }

    setState(() => _followBusy = true);

    final wasFollowing = profile.isFollowing;
    // Optimista: el botón reacciona de inmediato.
    setState(() {
      _profile = _copyProfile(
        profile,
        isFollowing: !wasFollowing,
        followersCount:
            profile.followersCount + (wasFollowing ? -1 : 1),
      );
    });

    try {
      final following = wasFollowing
          ? await UserService.unfollow(profile.id)
          : await UserService.follow(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = _copyProfile(
          _profile!,
          isFollowing: following,
          followersCount: following
              ? profile.followersCount + 1
              : profile.followersCount,
        );
      });
      _toast(following ? 'Ahora sigues a @${profile.username}' : 'Dejaste de seguir a @${profile.username}');
    } catch (e) {
      if (!mounted) return;
      // Revertir si el backend rechaza.
      setState(() => _profile = profile);
      _toast('No se pudo actualizar el seguimiento: $e', error: true);
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  /// Confirmación para dejar de seguir.
  Future<bool?> _confirmUnfollow(ProfileUser profile) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Dejar de seguir', style: DevTheme.display(size: 16)),
        content: Text(
          'Dejarás de ver las publicaciones de @${profile.username} en tu feed. '
          'Podrás volver a seguirlo cuando quieras.',
          style: DevTheme.body(size: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: DevTheme.body(color: DevColors.mutedFg),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.destructive,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Dejar de seguir'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlock() async {
    final profile = _profile;
    if (profile == null) return;
    final wasBlocked = profile.isBlocked;
    try {
      if (wasBlocked) {
        await SecurityService.unblock(profile.id);
      } else {
        await SecurityService.block(profile.id);
      }
      if (!mounted) return;
      setState(() => _profile = _copyProfile(_profile!, isBlocked: !wasBlocked));
      _toast(wasBlocked ? 'Usuario desbloqueado' : 'Usuario bloqueado');
    } catch (e) {
      if (!mounted) return;
      _toast('No se pudo bloquear: $e', error: true);
    }
  }

  Future<void> _shareProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final link = DevLink.profileUrl(profile.username);
    final text = 'Perfil de @${profile.username} en DevPlay\n$link';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _toast('Enlace del perfil copiado');
  }

  void _openFollowers({required bool followers}) {
    showProfilePeopleSheet(
      context,
      userId: widget.userId,
      followers: followers,
    );
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? DevColors.destructive : DevColors.consoleGreen,
      ),
    );
  }

  static ProfileUser _copyProfile(
    ProfileUser p, {
    bool? isFollowing,
    bool? isBlocked,
    int? followersCount,
  }) => ProfileUser(
    id: p.id,
    username: p.username,
    fullName: p.fullName,
    bio: p.bio,
    avatar: p.avatar,
    banner: p.banner,
    role: p.role,
    isGuest: p.isGuest,
    location: p.location,
    website: p.website,
    profession: p.profession,
    tags: p.tags,
    createdAt: p.createdAt,
    followersCount: followersCount ?? p.followersCount,
    followingCount: p.followingCount,
    postsCount: p.postsCount,
    isFollowing: isFollowing ?? p.isFollowing,
    isBlocked: isBlocked ?? p.isBlocked,
    blockedMe: p.blockedMe,
  );

  // -------------------------------- Build -----------------------------------

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final isOwn = _isOwnProfile;

    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        title: Text(
          profile?.username ?? 'Perfil',
          style: DevTheme.display(size: 16),
        ),
        backgroundColor: DevColors.card,
        elevation: 0,
        actions: [
          if (profile != null && !isOwn)
            _buildOptionsMenu(profile),
          if (isOwn)
            IconButton(
              tooltip: 'Editar perfil',
              icon: const Icon(Icons.edit_rounded, color: DevColors.foreground),
              onPressed: _openEditor,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : profile == null
          ? const Center(child: Text('No se encontró el perfil'))
          : _buildBody(profile, isOwn),
      bottomNavigationBar: _isLoading || profile == null
          ? null
          : _buildTabBar(profile),
    );
  }

  Widget _buildOptionsMenu(ProfileUser profile) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones del perfil',
      icon: const Icon(Icons.more_vert_rounded, color: DevColors.foreground),
      color: DevColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DevColors.border),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'share':
            await _shareProfile();
          case 'block':
            await _toggleBlock();
          case 'report':
            await _reportProfile(profile);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.ios_share_rounded, size: 18),
            title: Text('Compartir perfil'),
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              profile.isBlocked
                  ? Icons.lock_open_rounded
                  : Icons.block_rounded,
              size: 18,
              color: profile.isBlocked
                  ? DevColors.foreground
                  : DevColors.destructive,
            ),
            title: Text(profile.isBlocked ? 'Desbloquear' : 'Bloquear'),
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.flag_outlined,
              size: 18,
              color: DevColors.destructive,
            ),
            title: Text('Reportar perfil'),
          ),
        ),
      ],
    );
  }

  Future<void> _reportProfile(ProfileUser profile) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: DevColors.muted,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reportar a @${profile.username}',
                  style: DevTheme.display(size: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final option in const [
              ('spam', 'Spam'),
              ('harassment', 'Acoso'),
              ('inappropriate', 'Contenido inapropiado'),
              ('impersonation', 'Suplantación de identidad'),
              ('other', 'Otro motivo'),
            ])
              ListTile(
                dense: true,
                title: Text(option.$2, style: DevTheme.body(size: 14)),
                onTap: () => Navigator.pop(ctx, option.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await SecurityService.report(
        entityId: profile.id,
        entityType: 'USER',
        reason: reason,
      );
      if (!mounted) return;
      _toast('Reporte enviado. Gracias por avisarnos.');
    } catch (e) {
      if (!mounted) return;
      _toast('No se pudo enviar el reporte: $e', error: true);
    }
  }

  /// Estado visual del error, con un mensaje propio para cada caso.
  Widget _buildErrorState() {
    return switch (_errorKind) {
      _ProfileError.notFound => _buildMessageState(
        icon: Icons.person_off_outlined,
        title: 'Este perfil no está disponible',
        description:
            'El usuario que buscas no existe o ha sido eliminado. '
            'Vuelve a la pantalla anterior para seguir explorando.',
        actionLabel: 'Volver',
        onAction: () => Navigator.of(context).maybePop(),
      ),
      _ProfileError.private => _buildMessageState(
        icon: Icons.lock_outline_rounded,
        title: 'Perfil privado',
        description:
            'Este usuario decidió ocultar su contenido. Solo sus seguidores '
            'pueden ver sus publicaciones y juegos.',
        actionLabel: 'Volver',
        onAction: () => Navigator.of(context).maybePop(),
      ),
      _ => _buildMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'No se pudo cargar el perfil',
        description: _error ?? 'Revisa tu conexión e inténtalo de nuevo.',
        actionLabel: 'Reintentar',
        onAction: _load,
        isError: true,
      ),
    };
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: DevColors.mutedFg),
            const SizedBox(height: 16),
            Text(title, style: DevTheme.display(size: 16)),
            const SizedBox(height: 8),
            Text(
              description,
              style: DevTheme.body(
                size: 13,
                color: isError ? DevColors.destructive : DevColors.mutedFg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ProfileUser profile) {
    return Container(
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: DevColors.primary,
        labelColor: DevColors.primary,
        unselectedLabelColor: DevColors.mutedFg,
        labelStyle: DevTheme.body(size: 12.5, w: FontWeight.w600),
        tabs: ProfileTab.values
            .map(
              (t) => Tab(
                icon: Icon(t.icon, size: 19),
                text: t.label,
                height: 52,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBody(ProfileUser profile, bool isOwn) {
    if (profile.blockedMe) {
      return _buildBlockedState();
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ProfileHeader(
            profile: profile,
            isOwn: isOwn,
            followBusy: _followBusy,
            gamesCount: _gamesCount,
            onFollow: _toggleFollow,
            onEdit: _openEditor,
            onFollowers: () => _openFollowers(followers: true),
            onFollowing: () => _openFollowers(followers: false),
            onPosts: () => _goToTab(ProfileTab.posts),
            onGames: () => _goToTab(ProfileTab.games),
            onShare: _shareProfile,
          ),
          const SizedBox(height: 16),
          _buildTabContent(profile, isOwn),
        ],
      ),
    );
  }

  void _goToTab(ProfileTab tab) {
    _tabController.animateTo(tab.index);
  }

  Widget _buildBlockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.block_rounded,
              size: 48,
              color: DevColors.mutedFg,
            ),
            const SizedBox(height: 14),
            Text('Perfil no disponible', style: DevTheme.display(size: 16)),
            const SizedBox(height: 8),
            Text(
              'Este usuario te tiene bloqueado, así que no puedes ver su '
              'perfil ni su contenido.',
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ProfileUser profile, bool isOwn) {
    switch (ProfileTab.values[_tabController.index]) {
      case ProfileTab.posts:
        return _buildPostsTab();
      case ProfileTab.games:
        return _buildGamesTab();
      case ProfileTab.media:
        return _buildMediaTab();
      case ProfileTab.likes:
        return _buildLikesTab();
      case ProfileTab.about:
        return _buildAboutTab(profile, isOwn);
    }
  }

  // ------------------------------ Publicaciones -----------------------------

  Widget _buildPostsTab() {
    final posts = _posts;
    if (posts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.article_outlined,
        title: 'Sin publicaciones aún',
        description: _isOwnProfile
            ? 'Comparte tu primer juego, avance o idea con la comunidad.'
            : 'Este usuario todavía no ha publicado nada.',
      );
    }
    return Column(
      children: [
        for (final post in posts) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            // En el perfil se muestra el botón de guardar (colección privada
            // del visitante) y el de repost, según el PRD del perfil.
            child: PostCard(post: post, showSave: true),
          ),
        ],
      ],
    );
  }

  // --------------------------------- Juegos ---------------------------------

  Widget _buildGamesTab() {
    // Los juegos del usuario son sus publicaciones de tipo GAME_SHOWCASE
    // (datos reales de la API). Si el post trae adjunto de juego, se usan
    // su portada y sus metadatos; si no, los de la publicación.
    final games = _posts
        .where((p) => p.type == PostType.game_showcase)
        .toList();

    if (games.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sports_esports_outlined,
        title: 'Sin juegos publicados',
        description: _isOwnProfile
            ? 'Publica un showcase para que tu juego aparezca aquí.'
            : 'Este usuario todavía no ha publicado ningún juego.',
      );
    }

    return Column(
      children: [
        for (final game in games)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GameCard(post: game),
          ),
      ],
    );
  }

  // ------------------------------- Multimedia -------------------------------

  Widget _buildMediaTab() {
    if (_media.isEmpty) {
      return Column(
        children: [
          _buildEmptyState(
            icon: Icons.perm_media_outlined,
            title: 'Sin multimedia',
            description: 'Sube una foto o un video para empezar tu galería.',
          ),
          if (_isOwnProfile) _buildUploadButton(),
        ],
      );
    }

    return Column(
      children: [
        if (_isOwnProfile) _buildUploadButton(),
        LayoutBuilder(
          builder: (context, constraints) {
            // 2 columnas en móvil, 3 en tablet/escritorio.
            final columns = constraints.maxWidth >= 700 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _media.length,
              itemBuilder: (_, i) => MediaTile(
                media: _media[i],
                onTap: () => _openMedia(i),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Botón para subir una foto o un video a la galería.
  ///
  /// La galería se alimenta de los medios de las publicaciones, así que
  /// subir un archivo crea una publicación real con ese contenido.
  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: OutlinedButton.icon(
        onPressed: _uploadingMedia ? null : _uploadMedia,
        icon: _uploadingMedia
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined, size: 18),
        label: Text(_uploadingMedia ? 'Subiendo…' : 'Subir foto o video'),
        style: OutlinedButton.styleFrom(
          foregroundColor: DevColors.primary,
          side: const BorderSide(color: DevColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Sube un archivo y lo publica en la galería.
  Future<void> _uploadMedia() async {
    if (_uploadingMedia) return;
    setState(() => _uploadingMedia = true);
    try {
      final uploaded = await MediaService.pickAndUpload(allowVideo: true);
      if (!mounted) return;
      if (uploaded == null) {
        setState(() => _uploadingMedia = false);
        return;
      }
      // La galería viene de los medios de las publicaciones: se crea un post
      // con el archivo subido (dato real, no un mock).
      await PostService.createPost(
        content: '',
        type: 'POST',
        media: [
          {'url': uploaded.url, 'kind': uploaded.kind},
        ],
      );
      if (!mounted) return;
      setState(() {
        _uploadingMedia = false;
        _media = [];
        _likedPosts = [];
      });
      _load(refresh: true);
      _toast('Subido a tu galería');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingMedia = false);
      _toast('No se pudo subir: $e', error: true);
    }
  }

  void _openMedia(int index) {
    final media = _media[index];
    if (media.isVideo) {
      // Los videos se abren en una pestaña nueva con controles nativos del
      // navegador (el reproductor propio del video_player no está en assets).
      final uri = Uri.tryParse(media.url);
      if (uri == null) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: DevColors.card,
          title: Text('Video', style: DevTheme.display(size: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                media.url,
                style: DevTheme.bodySecondary(size: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchExternalUrl(uri);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Abrir video'),
              ),
            ],
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(
            media.url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              color: DevColors.card,
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar la imagen',
                style: DevTheme.body(color: DevColors.mutedFg),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------- Me gusta --------------------------------

  Widget _buildLikesTab() {
    if (_likedPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline_rounded,
        title: 'Sin publicaciones marcadas',
        description: 'Las publicaciones que le gusten a este usuario '
            'aparecerán aquí, según sus preferencias de privacidad.',
      );
    }
    return Column(
      children: [
        for (final post in _likedPosts)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: PostCard(post: post, showSave: true),
          ),
      ],
    );
  }

  // ------------------------------- Acerca de --------------------------------

  Widget _buildAboutTab(ProfileUser profile, bool isOwn) {
    final stats = _stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.bio != null && profile.bio!.isNotEmpty)
          AboutBlock(
            title: 'Biografía',
            icon: Icons.person_outline_rounded,
            child: Text(profile.bio!, style: DevTheme.body(size: 14)),
          ),
        if (profile.profession != null && profile.profession!.isNotEmpty)
          AboutBlock(
            title: 'Rol',
            icon: Icons.work_outline_rounded,
            child: Text(
              profile.profession!,
              style: DevTheme.body(size: 14),
            ),
          ),
        if (profile.tags != null && profile.tags!.isNotEmpty)
          AboutBlock(
            title: 'Intereses y habilidades',
            icon: Icons.interests_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.tags!
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: DevColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: DevColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: DevTheme.body(
                          size: 12,
                          color: DevColors.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        AboutBlock(
          title: 'Enlaces',
          icon: Icons.link_rounded,
          child: profile.website != null && profile.website!.isNotEmpty
              ? ExternalLink(url: profile.website!)
              : Text(
                  'Sin enlaces externos',
                  style: DevTheme.body(size: 13, color: DevColors.mutedFg),
                ),
        ),
        AboutBlock(
          title: 'Miembro desde',
          icon: Icons.calendar_today_rounded,
          child: Text(
            _formatJoinDate(profile.createdAt),
            style: DevTheme.body(size: 14),
          ),
        ),
        if (isOwn && stats != null) ...[
          const SizedBox(height: 8),
          CreatorStatsCard(stats: stats),
        ],
      ],
    );
  }

  static String _formatJoinDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _openEditor() async {
    final profile = _profile;
    if (profile == null) return;
    final saved = await showProfileEditSheet(context, profile: profile);
    if (saved == true && mounted) {
      _toast('Perfil actualizado');
      _load(refresh: true);
    }
  }

  /// Ajustes del perfil propio: editar datos y privacidad.
  Future<void> _openSettings() async {
    if (!_isOwnProfile) return;
    final profile = _profile;
    if (profile == null) {
      // Si aún no ha cargado, se reintenta al terminar la carga.
      _pendingSettings = true;
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Configuración', style: DevTheme.display(size: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: DevColors.primary),
              title: Text('Editar perfil', style: DevTheme.body(size: 14)),
              subtitle: Text(
                'Nombre, bio, avatar, portada e intereses',
                style: DevTheme.bodySecondary(size: 11.5),
              ),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(
                Icons.lock_outline_rounded,
                color: DevColors.gold,
              ),
              title: Text('Privacidad', style: DevTheme.body(size: 14)),
              subtitle: Text(
                'Perfil privado y controles de visibilidad',
                style: DevTheme.bodySecondary(size: 11.5),
              ),
              onTap: () => Navigator.pop(ctx, 'privacy'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar',
              style: DevTheme.body(color: DevColors.mutedFg),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _openEditor();
    } else if (action == 'privacy') {
      await _openPrivacy();
    }
  }

  /// Alterna la privacidad del perfil (`PATCH /security/privacy`).
  Future<void> _openPrivacy() async {
    final profile = _profile;
    if (profile == null) return;
    final current = _isPrivate;
    final next = !current;
    try {
      await UserService.setPrivacy(isPrivate: next);
      if (!mounted) return;
      setState(() => _isPrivate = next);
      _toast(
        next
            ? 'Tu perfil ahora es privado'
            : 'Tu perfil ahora es público',
      );
    } catch (e) {
      if (!mounted) return;
      _toast('No se pudo cambiar la privacidad: $e', error: true);
    }
  }

  // -------------------------------- Auxiliares ------------------------------

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: DevColors.muted),
              const SizedBox(height: 12),
              Text(title, style: DevTheme.body(color: DevColors.mutedFg)),
              const SizedBox(height: 6),
              Text(
                description,
                style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lanza una URL externa (helper local para el diálogo de video).
Future<void> launchExternalUrl(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Si no se puede abrir, se ignora: el usuario ya copió la URL.
  }
}
