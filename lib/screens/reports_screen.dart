import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../theme.dart';

/// Formulario de reportes comunitarios.
///
/// Usa el endpoint real `POST /security/report`. El backend todavía no expone
/// un historial de reportes ni una cola de moderación, por eso esta pantalla no
/// inventa listas: solo envía reportes y lo explica.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _reasons = <String, String>{
    'spam': 'Spam o promocional',
    'harassment': 'Acoso',
    'inappropriate': 'Contenido inapropiado',
    'impersonation': 'Suplantación de identidad',
    'other': 'Otro',
  };

  final _entityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _entityType = 'POST';
  String _reason = 'spam';
  bool _sending = false;

  @override
  void dispose() {
    _entityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _sending) return;
    setState(() => _sending = true);
    try {
      await PostService.reportContent(
        entityId: _entityController.text.trim(),
        entityType: _entityType,
        reason: _reason,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _sending = false);
      _entityController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado. Gracias por ayudar.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el reporte: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.card,
        elevation: 0,
        title: Text('Reportes', style: DevTheme.display(size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: DevTheme.glassStrong(radius: 12),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: DevColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reporta publicaciones, usuarios, comentarios o betas que incumplan las normas.',
                    style: DevTheme.bodySecondary(size: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Tipo de contenido'),
                DropdownButtonFormField<String>(
                  initialValue: _entityType,
                  dropdownColor: DevColors.card,
                  style: DevTheme.body(size: 13),
                  decoration: _inputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'POST', child: Text('Publicación')),
                    DropdownMenuItem(value: 'USER', child: Text('Usuario')),
                    DropdownMenuItem(
                      value: 'COMMENT',
                      child: Text('Comentario'),
                    ),
                    DropdownMenuItem(value: 'BETA', child: Text('Beta')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _entityType = value);
                  },
                ),
                const SizedBox(height: 14),
                _label('ID del contenido'),
                TextFormField(
                  controller: _entityController,
                  style: DevTheme.body(size: 13),
                  decoration: _inputDecoration(
                    hint: 'Pega el ID de la publicación, usuario, comentario o beta',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Indica el ID del contenido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _label('Motivo'),
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  dropdownColor: DevColors.card,
                  style: DevTheme.body(size: 13),
                  decoration: _inputDecoration(),
                  items: _reasons.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _reason = value);
                  },
                ),
                const SizedBox(height: 14),
                _label('Descripción (opcional)'),
                TextFormField(
                  controller: _descriptionController,
                  style: DevTheme.body(size: 13),
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: _inputDecoration(hint: 'Cuéntanos qué pasó…'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DevColors.primary,
                      foregroundColor: DevColors.primaryFg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Enviar reporte',
                            style: DevTheme.body(size: 13, w: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DevColors.cardRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DevColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: DevColors.mutedFg,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La API todavía no expone el historial de reportes ni la cola de moderación. '
                    'Por eso aquí solo se envían reportes reales.',
                    style: DevTheme.bodySecondary(size: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: DevTheme.body(size: 12, w: FontWeight.w600)),
  );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: DevTheme.bodySecondary(size: 12, color: DevColors.mutedFg),
    filled: true,
    fillColor: DevColors.cardRaised,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: DevColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: DevColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: DevColors.primary),
    ),
  );
}
