import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Notificaciones: `GET /notifications` → `{items, unreadCount, total}`;
/// al abrir marca todo con `PATCH /notifications/read-all`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
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
      final page = await UserService.getNotifications(limit: 50);
      _notifications = page.items;
      if (page.unreadCount > 0) {
        await UserService.markAllRead();
      }
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
        title: const Text('Notificaciones'),
        backgroundColor: DevColors.card,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
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
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none,
                              size: 48, color: DevColors.mutedFg),
                          const SizedBox(height: 12),
                          Text('No tienes notificaciones',
                              style: DevTheme.body(
                                  size: 16, color: DevColors.mutedFg)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _NotificationTile(notification: _notifications[i]),
                      ),
                    ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DevTheme.glass(radius: 8),
      child: Row(
        children: [
          _NotificationIcon(type: notification.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message,
                    style: DevTheme.body(size: 13, height: 1.3)),
                const SizedBox(height: 4),
                Text(
                  '${notification.fromUsername} · ${timeAgo(notification.createdAt)}',
                  style: DevTheme.body(size: 11, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
          if (!notification.read)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: DevColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final NotificationType type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.follow => (Icons.person_add, DevColors.gold),
      NotificationType.like => (Icons.favorite, DevColors.likedRed),
      NotificationType.comment => (Icons.comment, DevColors.consoleGreen),
      NotificationType.live => (Icons.radio, DevColors.wine),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
