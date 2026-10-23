import 'dart:async';

import 'package:flutter/material.dart';

import '../services/beta_service.dart';
import '../theme.dart';

/// Abre el formulario para publicar una beta.
/// Devuelve `true` si la beta se creó correctamente.
Future<bool?> showBetaComposeSheet(BuildContext context) {
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
              maxWidth: 560,
              maxHeight: size.height * 0.82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: const BetaComposeSheet(),
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
        height: size.height * 0.80,
        child: const BetaComposeSheet(),
      );
    },
  );
}

class BetaComposeSheet extends StatefulWidget {
  const BetaComposeSheet({super.key});

  @override
  State<BetaComposeSheet> createState() => _BetaComposeSheetState();
}

class _BetaComposeSheetState extends State<BetaComposeSheet> {
  static const _steps = ['Info', 'Media', 'Entrega', 'Normas'];

  static const _statuses = <String, (String, String)>{
    'open_beta': ('Beta abierta', 'Cualquiera puede probarla'),
    'closed_beta': ('Beta cerrada', 'Solo testers invitados'),
    'alpha': ('Alpha', 'Build muy temprano'),
    'tech_test': ('Test técnico', 'Pruebas de rendimiento'),
    'early_access': ('Early access', 'Contenido casi final'),
    'coming_soon': ('Próximamente', 'Aún sin build pública'),
    'ended': ('Finalizada', 'La beta ya terminó'),
  };

