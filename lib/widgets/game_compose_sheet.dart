import 'package:flutter/material.dart';

import '../services/media_service.dart';
import '../services/post_service.dart';
import '../theme.dart';

Future<bool?> showGameComposeSheet(BuildContext context) {
  final isWide = MediaQuery.sizeOf(context).width >= 760;

  if (isWide) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: size.height * 0.9,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: const GameComposeSheet(),
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DevColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final size = MediaQuery.sizeOf(sheetContext);
      return SizedBox(
        height: size.height * 0.94,
        child: const GameComposeSheet(),
      );
    },
  );
}

class GameComposeSheet extends StatefulWidget {
  const GameComposeSheet({super.key});

  @override
  State<GameComposeSheet> createState() => _GameComposeSheetState();
}

class _GameComposeSheetState extends State<GameComposeSheet> {
  static const _genres = [
    'Acción',
    'Aventura',
    'RPG',
    'Shooter',
    'Estrategia',
    'Puzzle',
    'Plataformas',
    'Simulación',
    'Terror',
    'Casual',
    'Indie',
    'Otro',
  ];

  static const _statuses = [
    'En desarrollo',
    'Beta abierta',
    'Beta cerrada',
    'Early access',
    'Próximamente',
    'Lanzado',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _playUrl = TextEditingController();
  final _tags = TextEditingController();

  String _genre = 'Indie';
  String _status = 'En desarrollo';
  UploadedMedia? _cover;
  bool _uploadingCover = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _playUrl.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    if (_uploadingCover) return;
    setState(() {
      _error = null;
      _uploadingCover = true;
    });
    try {
      final media = await MediaService.pickAndUpload();
      if (!mounted || media == null) return;
      if (media.isVideo) {
        setState(() => _error = 'La portada debe ser una imagen.');
        return;
      }
      setState(() => _cover = media);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo subir la portada: $e');
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  String _composeContent() {
    final lines = <String>[
      _title.text.trim(),
      '',
      _description.text.trim(),
      '',
      'Género: $_genre · Estado: $_status',
    ];
    final url = _playUrl.text.trim();
    if (url.isNotEmpty) lines.add('Jugar: $url');
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t : '#$t')
        .join(' ');
    if (tags.isNotEmpty) lines.add(tags);
    return lines.join('\n');
  }

  Future<void> _publish() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PostService.createPost(
        content: _composeContent(),
        type: 'GAME_SHOWCASE',
        media: [
          if (_cover != null) {'url': _cover!.url, 'kind': 'image'},
        ],
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo publicar: $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DevColors.card,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      icon: Icons.sports_esports_rounded,
                      title: 'Ficha del juego',
                      subtitle:
                          'Se publicará en Descubrir como juego destacado.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _title,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del juego *',
                        hintText: 'Ej. Astro Bakery',
                        counterText: '',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 3) {
                          return 'Escribe un nombre de al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _description,
                      maxLines: 4,
                      maxLength: 600,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText: '¿De qué trata? ¿Qué lo hace especial?',
                      ),
                      validator: (value) {
                        if ((value?.trim() ?? '').length < 10) {
                          return 'Cuéntanos un poco más (mín. 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 480;
                        final genre = DropdownButtonFormField<String>(
                          initialValue: _genre,
                          dropdownColor: DevColors.card,
                          style: DevTheme.body(size: 13),
                          decoration: const InputDecoration(
                            labelText: 'Género',
                          ),
                          items: _genres
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _genre = value);
                          },
                        );
                        final status = DropdownButtonFormField<String>(
                          initialValue: _status,
                          dropdownColor: DevColors.card,
                          style: DevTheme.body(size: 13),
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: _statuses
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _status = value);
                          },
                        );
                        if (!wide) {
                          return Column(
                            children: [
                              genre,
                              const SizedBox(height: 14),
                              status,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: genre),
                            const SizedBox(width: 12),
                            Expanded(child: status),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _coverPicker(),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _playUrl,
                      keyboardType: TextInputType.url,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Enlace para jugar',
                        hintText: 'https://…',
                        counterText: '',
                        prefixIcon: Icon(Icons.link_rounded, size: 20),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final uri = Uri.tryParse(text);
                        if (uri == null ||
                            !uri.hasScheme ||
                            !uri.hasAuthority) {
                          return 'Escribe una URL válida (https://…)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tags,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Etiquetas',
                        hintText: 'indie, pixel art, multijugador',
                        counterText: '',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DevColors.destructive.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: DevColors.destructive.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: DevTheme.bodySecondary(
                            size: 12,
                            color: DevColors.destructive,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DevColors.cardRaised, DevColors.card.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(bottom: BorderSide(color: DevColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DevColors.accentOrange.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DevColors.accentOrange.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: DevColors.accentOrange,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publicar un juego',
                  style: DevTheme.display(size: 20, w: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Showcase · portada · enlace jugable',
                  style: DevTheme.bodySecondary(size: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, color: DevColors.mutedFg),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: DevColors.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: DevColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DevTheme.display(size: 16, w: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: DevTheme.bodySecondary(size: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverPicker() {
    final cover = _cover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portada', style: DevTheme.body(size: 12, w: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _uploadingCover ? null : _pickCover,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: DevColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cover != null
                        ? DevColors.accentCyan.withValues(alpha: 0.55)
                        : DevColors.border,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover != null)
                      Image.network(cover.url, fit: BoxFit.cover)
                    else
                      Center(
                        child: _uploadingCover
                            ? const CircularProgressIndicator(
                                color: DevColors.accentCyan,
                                strokeWidth: 2.5,
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 34,
                                    color: DevColors.mutedFg.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Subir portada (16:9)',
                                    style: DevTheme.body(
                                      size: 12.5,
                                      w: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'JPG, PNG o WEBP · máx. 10 MB',
                                    style: DevTheme.bodySecondary(size: 10.5),
                                  ),
                                ],
                              ),
                      ),
                    if (cover != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _CoverAction(label: 'Cambiar', onTap: _pickCover),
                            const SizedBox(width: 6),
                            _CoverAction(
                              label: 'Quitar',
                              onTap: () => setState(() => _cover = null),
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
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _PublishButton(saving: _saving, onTap: _publish),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CoverAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: DevTheme.body(
              size: 10.5,
              w: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishButton extends StatefulWidget {
  final bool saving;
  final VoidCallback onTap;

  const _PublishButton({required this.saving, required this.onTap});

  @override
  State<_PublishButton> createState() => _PublishButtonState();
}

class _PublishButtonState extends State<_PublishButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.saving;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5E00), Color(0xFFFF8700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF5E00)
                          .withValues(alpha: _hover ? 0.6 : 0.4),
                      blurRadius: _hover ? 22 : 15,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.saving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.rocket_launch_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.saving ? 'Publicando…' : 'Publicar juego',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DevTheme.body(
                    size: 13,
                    w: FontWeight.w700,
                    color: Colors.white,
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
