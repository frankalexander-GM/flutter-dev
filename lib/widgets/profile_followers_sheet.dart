import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'avatar.dart';

/// Hoja con la lista de seguidores o de seguidos de un usuario.
///
/// Usa `GET /users/{id}/followers` y `GET /users/{id}/following`.
Future<void> showProfilePeopleSheet(
  BuildContext context, {
  required String userId,
  required bool followers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DevColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ProfilePeopleSheet(userId: userId, followers: followers),
  );
}

class ProfilePeopleSheet extends StatefulWidget {
  final String userId;
  final bool followers;

  const ProfilePeopleSheet({
    super.key,
    required this.userId,
    required this.followers,
  });

  @override
  State<ProfilePeopleSheet> createState() => _ProfilePeopleSheetState();
}

class _ProfilePeopleSheetState extends State<ProfilePeopleSheet> {
  List<FollowUser> _people = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final people = widget.followers
          ? await UserService.getFollowers(widget.userId)
          : await UserService.getFollowing(widget.userId);
      if (!mounted) return;
      setState(() {
        _people = people;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SizedBox(
      height: size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: DevColors.muted,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
            child: Row(
              children: [
                Text(
                  widget.followers ? 'Seguidores' : 'Siguiendo',
                  style: DevTheme.display(size: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
          const Divider(color: DevColors.border, height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: DevColors.mutedFg,
              ),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar la lista',
                style: DevTheme.body(color: DevColors.mutedFg),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.followers
                    ? Icons.group_outlined
                    : Icons.person_outline_rounded,
                size: 40,
                color: DevColors.mutedFg,
              ),
              const SizedBox(height: 12),
              Text(
                widget.followers
                    ? 'Todavía no tiene seguidores'
                    : 'No sigue a nadie todavía',
                style: DevTheme.body(color: DevColors.mutedFg),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _people.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final person = _people[i];
        return Row(
          children: [
            UserAvatar(
              username: person.username,
              avatar: person.avatar,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.username,
                    style: DevTheme.body(size: 14, w: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (person.bio != null && person.bio!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      person.bio!,
                      style: DevTheme.bodySecondary(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${person.followersCount}',
              style: DevTheme.bodySecondary(size: 12),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.group_outlined,
              size: 14,
              color: DevColors.mutedFg,
            ),
          ],
        );
      },
    );
  }
}
