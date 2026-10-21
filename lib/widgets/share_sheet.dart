import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/post.dart';
import '../theme.dart';

/// Hoja de compartir: copiar enlace, compartir nativo y ver conteo.
/// Devuelve `true` si el usuario compartió (para sumar al contador).
class ShareSheet extends StatelessWidget {
  final Post post;
  const ShareSheet({super.key, required this.post});

  String get _link => 'https://devplay.gg/p/${post.id}';
  String get _text =>
      'Mira este post de @${post.author?.username ?? 'usuario'} en DevPlay 🎮\n${post.content}\n$_link';

  static Future<bool?> show(BuildContext context, Post post) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Compartir', style: DevTheme.display(size: 17)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _link,
                style: DevTheme.mono(size: 11, color: DevColors.mutedFg),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Option(
            icon: Icons.link_rounded,
            color: DevColors.gold,
            label: 'Copiar enlace',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: _link));
              if (context.mounted) {
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enlace copiado 🔗')),
                );
              }
            },
          ),
          _Option(
            icon: Icons.ios_share_rounded,
            color: DevColors.primary,
            label: 'Compartir en otras apps…',
            onTap: () async {
              await SharePlus.instance.share(
                ShareParams(text: _text),
              );
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
          _Option(
            icon: Icons.download_rounded,
            color: DevColors.olive,
            label: 'Guardar post',
            trailing: 'pronto',
            onTap: () {
              Navigator.pop(context, false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Guardado en tu colección 📌 (demo local)')),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _Option({
    required this.icon,
    required this.color,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: DevTheme.body(size: 14)),
            ),
            if (trailing != null)
              Text(trailing!,
                  style:
                      DevTheme.body(size: 11, color: DevColors.mutedFg)),
          ],
        ),
      ),
    );
  }
}
