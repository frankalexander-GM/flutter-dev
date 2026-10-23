import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// Hoja de descargas: APK (Android), Windows y PWA.
///
/// Los binarios viven en `web/downloads/` y se publican con
/// `tool/build_releases.ps1`; si el archivo no está, la tarjeta sale como
/// "Próximamente" en vez de dar un 404 al usuario.
Future<void> showDownloadSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => const _DownloadSheet(),
  );
}

class _DownloadSheet extends StatefulWidget {
  const _DownloadSheet();

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  final Map<String, bool> _available = {};
  bool _checking = true;

  static const _files = <String, String>{
    'android': 'downloads/devplay.apk',
    'windows': 'downloads/devplay-windows.zip',
  };

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final origin = Uri.base.origin;
    for (final entry in _files.entries) {
      var ok = false;
      try {
        final res = await http
            .head(Uri.parse('$origin/${entry.value}'))
            .timeout(const Duration(seconds: 4));
        ok = res.statusCode >= 200 && res.statusCode < 300;
      } catch (_) {
        ok = false;
      }
      _available[entry.key] = ok;
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _open(String path) async {
    final uri = Uri.parse('${Uri.base.origin}/$path');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $uri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(
            color: DevColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DevColors.accentCyan.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
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
                        color: DevColors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DevColors.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: DevColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descargar DevPlay',
                            style: DevTheme.display(size: 18),
                          ),
                          Text(
                            'Llévatela a tu móvil o a tu escritorio',
                            style: DevTheme.bodySecondary(size: 11.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
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
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    children: [
                      Expanded(
                        child: _card(
                          key: 'android',
                          icon: Icons.android_rounded,
                          title: 'Android',
                          subtitle: 'APK · instala en un toque',
                          color: const Color(0xFF3DDC84),
                          onTap: () => _open(_files['android']!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _card(
                          key: 'windows',
                          icon: Icons.window_rounded,
                          title: 'Windows',
                          subtitle: 'ZIP portable · 64 bits',
                          color: DevColors.primary,
                          onTap: () => _open(_files['windows']!),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _card(
                    key: 'android',
                    icon: Icons.android_rounded,
                    title: 'Android',
                    subtitle: 'APK · instala en un toque',
                    color: const Color(0xFF3DDC84),
                    onTap: () => _open(_files['android']!),
                  ),
                  const SizedBox(height: 10),
                  _card(
                    key: 'windows',
                    icon: Icons.window_rounded,
                    title: 'Windows',
                    subtitle: 'ZIP portable · 64 bits',
                    color: DevColors.primary,
                    onTap: () => _open(_files['windows']!),
                  ),
                ],
                const SizedBox(height: 12),
                // Instalación como app (PWA): la propia web se añade al inicio.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DevColors.accentCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DevColors.accentCyan.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.install_mobile_rounded,
                            size: 18,
                            color: DevColors.accentCyan,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Instalar como app',
                              style: DevTheme.body(
                                size: 13.5,
                                w: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DevColors.accentCyan.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'SIN TIENDA',
                              style: DevTheme.labelCaps(
                                size: 8,
                                color: DevColors.accentCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esta web ya es una app: se instala desde el navegador '
                        'y queda con su icono, a pantalla completa.',
                        style: DevTheme.body(
                          size: 11.5,
                          height: 1.4,
                          color: DevColors.mutedFg,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _InstallStep(
                        icon: Icons.android_rounded,
                        text: 'Android: menú ⋮ → "Instalar app"',
                      ),
                      const _InstallStep(
                        icon: Icons.phone_iphone_rounded,
                        text: 'iPhone: Compartir → "Añadir a inicio"',
                      ),
                      const _InstallStep(
                        icon: Icons.desktop_windows_rounded,
                        text: 'PC (Chrome/Edge): icono de instalar en la barra',
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: Uri.base.origin),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enlace copiado'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.link_rounded, size: 15),
                          label: Text(
                            'Copiar enlace de la app',
                            style: DevTheme.body(
                              size: 12,
                              w: FontWeight.w600,
                              color: DevColors.accentCyan,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: DevColors.accentCyan,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DevColors.cardRaised.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DevColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los binarios se generan con '
                          'tool/build_releases.ps1 y se publican en '
                          'web/downloads/. Si una tarjeta dice "Próximamente", '
                          'todavía no hay build publicado.',
                          style: DevTheme.body(
                            size: 11,
                            height: 1.4,
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
    );
  }

  Widget _card({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final ready = _available[key] ?? false;
    final enabled = !_checking && ready;

    return Opacity(
      opacity: _checking ? 0.6 : (ready ? 1 : 0.75),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DevColors.cardRaised.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _checking
                            ? 'Comprobando…'
                            : (ready ? subtitle : 'Próximamente'),
                        style: DevTheme.bodySecondary(size: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  ready ? Icons.download_rounded : Icons.schedule_rounded,
                  size: 20,
                  color: enabled ? color : DevColors.disabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Línea de instrucciones para instalar la PWA.
class _InstallStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstallStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: DevColors.mutedFg),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: DevTheme.bodySecondary(size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
