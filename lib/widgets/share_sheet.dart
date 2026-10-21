import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../theme.dart';
import '../utils/dev_link.dart';
import 'avatar.dart';

/// Abre la hoja estética de "Compartir perfil".
///
/// Devuelve el mensaje a mostrar al usuario (o `null` si se cerró sin hacer
/// nada), para que la pantalla que la invoca muestre el aviso correspondiente.
Future<String?> showProfileShareSheet(
  BuildContext context, {
  required ProfileUser profile,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (_) => ProfileShareSheet(profile: profile),
  );
}

/// Panel compacto con accesos directos a WhatsApp, Facebook, X y Telegram
/// más una opción para copiar el enlace.
class ProfileShareSheet extends StatelessWidget {
  final ProfileUser profile;

  const ProfileShareSheet({super.key, required this.profile});

  String get _link => DevLink.profileUrl(profile.username);
  String get _text => 'Mira el perfil de @${profile.username} en DevPlay';

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
      await Clipboard.setData(ClipboardData(text: '$_text\n$_link'));
      if (!context.mounted) return;
      Navigator.pop(context, 'No se pudo abrir $label. Enlace copiado');
      return;
    }
    Navigator.pop(context, 'Compartiendo en $label…');
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '$_text\n$_link'));
    if (!context.mounted) return;
    Navigator.pop(context, 'Enlace del perfil copiado');
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                color: DevColors.card.withValues(alpha: 0.6),
                child: Stack(
                  children: [
                    Positioned(
                      top: -70,
                      left: -30,
                      child: IgnorePointer(
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                DevColors.accentCyan.withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                                child: Text(
                                  'Compartir perfil',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DevTheme.display(size: 17),
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
                          const SizedBox(height: 8),
                          _Preview(profile: profile),
                          const SizedBox(height: 18),
                          Text('ENVIAR A', style: DevTheme.labelCaps()),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 14,
                            children: [
                              _ShareTarget(
                                icon: Icons.chat_bubble_rounded,
                                label: 'WhatsApp',
                                color: const Color(0xFF25D366),
                                onTap: () => _open(
                                  context,
                                  Uri.https('wa.me', '/', {
                                    'text': '$_text\n$_link',
                                  }),
                                  'WhatsApp',
                                ),
                              ),
                              _ShareTarget(
                                icon: Icons.facebook,
                                label: 'Facebook',
                                color: const Color(0xFF1877F2),
                                onTap: () => _open(
                                  context,
                                  Uri.https(
                                    'www.facebook.com',
                                    '/sharer/sharer.php',
                                    {'u': _link, 'quote': _text},
                                  ),
                                  'Facebook',
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
                                    'url': _link,
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
                                    'url': _link,
                                    'text': _text,
                                  }),
                                  'Telegram',
                                ),
                              ),
                              _ShareTarget(
                                icon: Icons.link_rounded,
                                label: 'Copiar enlace',
                                color: DevColors.accentCyan,
                                onTap: () => _copy(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
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
                                    _link,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final ProfileUser profile;

  const _Preview({required this.profile});

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
        border: Border.all(color: DevColors.accentCyan.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          UserAvatar(
            username: profile.username,
            avatar: profile.avatar,
            size: 46,
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
                const SizedBox(height: 2),
                Text(
                  '@${profile.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DevTheme.bodySecondary(size: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              gradient: DevColors.cyanGradient(),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'DevPlay',
              style: DevTheme.body(
                size: 10.5,
                w: FontWeight.w700,
                color: const Color(0xFF04121A),
              ),
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
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: _hover ? 0.26 : 0.14),
                    borderRadius: BorderRadius.circular(18),
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
                  child: Icon(widget.icon, color: color, size: 24),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: DevTheme.bodySecondary(
                    size: 11.5,
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
