import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass_card.dart';
import '../widgets/post_card.dart';

/// Perfil público con pestañas: Publicaciones, Betas, Guardados, Logros.
class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  ProfileUser? _profile;
  List<Post> _posts = [];
  List<Post> _bookmarks = [];
  AchievementsResponse? _achievements;
  bool _isLoading = true;
  String? _error;
  int _currentTab = 0;

  static const _tabs = [
    ('Publicaciones', Icons.article_rounded),
    ('Betas', Icons.sports_esports_rounded),
    ('Guardados', Icons.bookmark_rounded),
    ('Logros', Icons.emoji_events_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
        _loadTabData();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final (user, posts) = await UserService.getUser(widget.userId);
      _profile = user;
      _posts = posts;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTabData() async {
    final auth = context.read<AuthProvider>();
    final isOwnProfile = auth.user?.id == widget.userId;

    // Solo cargar datos privados si es el propio perfil
    if (!isOwnProfile && (_currentTab == 2 || _currentTab == 3)) {
      return;
    }

    try {
      if (_currentTab == 2) { // Guardados
        final bookmarks = await UserService.getMyBookmarks();
        setState(() => _bookmarks = bookmarks.posts);
      } else if (_currentTab == 3) { // Logros
        final achievements = await UserService.getMyAchievements();
        setState(() => _achievements = achievements);
      }
    } catch (e) {
      // Silencioso, mantener datos previos
    }
  }

  List<Post> get _filteredPosts {
    if (_currentTab == 1) { // Betas
      return _posts.where((p) => p.type == PostType.beta).toList();
    } else if (_currentTab == 2) { // Guardados
      return _bookmarks;
    }
    return _posts; // Publicaciones (todo)
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isOwnProfile = auth.user?.id == widget.userId;

    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        title: Text(_profile?.username ?? 'Perfil'),
        backgroundColor: DevColors.card,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DevColors.gold,
          labelColor: DevColors.gold,
          unselectedLabelColor: DevColors.mutedFg,
          labelStyle: DevTheme.body(size: 13, w: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(icon: Icon(t.$2, size: 20), text: t.$1)).toList(),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: DevColors.foreground),
              onPressed: () => _showSettingsDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _profile == null
                  ? const Center(child: Text('No se encontró el perfil'))
                  : _buildBody(isOwnProfile),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: DevColors.mutedFg),
            const SizedBox(height: 16),
            Text('Error cargando perfil', style: DevTheme.display(size: 16)),
            const SizedBox(height: 8),
            Text(_error!, style: DevTheme.body(size: 13, color: DevColors.destructive), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isOwnProfile) {
    final profile = _profile!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header del perfil
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                UserAvatar(username: profile.username, avatar: profile.avatar, size: 80),
                const SizedBox(height: 16),
                Text(profile.username, style: DevTheme.display(size: 22)),
                if (profile.fullName != null && profile.fullName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.fullName!, style: DevTheme.body(size: 14, color: DevColors.mutedFg)),
                ],
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(profile.bio!, style: DevTheme.body(size: 14), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Posts', value: profile.postsCount),
                    _Stat(label: 'Seguidores', value: profile.followersCount),
                    _Stat(label: 'Siguiendo', value: profile.followingCount),
                  ],
                ),
                if (isOwnProfile) ...[
                  const SizedBox(height: 16),
                  _buildDevCoinsBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contenido de la pestaña activa
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildDevCoinsBadge() {
    final auth = context.read<AuthProvider>();
    final devCoins = auth.user?.devCoins ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD9A441), Color(0xFFB8862E)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text('$devCoins DevCoins', style: DevTheme.body(size: 13, w: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0: // Publicaciones
      case 1: // Betas
        return _buildPostsTab();
      case 2: // Guardados
        return _buildBookmarksTab();
      case 3: // Logros
        return _buildAchievementsTab();
      default:
        return _buildPostsTab();
    }
  }

  Widget _buildPostsTab() {
    final posts = _filteredPosts;
    final tabName = _currentTab == 0 ? 'Publicaciones' : 'Betas';

    final children = <Widget>[
      Text(tabName, style: DevTheme.display(size: 16)),
      const SizedBox(height: 8),
    ];

    if (posts.isEmpty) {
      children.add(
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_currentTab == 0 ? Icons.article_outlined : Icons.sports_esports_outlined, size: 48, color: DevColors.muted),
                const SizedBox(height: 12),
                Text('Sin ${_currentTab == 0 ? 'publicaciones' : 'betas'} aún', style: DevTheme.body(color: DevColors.mutedFg)),
                if (_currentTab == 1) ...[
                  const SizedBox(height: 8),
                  Text('Sube tu primera beta desde "Crear"', style: DevTheme.body(size: 12, color: DevColors.mutedFg)),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      for (final post in posts) {
        children.add(PostCard(post: post));
        children.add(const SizedBox(height: 12));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildBookmarksTab() {
    final auth = context.read<AuthProvider>();
    final isOwnProfile = auth.user?.id == widget.userId;

    if (!isOwnProfile) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: DevColors.muted),
              const SizedBox(height: 12),
              Text('Solo tú puedes ver tus guardados', style: DevTheme.body(color: DevColors.mutedFg)),
            ],
          ),
        ),
      );
    }

    final children = <Widget>[
      Text('Guardados', style: DevTheme.display(size: 16)),
      const SizedBox(height: 8),
    ];

    if (_bookmarks.isEmpty) {
      children.add(
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_outline_rounded, size: 48, color: DevColors.muted),
                const SizedBox(height: 12),
                Text('Sin posts guardados', style: DevTheme.body(color: DevColors.mutedFg)),
                const SizedBox(height: 8),
                Text('Marca posts con el icono de bandera', style: DevTheme.body(size: 12, color: DevColors.mutedFg)),
              ],
            ),
          ),
        ),
      );
    } else {
      for (final post in _bookmarks) {
        children.add(PostCard(post: post));
        children.add(const SizedBox(height: 12));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildAchievementsTab() {
    final auth = context.read<AuthProvider>();
    final isOwnProfile = auth.user?.id == widget.userId;

    if (!isOwnProfile) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: DevColors.muted),
              const SizedBox(height: 12),
              Text('Solo tú puedes ver tus logros', style: DevTheme.body(color: DevColors.mutedFg)),
            ],
          ),
        ),
      );
    }

    final achievements = _achievements?.achievements ?? [];

    final children = <Widget>[
      Text('Logros', style: DevTheme.display(size: 16)),
      const SizedBox(height: 8),
    ];

    if (achievements.isEmpty) {
      children.add(
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_outlined, size: 48, color: DevColors.muted),
                const SizedBox(height: 12),
                Text('Sin logros aún', style: DevTheme.body(color: DevColors.mutedFg)),
                const SizedBox(height: 8),
                Text('Participa en la comunidad para desbloquearlos', style: DevTheme.body(size: 12, color: DevColors.mutedFg)),
              ],
            ),
          ),
        ),
      );
    } else {
      children.add(
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: achievements.length,
          itemBuilder: (_, i) => _AchievementCard(achievement: achievements[i]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Configuración', style: DevTheme.display(size: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: DevColors.primary),
              title: Text('Editar perfil', style: DevTheme.body(size: 14)),
              onTap: () {
                Navigator.pop(context);
                _editProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.tour_rounded, color: DevColors.amber),
              title: Text('Repetir tour', style: DevTheme.body(size: 14)),
              onTap: () {
                Navigator.pop(context);
                // TODO: trigger tour
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar', style: DevTheme.body(color: DevColors.mutedFg))),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final profile = _profile!;
    final fullNameCtrl = TextEditingController(text: profile.fullName ?? '');
    final bioCtrl = TextEditingController(text: profile.bio ?? '');
    final locationCtrl = TextEditingController(text: profile.location ?? '');
    final websiteCtrl = TextEditingController(text: profile.website ?? '');
    final professionCtrl = TextEditingController(text: profile.profession ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Editar perfil', style: DevTheme.display(size: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EditField(controller: fullNameCtrl, label: 'Nombre completo', icon: Icons.person_rounded),
              _EditField(controller: bioCtrl, label: 'Bio', icon: Icons.info_outline_rounded, maxLines: 3),
              _EditField(controller: locationCtrl, label: 'Ubicación', icon: Icons.location_on_rounded),
              _EditField(controller: websiteCtrl, label: 'Web / GitHub', icon: Icons.link_rounded),
              _EditField(controller: professionCtrl, label: 'Profesión / Rol', icon: Icons.work_outline_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: DevTheme.body(color: DevColors.mutedFg))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'fullName': fullNameCtrl.text.trim(),
              'bio': bioCtrl.text.trim(),
              'location': locationCtrl.text.trim(),
              'website': websiteCtrl.text.trim(),
              'profession': professionCtrl.text.trim(),
            }),
            style: ElevatedButton.styleFrom(backgroundColor: DevColors.primary, foregroundColor: DevColors.primaryFg),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await UserService.updateProfile(
          fullName: result['fullName']!.isEmpty ? null : result['fullName'],
          bio: result['bio']!.isEmpty ? null : result['bio'],
          location: result['location']!.isEmpty ? null : result['location'],
          website: result['website']!.isEmpty ? null : result['website'],
          profession: result['profession']!.isEmpty ? null : result['profession'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado'), backgroundColor: DevColors.consoleGreen),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: DevColors.destructive),
          );
        }
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: DevTheme.display(size: 20)),
        const SizedBox(height: 4),
        Text(label, style: DevTheme.labelCaps(size: 11)),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: DevTheme.body(size: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DevTheme.body(size: 13, color: DevColors.mutedFg),
          prefixIcon: Icon(icon, color: DevColors.mutedFg, size: 20),
          filled: true,
          fillColor: DevColors.cardRaised,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DevColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DevColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DevColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'legendary': return const Color(0xFFE8A838);
      case 'epic': return const Color(0xFF9B59E8);
      case 'rare': return const Color(0xFF4A9F9A);
      default: return DevColors.mutedFg;
    }
  }

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'star': return Icons.star_rounded;
      case 'workspace_premium': return Icons.workspace_premium_rounded;
      case 'verified': return Icons.verified_rounded;
      case 'military_tech': return Icons.military_tech_rounded;
      case 'rocket_launch': return Icons.rocket_launch_rounded;
      default: return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(achievement.rarity);
    final iconData = _iconFromString(achievement.icon);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: achievement.isUnlocked
                    ? [rarityColor, rarityColor.withValues(alpha: 0.7)]
                    : [DevColors.muted, DevColors.muted],
              ),
            ),
            child: Icon(iconData, size: 28, color: achievement.isUnlocked ? Colors.white : DevColors.mutedFg),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.name,
            style: DevTheme.body(size: 13, w: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: DevTheme.body(size: 10, color: DevColors.mutedFg),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: achievement.isUnlocked ? rarityColor.withValues(alpha: 0.2) : DevColors.muted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              achievement.isUnlocked ? 'DESBLOQUEADO' : 'BLOQUEADO',
              style: DevTheme.body(
                size: 9,
                w: FontWeight.w700,
                color: achievement.isUnlocked ? rarityColor : DevColors.mutedFg,
              ),
            ),
          ),
          if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Desde ${_formatDate(achievement.unlockedAt!)}',
              style: DevTheme.body(size: 9, color: DevColors.mutedFg),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
    if (diff.inDays > 0) return '${diff.inDays}d';
    return 'hoy';
  }
}