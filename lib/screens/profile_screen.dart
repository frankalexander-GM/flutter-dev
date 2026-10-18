import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass_card.dart';
import '../widgets/post_card.dart';

/// Perfil público: `GET /users/{id}` → `{user: ProfileUser, posts}`.
class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileUser? _profile;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

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
      final (user, posts) = await UserService.getUser(widget.userId);
      _profile = user;
      _posts = posts;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? 'Perfil'),
        backgroundColor: DevColors.card,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Error: $_error',
                            textAlign: TextAlign.center,
                            style:
                                DevTheme.body(color: DevColors.destructive)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('No se encontro el perfil'))
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final profile = _profile!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                UserAvatar(
                    username: profile.username, avatar: profile.avatar, size: 80),
                const SizedBox(height: 16),
                Text(profile.username, style: DevTheme.display(size: 22)),
                if (profile.fullName != null &&
                    profile.fullName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.fullName!,
                      style: DevTheme.body(
                          size: 14, color: DevColors.mutedFg)),
                ],
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(profile.bio!,
                      style: DevTheme.body(size: 14),
                      textAlign: TextAlign.center),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Publicaciones', style: DevTheme.display(size: 16)),
          const SizedBox(height: 8),
          if (_posts.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Sin publicaciones aun',
                    style: DevTheme.body(color: DevColors.mutedFg)),
              ),
            )
          else
            for (final post in _posts) ...[
              PostCard(post: post),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
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