  static const _platformOptions = [
    'PC',
    'Windows',
    'macOS',
    'Linux',
    'Android',
    'iOS',
    'Web',
    'Steam Deck',
    'Consola',
    'VR',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _version = TextEditingController();
  final _genre = TextEditingController();
  final _cover = TextEditingController();
  final _externalUrl = TextEditingController();
  final _fileUrl = TextEditingController();
  final _fileName = TextEditingController();
  final _fileSizeMb = TextEditingController();
  final _externalPlatform = TextEditingController();
  final _requirements = TextEditingController();
  final _installInstructions = TextEditingController();
  final _changelog = TextEditingController();
  final _tagController = TextEditingController();
  final List<TextEditingController> _screenshots = [];

  final List<String> _tags = [];
  final Set<String> _platforms = {'PC'};

  int _step = 0;
  String _status = 'open_beta';
  String _downloadType = 'LINK';
  bool _rights = false;
  bool _safeBuild = false;
  bool _rules = false;
  bool _saving = false;
  String? _formError;
  String? _tagError;
  String _coverPreviewUrl = '';
  Timer? _coverDebounce;

  @override
  void dispose() {
    _coverDebounce?.cancel();
    for (final controller in [
      _title,
      _description,
      _version,
      _genre,
      _cover,
      _externalUrl,
      _fileUrl,
      _fileName,
      _fileSizeMb,
      _externalPlatform,
      _requirements,
      _installInstructions,
      _changelog,
      _tagController,
      ..._screenshots,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------ utils

  String? _required(String? value, {int min = 1, int max = 9999}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Este campo es obligatorio';
    if (text.length < min) return 'Mínimo $min caracteres';
    if (text.length > max) return 'Máximo $max caracteres';
    return null;
  }

  String? _optionalUrl(String? value, {bool required = false}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return required ? 'Este campo es obligatorio' : null;
    return _urlError(text);
  }

  String? _urlError(String text) {
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Usa una URL válida (http:// o https://)';
    }
    return null;
  }

  String? _optionalText(String? value, int max) {
    final text = (value ?? '').trim();
    if (text.length > max) return 'Máximo $max caracteres';
    return null;
  }

  String? _fileSizeError(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final mb = double.tryParse(text.replaceAll(',', '.'));
    if (mb == null || mb <= 0) return 'Indica un tamaño mayor que 0';
    if (mb > 50 * 1024) return 'El tamaño máximo es 50 GB';
    return null;
  }

  void _onCoverChanged(String value) {
    _coverDebounce?.cancel();
    _coverDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _coverPreviewUrl = value.trim());
    });
  }

  void _addTag() {
    final raw = _tagController.text.trim().replaceAll('#', '');
    if (raw.isEmpty) return;
    final tag = raw.replaceAll(RegExp(r'\s+'), '-').toLowerCase();
    if (tag.length > 20) {
      setState(() => _tagError = 'Cada etiqueta admite 20 caracteres');
      return;
    }
    if (_tags.length >= 15) {
      setState(() => _tagError = 'Máximo 15 etiquetas');
      return;
    }
    if (!_tags.contains(tag)) setState(() => _tags.add(tag));
    _tagController.clear();
    setState(() => _tagError = null);
  }

  void _addScreenshot() {
    if (_screenshots.length >= 10) return;
    setState(() => _screenshots.add(TextEditingController()));
  }

  void _removeScreenshot(int index) {
    setState(() => _screenshots.removeAt(index).dispose());
  }

  // -------------------------------------------------------------- navigation

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 2 && _platforms.isEmpty) {
      setState(() => _formError = 'Selecciona al menos una plataforma.');
      return;
    }
    if (_step < _steps.length - 1) setState(() => _step++);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_saving) return;
    setState(() {
      _formError = null;
      if (_step > 0) _step--;
    });
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);

    if (!_rights || !_safeBuild || !_rules) {
      setState(
        () =>
            _formError = 'Debes aceptar los tres protocolos antes de publicar.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final externalUrl = _externalUrl.text.trim();
    final fileUrl = _fileUrl.text.trim();
    if (_downloadType == 'LINK' && externalUrl.isEmpty) {
      setState(() => _formError = 'Añade el enlace de descarga externo.');
      return;
    }
    if (_downloadType == 'DIRECT' && fileUrl.isEmpty) {
      setState(() => _formError = 'Añade la URL del archivo directo.');
      return;
    }

    final sizeMb = double.tryParse(
      _fileSizeMb.text.trim().replaceAll(',', '.'),
    );
    final screenshots = _screenshots
        .map((controller) => controller.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    setState(() => _saving = true);
    try {
      await BetaService.createBeta(
        title: _title.text.trim(),
        description: _description.text.trim(),
        betaStatus: _status,
        downloadType: _downloadType,
        externalUrl: _downloadType == 'LINK' && externalUrl.isNotEmpty
            ? externalUrl
            : null,
        fileUrl: _downloadType == 'DIRECT' && fileUrl.isNotEmpty
            ? fileUrl
            : null,
        fileSize: sizeMb == null ? null : (sizeMb * 1024 * 1024).round(),
        fileName: _fileName.text.trim().isEmpty ? null : _fileName.text.trim(),
        version: _version.text.trim().isEmpty ? null : _version.text.trim(),
        genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
        coverImage: _cover.text.trim().isEmpty ? null : _cover.text.trim(),
        platforms: _platforms.toList(),
        tags: _tags,
        screenshots: screenshots,
        requirements: _requirements.text.trim().isEmpty
            ? null
            : _requirements.text.trim(),
        changelog: _changelog.text.trim().isEmpty
            ? null
            : _changelog.text.trim(),
        installInstructions: _installInstructions.text.trim().isEmpty
            ? null
            : _installInstructions.text.trim(),
        externalPlatform: _externalPlatform.text.trim().isEmpty
            ? null
            : _externalPlatform.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e.toString();
      });
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Material(
        color: DevColors.card,
        child: Column(
          children: [
            _buildHeader(),
            _buildStepper(),
            const Divider(color: DevColors.border, height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: switch (_step) {
                            0 => _buildInfoStep(),
                            1 => _buildMediaStep(),
                            2 => _buildDeliveryStep(),
                            _ => _buildRulesStep(),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 10, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DevColors.primary.withValues(alpha: 0.20),
            DevColors.gold.withValues(alpha: 0.10),
            DevColors.card,
          ],
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
              color: DevColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DevColors.gold.withValues(alpha: 0.45)),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: DevColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publicar beta',
                  style: DevTheme.display(size: 20, w: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Build · feedback · comunidad',
                  style: DevTheme.bodySecondary(size: 11.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: DevColors.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: DevColors.border),
            ),
            child: Text(
              '${_step + 1}/${_steps.length}',
              style: DevTheme.body(size: 10.5, color: DevColors.goldSoft),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, color: DevColors.mutedFg),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                _StepDot(number: i + 1, active: i == _step, done: i < _step),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: i < _step ? DevColors.gold : DevColors.border,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _steps[i],
                      style: DevTheme.body(
                        size: 9.5,
                        w: i == _step ? FontWeight.w700 : FontWeight.w400,
                        color: i == _step
                            ? DevColors.foreground
                            : DevColors.mutedFg,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- steps

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          icon: Icons.edit_note_rounded,
          title: 'Cuéntanos qué estás construyendo',
          subtitle: 'Este texto aparecerá en la ficha de la beta y en el feed.',
        ),
        const SizedBox(height: 16),
        _BetaField(
          controller: _title,
          label: 'Título *',
          hint: 'Ej. Astro Bakery',
          maxLength: 120,
          textInputAction: TextInputAction.next,
          validator: (value) => _required(value, min: 3, max: 120),
        ),
        const SizedBox(height: 14),
        _BetaField(
          controller: _description,
          label: 'Descripción *',
          hint: '¿De qué trata? ¿Qué feedback necesitas de los testers?',
          maxLines: 3,
          maxLength: 8000,
          showCounter: false,
          validator: (value) => _required(value, max: 8000),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final version = _BetaField(
              controller: _version,
              label: 'Versión',
              hint: 'v0.1.0',
              maxLength: 32,
              textInputAction: TextInputAction.next,
              validator: (value) => _optionalText(value, 32),
            );
            final genre = _BetaField(
              controller: _genre,
              label: 'Género',
              hint: 'Plataformas, RPG, terror…',
              maxLength: 64,
              textInputAction: TextInputAction.next,
              validator: (value) => _optionalText(value, 64),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: version),
                      const SizedBox(width: 12),
                      Expanded(child: genre),
                    ],
                  )
                : Column(
                    children: [version, const SizedBox(height: 14), genre],
                  );
          },
        ),
        const SizedBox(height: 16),
        _InfoBanner(
          icon: Icons.info_outline_rounded,
          text: 'La beta se publica como un post de tipo BETA. El título y la descripción también se verán en el feed.',
        ),
      ],
    );
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          icon: Icons.image_rounded,
          title: 'Presentación visual',
          subtitle: 'Una portada y capturas ayudan a que encuentren tu beta.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final coverFields = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BetaField(
                  controller: _cover,
                  label: 'Portada (URL)',
                  hint: 'https://…/portada.jpg',
                  keyboardType: TextInputType.url,
                  maxLength: 500,
                  onChanged: _onCoverChanged,
                  validator: (value) => _optionalUrl(value),
                ),
                const SizedBox(height: 14),
                _label('Capturas (URL)'),
                if (_screenshots.isEmpty)
                  Text(
                    'Puedes añadir hasta 10 capturas.',
                    style: DevTheme.bodySecondary(size: 11),
                  ),
                ...List.generate(_screenshots.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _BetaField(
                            controller: _screenshots[index],
                            label: 'Captura ${index + 1}',
                            hint: 'https://…/captura.png',
                            keyboardType: TextInputType.url,
                            maxLength: 500,
                            validator: (value) => _optionalUrl(value),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Quitar captura',
                          onPressed: () => _removeScreenshot(index),
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 19,
                            color: DevColors.destructive,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_screenshots.length < 10)
                  TextButton.icon(
                    onPressed: _addScreenshot,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'Añadir captura',
                      style: DevTheme.body(size: 12),
                    ),
                  ),
              ],
            );
            final preview = _CoverPreview(url: _coverPreviewUrl);
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: coverFields),
                      const SizedBox(width: 18),
                      SizedBox(width: 240, child: preview),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      coverFields,
                      const SizedBox(height: 16),
                      preview,
                    ],
                  );
          },
        ),
        const SizedBox(height: 18),
        _label('Etiquetas'),
        Text(
          'Máximo 15. Ayudan a encontrar tu beta por tema.',
          style: DevTheme.bodySecondary(size: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BetaField(
                controller: _tagController,
                label: 'Añadir etiqueta',
                hint: 'rpg, pixel-art, multijugador…',
                maxLength: 20,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _addTag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.muted,
                  foregroundColor: DevColors.foreground,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.add_rounded, size: 18),
              ),
            ),
          ],
        ),
        if (_tagError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _tagError!,
              style: DevTheme.body(size: 11, color: DevColors.destructive),
            ),
          ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag', style: DevTheme.body(size: 11)),
                    backgroundColor: DevColors.muted,
                    side: const BorderSide(color: DevColors.border),
                    deleteIcon: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: DevColors.mutedFg,
                    ),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDeliveryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          icon: Icons.rocket_launch_rounded,
          title: 'Distribución',
          subtitle:
              'Define el estado, la plataforma y cómo llegarán los testers.',
        ),
        const SizedBox(height: 16),
        _label('Estado de la beta'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _statuses.entries.map((entry) {
            final selected = _status == entry.key;
            return _ChoicePill(
              label: entry.value.$1,
              selected: selected,
              onTap: () => setState(() => _status = entry.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _label('Tipo de entrega'),
        Row(
          children: [
            Expanded(
              child: _DeliveryCard(
                icon: Icons.link_rounded,
                title: 'Enlace externo',
                subtitle: 'itch.io, Drive, Steam…',
                selected: _downloadType == 'LINK',
                onTap: () => setState(() => _downloadType = 'LINK'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DeliveryCard(
                icon: Icons.file_download_outlined,
                title: 'Archivo directo',
                subtitle: 'URL al build',
                selected: _downloadType == 'DIRECT',
                onTap: () => setState(() => _downloadType = 'DIRECT'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_downloadType == 'LINK') ...[
          _BetaField(
            controller: _externalUrl,
            label: 'Enlace de descarga *',
            hint: 'https://itch.io/tu-juego',
            keyboardType: TextInputType.url,
            maxLength: 500,
            validator: (value) => _optionalUrl(value, required: true),
          ),
          const SizedBox(height: 14),
          _BetaField(
            controller: _externalPlatform,
            label: 'Plataforma del enlace',
            hint: 'itch.io, Steam, Google Drive…',
            maxLength: 64,
            validator: (value) => _optionalText(value, 64),
          ),
        ] else ...[
          _BetaField(
            controller: _fileUrl,
            label: 'URL del archivo *',
            hint: 'https://…/build.zip',
            keyboardType: TextInputType.url,
            maxLength: 500,
            validator: (value) => _optionalUrl(value, required: true),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final name = _BetaField(
                controller: _fileName,
                label: 'Nombre del archivo',
                hint: 'mi-juego-v0.1.0.zip',
                maxLength: 255,
                validator: (value) => _optionalText(value, 255),
              );
              final size = _BetaField(
                controller: _fileSizeMb,
                label: 'Tamaño (MB)',
                hint: '250',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _fileSizeError,
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: 12),
                        Expanded(child: size),
                      ],
                    )
                  : Column(children: [name, const SizedBox(height: 14), size]);
            },
          ),
        ],
        const SizedBox(height: 16),
        _label('Plataformas'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _platformOptions.map((platform) {
            final selected = _platforms.contains(platform);
            return _ChoicePill(
              label: platform,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _platforms.remove(platform);
                  } else if (_platforms.length < 10) {
                    _platforms.add(platform);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _InfoBanner(
          icon: Icons.shield_outlined,
          text: 'El enlace debe funcionar para los testers. El backend registra las descargas y suma al contador de la beta.',
        ),
      ],
    );
  }

  Widget _buildRulesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          icon: Icons.fact_check_rounded,
          title: 'Revisión y protocolo',
          subtitle: 'Revisa el resumen y confirma las normas de publicación.',
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: _title.text.trim().isEmpty ? 'Tu beta' : _title.text.trim(),
          description: _description.text.trim(),
          coverUrl: _cover.text.trim(),
          version: _version.text.trim(),
          genre: _genre.text.trim(),
          status: _statuses[_status]!.$1,
          delivery: _downloadType == 'LINK'
              ? 'Enlace externo'
              : 'Archivo directo',
          url: _downloadType == 'LINK'
              ? _externalUrl.text.trim()
              : _fileUrl.text.trim(),
          platforms: _platforms.toList(),
          tags: _tags,
        ),
        const SizedBox(height: 18),
        _label('Material para testers (opcional)'),
        _BetaField(
          controller: _requirements,
          label: 'Requisitos',
          hint: 'SO, RAM, GPU, espacio en disco…',
          maxLines: 4,
          maxLength: 4000,
          showCounter: false,
          validator: (value) => _optionalText(value, 4000),
        ),
        const SizedBox(height: 14),
        _BetaField(
          controller: _installInstructions,
          label: 'Instrucciones de instalación',
          hint: 'Cómo descomprimir, ejecutar, reportar bugs…',
          maxLines: 4,
          maxLength: 4000,
          showCounter: false,
          validator: (value) => _optionalText(value, 4000),
        ),
        const SizedBox(height: 14),
        _BetaField(
          controller: _changelog,
          label: 'Novedades de esta versión',
          hint: 'Qué cambia respecto a la anterior…',
          maxLines: 4,
          maxLength: 8000,
          showCounter: false,
          validator: (value) => _optionalText(value, 8000),
        ),
        const SizedBox(height: 18),
        _label('Protocolos de publicación'),
        _ProtocolCheck(
          value: _rights,
          title: 'Derechos de distribución',
          description: 'Confirmo que soy el autor o tengo permiso para distribuir este build.',
          onChanged: (value) => setState(() => _rights = value),
        ),
        const SizedBox(height: 8),
        _ProtocolCheck(
          value: _safeBuild,
          title: 'Build seguro',
          description: 'El enlace o archivo funciona y no contiene malware ni contenido prohibido.',
          onChanged: (value) => setState(() => _safeBuild = value),
        ),
        const SizedBox(height: 8),
        _ProtocolCheck(
          value: _rules,
          title: 'Normas de la comunidad',
          description: 'Acepto las normas de DevPlay y entiendo que la ficha será pública.',
          onChanged: (value) => setState(() => _rules = value),
        ),
        const SizedBox(height: 12),
        _InfoBanner(
          icon: Icons.timer_outlined,
          text: 'Límite de publicación: 10 betas por hora por cuenta. La beta aparecerá también en el feed.',
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ footer

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_formError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DevColors.destructive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DevColors.destructive.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: DevColors.destructive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formError!,
                      style: DevTheme.body(
                        size: 11.5,
                        color: DevColors.destructive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final stepLabel = Text(
                'Paso ${_step + 1} de ${_steps.length}',
                style: DevTheme.bodySecondary(size: 10.5),
              );
              final backButton = OutlinedButton(
                onPressed: _saving ? null : _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DevColors.mutedFg,
                  side: const BorderSide(color: DevColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text('Atrás'),
              );
              final nextButton = ElevatedButton.icon(
                onPressed: _saving
                    ? null
                    : (_step == _steps.length - 1 ? _publish : _next),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _step == _steps.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        size: 17,
                      ),
                label: Text(
                  _saving
                      ? 'Publicando…'
                      : (_step == _steps.length - 1
                            ? 'Publicar beta'
                            : 'Siguiente'),
                  style: DevTheme.body(
                    size: 13,
                    w: FontWeight.w700,
                    color: DevColors.primaryFg,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.primary,
                  foregroundColor: DevColors.primaryFg,
                  disabledBackgroundColor: DevColors.primary.withValues(
                    alpha: 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              );

              // En móvil el pie se parte en dos filas para que los botones
              // nunca se salgan del ancho disponible.
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        stepLabel,
                        const Spacer(),
                        if (_step == 0) nextButton,
                      ],
                    ),
                    if (_step > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: backButton),
                          const SizedBox(width: 8),
                          Expanded(child: nextButton),
                        ],
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  stepLabel,
                  const Spacer(),
                  if (_step > 0) backButton,
                  if (_step > 0) const SizedBox(width: 8),
                  nextButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stepTitle({
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: DevTheme.body(size: 12, w: FontWeight.w600)),
  );
}

// --------------------------------------------------------------------- pieces

class _StepDot extends StatelessWidget {
  final int number;
  final bool active;
  final bool done;

  const _StepDot({
    required this.number,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? DevColors.gold
        : active
        ? DevColors.primary
        : DevColors.border;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done || active ? color.withValues(alpha: 0.16) : DevColors.muted,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: DevColors.gold)
          : Text(
              '$number',
              style: DevTheme.body(
                size: 10.5,
                w: FontWeight.w700,
                color: active ? DevColors.primary : DevColors.mutedFg,
              ),
            ),
    );
  }
}

class _BetaField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  const _BetaField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: DevTheme.body(size: 13.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: showCounter ? null : '',
        labelStyle: DevTheme.body(size: 12.5, color: DevColors.mutedFg),
        hintStyle: DevTheme.body(
          size: 12.5,
          color: DevColors.mutedFg.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: DevColors.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: DevColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: DevColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: DevColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: DevColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: DevColors.destructive),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DevColors.cardRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DevColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: DevColors.gold),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: DevTheme.bodySecondary(size: 11.5)),
          ),
        ],
      ),
    );
  }
}

bool _isWebUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

class _CoverPreview extends StatelessWidget {
  final String url;

  const _CoverPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    final valid = _isWebUrl(url);
    return Container(
      decoration: BoxDecoration(
        color: DevColors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DevColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: valid
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Text(
              valid ? 'Vista previa de portada' : 'Añade una URL de portada',
              style: DevTheme.bodySecondary(size: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: DevColors.muted,
    child: const Center(
      child: Icon(Icons.image_outlined, color: DevColors.mutedFg, size: 30),
    ),
  );
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? DevColors.primary.withValues(alpha: 0.16)
              : DevColors.muted,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? DevColors.primary : DevColors.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 12,
                color: DevColors.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: DevTheme.body(
                size: 11.5,
                w: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? DevColors.primary : DevColors.mutedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? DevColors.primary.withValues(alpha: 0.12)
              : DevColors.muted,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? DevColors.primary : DevColors.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? DevColors.primary : DevColors.mutedFg,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: DevTheme.body(
                size: 12,
                w: FontWeight.w700,
                color: selected ? DevColors.foreground : DevColors.mutedFg,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: DevTheme.bodySecondary(size: 10)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String description;
  final String coverUrl;
  final String version;
  final String genre;
  final String status;
  final String delivery;
  final String url;
  final List<String> platforms;
  final List<String> tags;

  const _SummaryCard({
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.version,
    required this.genre,
    required this.status,
    required this.delivery,
    required this.url,
    required this.platforms,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = _isWebUrl(coverUrl);
    return Container(
      decoration: BoxDecoration(
        color: DevColors.cardRaised,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: DevColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCover)
            AspectRatio(
              aspectRatio: 16 / 6,
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: DevColors.muted,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: DevColors.mutedFg,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DevTheme.display(size: 16, w: FontWeight.w700),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: DevTheme.bodySecondary(size: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniTag(label: status, color: DevColors.gold),
                    if (version.isNotEmpty)
                      _MiniTag(label: version, color: DevColors.primary),
                    if (genre.isNotEmpty)
                      _MiniTag(label: genre, color: DevColors.mutedFg),
                    _MiniTag(label: delivery, color: DevColors.mutedFg),
                  ],
                ),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 13,
                        color: DevColors.mutedFg,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          url,
                          style: DevTheme.bodySecondary(size: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (platforms.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    'Plataformas: ${platforms.join(' · ')}',
                    style: DevTheme.bodySecondary(size: 10.5),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    tags.map((tag) => '#$tag').join('  '),
                    style: DevTheme.bodySecondary(size: 10.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: DevTheme.body(size: 9.5, color: color)),
    );
  }
}

class _ProtocolCheck extends StatelessWidget {
  final bool value;
  final String title;
  final String description;
  final ValueChanged<bool> onChanged;

  const _ProtocolCheck({
    required this.value,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: value
              ? DevColors.consoleGreen.withValues(alpha: 0.07)
              : DevColors.muted,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: value
                ? DevColors.consoleGreen.withValues(alpha: 0.45)
                : DevColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              activeColor: DevColors.primary,
              checkColor: DevColors.primaryFg,
              side: const BorderSide(color: DevColors.mutedFg),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DevTheme.body(size: 12, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: DevTheme.bodySecondary(size: 10.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
