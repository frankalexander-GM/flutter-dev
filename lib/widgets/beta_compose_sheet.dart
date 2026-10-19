import 'package:flutter/material.dart';

import '../services/beta_service.dart';
import '../theme.dart';

/// Abre el formulario para publicar una beta.
/// Devuelve `true` si la beta se creó correctamente.
Future<bool?> showBetaComposeSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DevColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const BetaComposeSheet(),
  );
}

class BetaComposeSheet extends StatefulWidget {
  const BetaComposeSheet({super.key});

  @override
  State<BetaComposeSheet> createState() => _BetaComposeSheetState();
}

class _BetaComposeSheetState extends State<BetaComposeSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _version = TextEditingController();
  final _genre = TextEditingController();
  final _link = TextEditingController();
  final _cover = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _version.dispose();
    _genre.dispose();
    _link.dispose();
    _cover.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    final link = _link.text.trim();

    if (title.length < 3) {
      setState(() => _error = 'El título debe tener al menos 3 caracteres.');
      return;
    }
    if (description.isEmpty) {
      setState(() => _error = 'Añade una descripción para los testers.');
      return;
    }
    if (link.isNotEmpty &&
        !(link.startsWith('http://') || link.startsWith('https://'))) {
      setState(() => _error = 'El enlace debe empezar por http:// o https://');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await BetaService.createBeta(
        title: title,
        description: description,
        downloadType: 'LINK',
        externalUrl: link.isEmpty ? null : link,
        version: _version.text.trim().isEmpty ? null : _version.text.trim(),
        genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
        coverImage: _cover.text.trim().isEmpty ? null : _cover.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DevColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: DevColors.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subir beta',
                        style: DevTheme.display(size: 20, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Comparte tu build y encuentra testers.',
                        style: DevTheme.bodySecondary(size: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded, color: DevColors.mutedFg),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Field(
              controller: _title,
              label: 'Título',
              hint: 'Ej. Mi juego de plataformas',
              maxLength: 120,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _description,
              label: 'Descripción',
              hint: '¿De qué trata y qué feedback buscas?',
              maxLines: 4,
              maxLength: 8000,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _version,
                    label: 'Versión',
                    hint: 'v0.1.0',
                    maxLength: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _genre,
                    label: 'Género',
                    hint: 'Plataformas',
                    maxLength: 64,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _link,
              label: 'Enlace de descarga (opcional)',
              hint: 'https://...',
              keyboardType: TextInputType.url,
              maxLength: 500,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _cover,
              label: 'Portada (URL, opcional)',
              hint: 'https://...',
              keyboardType: TextInputType.url,
              maxLength: 500,
            ),
            const SizedBox(height: 10),
            Text(
              'Tu beta se publica también en el feed de la comunidad.',
              style: DevTheme.bodySecondary(size: 11),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DevColors.destructive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DevColors.destructive.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _error!,
                  style: DevTheme.body(size: 12, color: DevColors.destructive),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(
                  _saving ? 'Publicando...' : 'Publicar beta',
                  style: DevTheme.body(
                    size: 14,
                    w: FontWeight.w700,
                    color: DevColors.primaryFg,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.primary,
                  foregroundColor: DevColors.primaryFg,
                  disabledBackgroundColor:
                      DevColors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: DevTheme.body(size: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        labelStyle: DevTheme.body(size: 12.5, color: DevColors.mutedFg),
        hintStyle: DevTheme.body(
          size: 13,
          color: DevColors.mutedFg.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: DevColors.muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DevColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DevColors.primary),
        ),
      ),
    );
  }
}
