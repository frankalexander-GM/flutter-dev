import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../theme.dart';

/// Diálogo para reportar cualquier contenido con `POST /security/report`.
Future<void> showReportDialog(
  BuildContext context, {
  required String entityId,
  required String entityType,
  String? entityLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReportDialog(
      entityId: entityId,
      entityType: entityType,
      entityLabel: entityLabel,
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  final String entityId;
  final String entityType;
  final String? entityLabel;

  const _ReportDialog({
    required this.entityId,
    required this.entityType,
    this.entityLabel,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = <String, String>{
    'spam': 'Spam o promocional',
    'harassment': 'Acoso',
    'inappropriate': 'Contenido inapropiado',
    'impersonation': 'Suplantación de identidad',
    'other': 'Otro',
  };

  final _descriptionController = TextEditingController();
  String _reason = 'spam';
  bool _sending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await PostService.reportContent(
        entityId: widget.entityId,
        entityType: widget.entityType,
        reason: _reason,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
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
    return AlertDialog(
      backgroundColor: DevColors.card,
      title: Text('Reportar contenido', style: DevTheme.display(size: 16)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.entityLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  widget.entityLabel!,
                  style: DevTheme.bodySecondary(size: 11.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              dropdownColor: DevColors.card,
              style: DevTheme.body(size: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: DevColors.cardRaised,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DevColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DevColors.border),
                ),
              ),
              items: _reasons.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _reason = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              style: DevTheme.body(size: 13),
              decoration: InputDecoration(
                hintText: 'Detalles (opcional)',
                hintStyle: DevTheme.bodySecondary(
                    size: 12, color: DevColors.mutedFg),
                filled: true,
                fillColor: DevColors.cardRaised,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DevColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DevColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: Text('Cancelar',
              style: DevTheme.body(color: DevColors.mutedFg)),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DevColors.destructive,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: _sending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Reportar'),
        ),
      ],
    );
  }
}
