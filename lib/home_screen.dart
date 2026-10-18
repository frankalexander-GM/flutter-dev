import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/post.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/post_service.dart';
import 'services/user_service.dart';
import 'theme.dart';
import 'widgets/feed_view.dart';
import 'widgets/header.dart';
import 'widgets/hero_banner.dart';
import 'widgets/hero_ticker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;
  int _unread = 0;

  static const _nav = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.explore_outlined, 'Explorar'),
    (Icons.auto_awesome_outlined, 'Descubrir'),
    (Icons.sports_esports_outlined, 'Betas'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

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
      final posts = await PostService.getPosts();
      int unread = 0;
      try {
        unread = await UserService.getUnreadCount();
      } catch (_) {
        // Invitado sin notificaciones: badge en 0.
      }
      _posts = posts;
      _unread = unread;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onNavTap(int index) async {
    final auth = context.read<AuthProvider>();
    if (index == 4) {
      final user = auth.user;
      if (user != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
        );
        if (mounted) _load();
      }
      return;
    }
    setState(() => _navIndex = index);
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

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                DevHeader(
                  unreadCount: _unread,
                  onNotificationsTap: _openNotifications,
                  onLogout: _logout,
                ),
                // Hero pixel-art (nuestro diseño) con margen para que respire.
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: HeroBanner(
                    onCreateTap: () => _CreateDock(onCreated: _load)._open(context),
                    onGameTap: (name) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name - pronto')),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const HeroTicker(games: mockGames),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _load)
                          : FeedView(posts: _posts),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(child: _CreateDock(onCreated: _load)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(
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
                    onTap: () => _onNavTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _nav[i].$1,
                          size: 22,
                          color:
                              i == _navIndex ? DevColors.gold : DevColors.mutedFg,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nav[i].$2,
                          style: DevTheme.body(
                            size: 10,
                            w: i == _navIndex ? FontWeight.w700 : FontWeight.w400,
                            color:
                                i == _navIndex ? DevColors.gold : DevColors.mutedFg,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: DevColors.mutedFg),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el feed.\n¿Esta corriendo el backend en :8000?',
              textAlign: TextAlign.center,
              style: DevTheme.body(size: 14, color: DevColors.mutedFg),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    DevTheme.body(size: 12, color: DevColors.destructive)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
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

  const _CreateDock({required this.onCreated});

  Future<void> _open(BuildContext context) async {
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
            _Option(
                icon: Icons.sports_esports_rounded,
                iconColor: DevColors.amber,
                label: 'Subir Beta',
                type: 'BETA'),
            _Option(
                icon: Icons.videocam_outlined,
                iconColor: DevColors.wine,
                label: 'Subir Stream',
                type: 'STREAM'),
            _Option(
                icon: Icons.article_outlined,
                iconColor: DevColors.consoleGreen,
                label: 'Publicar Post',
                type: 'POST'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (action != null && context.mounted) {
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
              const SnackBar(content: Text('Publicado!')),
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
            BoxShadow(
              color: DevColors.background.withValues(alpha: 0.6),
              blurRadius: 4,
              offset: const Offset(0, 0),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text('Crear',
                style: DevTheme.body(
                    size: 14, w: FontWeight.w700, color: Colors.white)),
          ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DevColors.card,
      title: Text('Nueva publicacion', style: DevTheme.display(size: 16)),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        style: DevTheme.body(size: 14),
        decoration: InputDecoration(
          hintText: 'Que esta pasando en tu proyecto?',
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
          child: Text('Cancelar',
              style: DevTheme.body(color: DevColors.mutedFg)),
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
