import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../theme.dart';
import '../utils/dev_link.dart';
import 'avatar.dart';

/// Contenido que se va a compartir. Sirve para posts, betas, encuestas,
/// perfiles o cualquier cosa que tenga texto + enlace (+ media opcional).
class SharePayload {
  final String title;
  final String? subtitle;
  final String message;
  final String link;
  final String? mediaUrl;
  final bool mediaIsVideo;
  final Widget? preview;

  const SharePayload({
    required this.title,
    required this.message,
    required this.link,
    this.subtitle,
    this.mediaUrl,
    this.mediaIsVideo = false,
    this.preview,
  });

  /// Lo que se copia al portapapeles / se manda a las redes.
  String get fullText {
    final buffer = StringBuffer(message.trim());
    final media = (mediaUrl ?? '').trim();
    if (media.isNotEmpty) {
      buffer.write('\n\n${mediaIsVideo ? 'Video' : 'Imagen'}: $media');
    }
    if (link.trim().isNotEmpty) {
      buffer.write('\n\n${link.trim()}');
    }
    return buffer.toString().trim();
  }
}

/// Abre la hoja de compartir. Devuelve el aviso a mostrar (o `null`).
Future<String?> showShareSheet(
  BuildContext context, {
  required SharePayload payload,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (_) => ShareSheet(payload: payload),
  );
}

/// Compatibilidad: el perfil arma su propio payload.
Future<String?> showProfileShareSheet(
  BuildContext context, {
  required ProfileUser profile,
}) {
  return showShareSheet(
    context,
    payload: SharePayload(
      title: 'Compartir perfil',
      subtitle: '@${profile.username}',
      message: 'Mira el perfil de @${profile.username} en DevPlay',
      link: DevLink.profileUrl(profile.username),
      mediaUrl: profile.avatar,
      preview: _ProfilePreview(profile: profile),
    ),
  );
}

class ShareSheet extends StatelessWidget {
  final SharePayload payload;

  const ShareSheet({super.key, required this.payload});

  String get _text => payload.message.trim();
  String get _link => payload.link.trim();
  String get _full => payload.fullText;

  Future<void> _open(BuildContext context, Uri uri, String label) async {
    var launched = false;
    try {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      launched = false;
    }
    if (!context.mounted) return;
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: _full));
      if (!context.mounted) return;
      Navigator.pop(context, 'No se pudo abrir $label. Texto copiado');
      return;
    }
    Navigator.pop(context, 'Compartiendo en $label…');
  }

  Future<void> _copyText(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _full));
    if (!context.mounted) return;
    Navigator.pop(context, 'Texto copiado');
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!context.mounted) return;
    Navigator.pop(context, 'Enlace copiado');
  }

  Future<void> _copyMedia(BuildContext context) async {
    final media = payload.mediaUrl?.trim() ?? '';
    if (media.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: media));
    if (!context.mounted) return;
    Navigator.pop(context, 'Enlace del archivo copiado');
  }

  @override
  Widget build(BuildContext context) {
    final media = payload.mediaUrl?.trim() ?? '';
    final hasLink = _link.isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: DevColors.accentCyan.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: DevColors.accentCyan.withValues(alpha: 0.08),
                blurRadius: 46,
                spreadRadius: -6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: DevColors.card.withValues(alpha: 0.72),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: DevColors.muted,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DevColors.accentCyan.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DevColors.accentCyan.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.ios_share_rounded,
                              size: 16,
                              color: DevColors.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payload.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DevTheme.display(size: 17),
                                ),
                                if ((payload.subtitle ?? '').isNotEmpty)
                                  Text(
                                    payload.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DevTheme.bodySecondary(size: 11.5),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: DevColors.mutedFg,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (payload.preview != null) ...[
                        payload.preview!,
                        const SizedBox(height: 16),
                      ] else if (_text.isNotEmpty) ...[
                        _MessagePreview(text: _text),
                        const SizedBox(height: 16),
                      ],
                      Text('ENVIAR A', style: DevTheme.labelCaps()),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 4,
                        runSpacing: 14,
                        children: [
                          _ShareTarget(
                            icon: Icons.chat_bubble_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _open(
                              context,
                              Uri.https('wa.me', '/', {'text': _full}),
                              'WhatsApp',
                            ),
                          ),
                          _ShareTarget(
                            icon: Icons.alternate_email_rounded,
                            label: 'X',
                            color: DevColors.foreground,
                            onTap: () => _open(
                              context,
                              Uri.https('twitter.com', '/intent/tweet', {
                                'text': _text,
                                if (hasLink) 'url': _link,
                              }),
                              'X',
                            ),
                          ),
                          _ShareTarget(
                            icon: Icons.send_rounded,
                            label: 'Telegram',
                            color: const Color(0xFF229ED9),
                            onTap: () => _open(
                              context,
                              Uri.https('t.me', '/share/url', {
                                if (hasLink) 'url': _link,
                                'text': _text,
                              }),
                              'Telegram',
                            ),
                          ),
                          _ShareTarget(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            color: const Color(0xFF1877F2),
                            onTap: () => _open(
                              context,
                              Uri.https('www.facebook.com', '/sharer/sharer.php', {
                                'u': _link,
                                'quote': _text,
                              }),
                              'Facebook',
                            ),
                          ),
                          _ShareTarget(
                            icon: Icons.title_rounded,
                            label: 'Copiar texto',
                            color: DevColors.gold,
                            onTap: () => _copyText(context),
                          ),
                          if (hasLink)
                            _ShareTarget(
                              icon: Icons.link_rounded,
                              label: 'Copiar enlace',
                              color: DevColors.accentCyan,
                              onTap: () => _copyLink(context),
                            ),
                          if (media.isNotEmpty)
                            _ShareTarget(
                              icon: payload.mediaIsVideo
                                  ? Icons.videocam_rounded
                                  : Icons.image_rounded,
                              label: payload.mediaIsVideo
                                  ? 'Copiar video'
                                  : 'Copiar imagen',
                              color: DevColors.primary,
                              onTap: () => _copyMedia(context),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: DevColors.muted.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DevColors.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: DevColors.mutedFg,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasLink ? _link : _text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DevTheme.mono(
                                  size: 11,
                                  color: DevColors.mutedFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  final String text;

  const _MessagePreview({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DevColors.cardRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DevColors.accentCyan.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: DevTheme.body(size: 12.5, height: 1.45),
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  final ProfileUser profile;

  const _ProfilePreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = (profile.fullName?.trim().isNotEmpty ?? false)
        ? profile.fullName!.trim()
        : profile.username;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DevColors.cardRaised.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DevColors.accentCyan.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            username: profile.username,
            avatar: profile.avatar,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DevTheme.display(size: 15),
                ),
                Text(
                  '@${profile.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DevTheme.bodySecondary(size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTarget extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareTarget({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ShareTarget> createState() => _ShareTargetState();
}

class _ShareTargetState extends State<_ShareTarget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.06 : 1,
          duration: const Duration(milliseconds: 140),
          child: SizedBox(
            width: 72,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: _hover ? 0.26 : 0.14),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: color.withValues(alpha: _hover ? 0.8 : 0.4),
                    ),
                    boxShadow: _hover
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(widget.icon, color: color, size: 23),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: DevTheme.bodySecondary(
                    size: 11,
                    color: _hover ? DevColors.foreground : DevColors.mutedFg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
