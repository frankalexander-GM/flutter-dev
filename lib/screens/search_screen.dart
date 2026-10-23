import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/beta.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../services/beta_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/post_card.dart';
import 'betas_screen.dart';
import 'profile_screen.dart';

/// Buscador global: juegos/betas, usuarios y publicaciones.
///
/// Usa `GET /search?q=` (usuarios + posts) y filtra en cliente para separar
/// juegos (posts con ficha de beta o showcases) del resto del feed.
class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _SearchFilter { todo, juegos, usuarios, posts }

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  Timer? _debounce;
  bool _loading = false;
  String? _error;
  String _query = '';
  List<_SearchUser> _users = const [];
  List<Post> _posts = const [];
  _SearchFilter _filter = _SearchFilter.todo;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery.trim();
    if (_query.length >= 2) {
      _run(_query);
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    setState(() => _query = q);
    if (q.length < 2) {
      setState(() {
        _users = const [];
        _posts = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(q));
  }

  Future<void> _run(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getJson(
        '/search?q=${Uri.encodeQueryComponent(q)}&limit_users=8&limit_posts=16',
      );
      if (!mounted || _query != q) return;
      final users = (data['users'] as List? ?? [])
          .map((e) => _SearchUser.fromJson(e as Map<String, dynamic>))
          .toList();
      final posts = (data['posts'] as List? ?? [])
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _users = users;
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Post> get _games => _posts
      .where(
        (p) =>
            p.type == PostType.beta || p.type == PostType.game_showcase,
      )
      .toList();

  List<Post> get _plainPosts => _posts
      .where(
        (p) =>
            p.type != PostType.beta && p.type != PostType.game_showcase,
      )
      .toList();

  bool get _hasResults =>
      _users.isNotEmpty || _posts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                _buildSearchBar(),
                if (_query.length >= 2) _buildFilters(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DevColors.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: DevColors.accentCyan.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: DevColors.mutedFg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: (v) {
                        if (v.trim().length >= 2) _run(v.trim());
                      },
                      style: DevTheme.body(
                        size: 14,
                        color: DevColors.foreground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar juegos, betas, devs o @usuarios…',
                        hintStyle: DevTheme.body(
                          size: 13.5,
                          color: DevColors.disabled,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpiar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                        _focus.requestFocus();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: DevColors.mutedFg,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final juegos = _games.length;
    final usuarios = _users.length;
    final posts = _plainPosts.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todo',
            count: juegos + usuarios + posts,
            active: _filter == _SearchFilter.todo,
            onTap: () => setState(() => _filter = _SearchFilter.todo),
          ),
          _FilterChip(
            label: 'Juegos',
            count: juegos,
            active: _filter == _SearchFilter.juegos,
            onTap: () => setState(() => _filter = _SearchFilter.juegos),
          ),
          _FilterChip(
            label: 'Usuarios',
            count: usuarios,
            active: _filter == _SearchFilter.usuarios,
            onTap: () => setState(() => _filter = _SearchFilter.usuarios),
          ),
          _FilterChip(
            label: 'Publicaciones',
            count: posts,
            active: _filter == _SearchFilter.posts,
            onTap: () => setState(() => _filter = _SearchFilter.posts),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && !_hasResults) {
      return const Center(
        child: CircularProgressIndicator(color: DevColors.accentCyan),
      );
    }
    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'No se pudo buscar',
        text: _error!,
        actionLabel: 'Reintentar',
        onAction: () => _run(_query),
      );
    }
    if (_query.length < 2) {
      return const _SearchIntro();
    }
    if (!_hasResults) {
      return _Message(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados para "$_query"',
        text: 'Prueba con el nombre de un juego, un género o un @usuario.',
      );
    }

    final showGames =
        _filter == _SearchFilter.todo || _filter == _SearchFilter.juegos;
    final showUsers =
        _filter == _SearchFilter.todo || _filter == _SearchFilter.usuarios;
    final showPosts =
        _filter == _SearchFilter.todo || _filter == _SearchFilter.posts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
      children: [
        if (showGames && _games.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.sports_esports_rounded,
            title: 'Juegos y betas',
            count: _games.length,
          ),
          ..._games.map((p) => _GameResult(post: p)),
          const SizedBox(height: 8),
        ],
        if (showUsers && _users.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.people_alt_rounded,
            title: 'Usuarios',
            count: _users.length,
          ),
          ..._users.map((u) => _UserResult(user: u)),
          const SizedBox(height: 8),
        ],
        if (showPosts && _plainPosts.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.article_rounded,
            title: 'Publicaciones',
            count: _plainPosts.length,
          ),
          ..._plainPosts.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(post: p, compact: true),
            ),
          ),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------- resultados

class _GameResult extends StatelessWidget {
  final Post post;

  const _GameResult({required this.post});

  Future<void> _open(BuildContext context) async {
    final betaId = post.beta?.id;
    if (betaId == null || betaId.isEmpty) {
      // Showcase sin ficha de beta: mostramos la tarjeta del post.
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: DevColors.card,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: PostCard(post: post),
              ),
            ),
          ),
        ),
      );
      return;
    }

    Beta beta;
    try {
      beta = await BetaService.getBeta(betaId);
    } catch (_) {
      beta = Beta(
        id: betaId,
        postId: post.id,
        title: post.beta?.title ?? '',
        description: post.beta?.description ?? post.content,
        downloadType: 'LINK',
        betaStatus: (post.beta?.isOpen ?? false) ? 'open_beta' : 'closed_beta',
        version: post.beta?.version,
        genre: post.beta?.genre,
        downloads: post.beta?.downloads ?? 0,
        createdAt: post.createdAt,
      );
    }
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (ctx) => BetaDetailsSheet(
        beta: beta,
        onDownload: () async {
          Navigator.of(ctx).pop();
          try {
            final result = await BetaService.registerDownload(beta.id);
            final url = (result['url'] ?? '').toString();
            final uri = Uri.tryParse(url);
            if (uri != null && url.isNotEmpty) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {
            // Silencioso: el detalle ya muestra el enlace.
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beta = post.beta;
    final cover = post.media.isNotEmpty ? post.media.first.url : '';
    final isOpen = beta?.isOpen ?? false;
    final title = beta?.title ??
        post.game?.title ??
        (post.content.trim().split('\n').first);
    final meta = [
      if ((beta?.genre ?? '').isNotEmpty) beta!.genre!,
      if ((beta?.version ?? '').isNotEmpty) 'v${beta!.version}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DevColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DevColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: cover.isEmpty
                        ? Container(
                            color: DevColors.muted,
                            child: const Icon(
                              Icons.sports_esports_rounded,
                              size: 22,
                              color: DevColors.mutedFg,
                            ),
                          )
                        : Image.network(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: DevColors.muted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DevTheme.body(
                                size: 13.5,
                                w: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? DevColors.primary.withValues(alpha: 0.16)
                                  : DevColors.muted,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isOpen ? 'BETA' : 'JUEGO',
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
                      const SizedBox(height: 5),
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
                          const SizedBox(width: 10),
                          if ((post.author?.username ?? '').isNotEmpty)
                            Flexible(
                              child: Text(
                                '@${post.author!.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DevTheme.bodySecondary(size: 11),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DevColors.mutedFg,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserResult extends StatelessWidget {
  final _SearchUser user;

  const _UserResult({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: user.id),
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DevColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DevColors.border),
            ),
            child: Row(
              children: [
                UserAvatar(
                  username: user.username,
                  avatar: user.avatar,
                  size: 42,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? user.username : user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.body(
                          size: 13.5,
                          w: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DevTheme.bodySecondary(size: 11.5),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          user.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DevTheme.body(
                            size: 11.5,
                            color: DevColors.mutedFg,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DevColors.mutedFg,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchUser {
  final String id;
  final String username;
  final String fullName;
  final String bio;
  final String? avatar;

  const _SearchUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.bio,
    this.avatar,
  });

  factory _SearchUser.fromJson(Map<String, dynamic> json) => _SearchUser(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
        bio: json['bio'] as String? ?? '',
        avatar: json['avatar'] as String?,
      );
}

// ------------------------------------------------------------------ piezas

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DevColors.accentCyan),
          const SizedBox(width: 8),
          Text(title, style: DevTheme.display(size: 15, w: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: DevTheme.bodySecondary(size: 12),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? DevColors.primary : DevColors.card,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: active ? DevColors.primary : DevColors.border,
              ),
            ),
            child: Text(
              count > 0 ? '$label · $count' : label,
              style: DevTheme.body(
                size: 12,
                w: FontWeight.w600,
                color: active ? Colors.white : DevColors.mutedFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: DevColors.mutedFg),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: DevTheme.display(size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchIntro extends StatelessWidget {
  const _SearchIntro();

  @override
  Widget build(BuildContext context) {
    const suggestions = ['neon', 'godot', 'pixel', 'beta', 'sakura'];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: DevColors.accentCyan.withValues(alpha: 0.25),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                color: Color(0xFF04121A),
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Busca tu próximo juego',
              style: DevTheme.display(size: 20, w: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Encuentra betas abiertas, devs a los que seguir y '
                'publicaciones por tema. Escribe al menos 2 letras.',
                textAlign: TextAlign.center,
                style: DevTheme.body(
                  size: 13,
                  height: 1.5,
                  color: DevColors.mutedFg,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text('#$s'),
                      onPressed: () {
                        final state = context
                            .findAncestorStateOfType<_SearchScreenState>();
                        if (state == null) return;
                        state._controller.text = s;
                        state._onChanged(s);
                      },
                      backgroundColor: DevColors.card,
                      side: const BorderSide(color: DevColors.border),
                      labelStyle: DevTheme.body(
                        size: 12,
                        color: DevColors.mutedFg,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
