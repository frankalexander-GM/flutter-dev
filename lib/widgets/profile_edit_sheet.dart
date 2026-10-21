import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/media_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

/// Hoja de edición del perfil propio.
///
/// Permite modificar nombre visible, bio, avatar, portada, ubicación, enlaces,
/// intereses (tags), rol y privacidad. Los cambios se guardan con
/// `PATCH /users/me/profile` y `PATCH /security/privacy`.
///
/// Devuelve `true` si se guardó, `null` si el usuario canceló.
Future<bool?> showProfileEditSheet(
  BuildContext context, {
  required ProfileUser profile,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DevColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ProfileEditSheet(profile: profile),
  );
}

class ProfileEditSheet extends StatefulWidget {
  final ProfileUser profile;

  const ProfileEditSheet({super.key, required this.profile});

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _fullName = TextEditingController(
    text: widget.profile.fullName ?? '',
  );
  late final TextEditingController _bio = TextEditingController(
    text: widget.profile.bio ?? '',
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.profile.location ?? '',
  );
  late final TextEditingController _website = TextEditingController(
    text: widget.profile.website ?? '',
  );
  late final TextEditingController _profession = TextEditingController(
    text: widget.profile.profession ?? '',
  );
  late final TextEditingController _tags = TextEditingController(
    text: (widget.profile.tags ?? []).join(', '),
  );

  late String _avatar = widget.profile.avatar ?? '';
  late String _banner = widget.profile.banner ?? '';
  late bool _isPrivate = false;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _bio.dispose();
    _location.dispose();
    _website.dispose();
    _profession.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacy() async {
    try {
      final me = await UserService.getMe();
      if (!mounted) return;
      setState(() => _isPrivate = me.isPrivate);
    } catch (_) {
      // Si no se puede leer, se deja el valor por defecto.
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    // Validación local antes de tocar la red.
    final fullName = _fullName.text.trim();
    final bio = _bio.text.trim();
    if (fullName.isNotEmpty && fullName.length < 3) {
      setState(() => _error = 'El nombre visible debe tener al menos 3 caracteres');
      return;
    }
    if (bio.length > 500) {
      setState(() => _error = 'La bio no puede superar los 500 caracteres');
      return;
    }
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tags.length > 15) {
      setState(() => _error = 'Máximo 15 intereses');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await UserService.updateProfile(
        fullName: fullName.isEmpty ? null : fullName,
        bio: bio.isEmpty ? null : bio,
        avatar: _avatar.isEmpty ? null : _avatar,
        banner: _banner.isEmpty ? null : _banner,
        location: _location.text.trim().isEmpty
            ? null
            : _location.text.trim(),
        website: _website.text.trim().isEmpty
            ? null
            : _website.text.trim(),
        profession: _profession.text.trim().isEmpty
            ? null
            : _profession.text.trim(),
        tags: tags,
      );
      await UserService.setPrivacy(isPrivate: _isPrivate);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      // Los cambios NO se pierden: el formulario conserva lo escrito.
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: DevColors.muted,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
            child: Row(
              children: [
                Text('Editar perfil', style: DevTheme.display(size: 17)),
                const Spacer(),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              children: [
                _ImagePickerRow(
                  label: 'Foto de perfil',
                  value: _avatar,
                  placeholder: widget.profile.username,
                  onChanged: (v) => setState(() => _avatar = v),
                ),
                const SizedBox(height: 12),
                _ImagePickerRow(
                  label: 'Portada',
                  value: _banner,
                  placeholder: 'portada',
                  isBanner: true,
                  onChanged: (v) => setState(() => _banner = v),
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _fullName,
                  label: 'Nombre visible',
                  icon: Icons.person_outline_rounded,
                  maxLength: 30,
                ),
                _Field(
                  controller: _bio,
                  label: 'Bio',
                  icon: Icons.info_outline_rounded,
                  maxLines: 3,
                  maxLength: 500,
                ),
                _Field(
                  controller: _location,
                  label: 'Ubicación',
                  icon: Icons.location_on_outlined,
                  maxLength: 255,
                ),
                _Field(
                  controller: _website,
                  label: 'Web / GitHub',
                  icon: Icons.link_rounded,
                  maxLength: 255,
                ),
                _Field(
                  controller: _profession,
                  label: 'Rol o profesión',
                  icon: Icons.work_outline_rounded,
                  maxLength: 255,
                ),
                _Field(
                  controller: _tags,
                  label: 'Intereses (separados por coma)',
                  icon: Icons.interests_outlined,
                  maxLength: 200,
                ),
                SwitchListTile(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                  activeThumbColor: DevColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Perfil privado',
                    style: DevTheme.body(size: 14, w: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Solo los seguidores pueden ver tus publicaciones.',
                    style: DevTheme.bodySecondary(size: 11.5),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DevColors.destructive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DevColors.destructive.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: DevColors.destructive,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: DevTheme.body(
                              size: 12,
                              color: DevColors.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DevColors.primary,
                  foregroundColor: DevColors.primaryFg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto con validación de longitud.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final int maxLength;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.maxLength = 255,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: DevTheme.body(size: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DevTheme.body(size: 13, color: DevColors.mutedFg),
          prefixIcon: Icon(icon, color: DevColors.mutedFg, size: 20),
          filled: true,
          fillColor: DevColors.cardRaised,
          counterStyle: DevTheme.bodySecondary(size: 10),
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
            borderSide: const BorderSide(color: DevColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

/// Selector de imagen de perfil o portada.
///
/// Permite elegir un archivo del dispositivo, previsualizarlo y subirlo al
/// servidor con `POST /users/me/media`. La URL devuelta se guarda en el
/// perfil con `PATCH /users/me/profile`.
class _ImagePickerRow extends StatefulWidget {
  final String label;
  final String value;
  final String placeholder;
  final bool isBanner;
  final ValueChanged<String> onChanged;

  const _ImagePickerRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.isBanner = false,
  });

  @override
  State<_ImagePickerRow> createState() => _ImagePickerRowState();
}

class _ImagePickerRowState extends State<_ImagePickerRow> {
  bool _uploading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Preview(
              url: widget.value,
              placeholder: widget.placeholder,
              isBanner: widget.isBanner,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: DevTheme.body(size: 13, w: FontWeight.w600),
              ),
            ),
            if (_uploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: _pick,
                child: Text(
                  hasImage ? 'Cambiar' : 'Elegir',
                  style: DevTheme.body(
                    size: 12.5,
                    w: FontWeight.w600,
                    color: DevColors.primary,
                  ),
                ),
              ),
            if (hasImage && !_uploading)
              IconButton(
                onPressed: () => widget.onChanged(''),
                icon: const Icon(Icons.close_rounded, size: 18),
                color: DevColors.mutedFg,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: DevTheme.body(size: 11, color: DevColors.destructive),
            ),
          ),
      ],
    );
  }

  /// Abre el selector, sube el archivo y avisa con la URL pública.
  Future<void> _pick() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final uploaded = await MediaService.pickAndUpload();
      if (!mounted) return;
      if (uploaded == null) {
        // El usuario canceló: no es un error.
        setState(() => _uploading = false);
        return;
      }
      widget.onChanged(uploaded.url);
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen subida correctamente'),
          backgroundColor: DevColors.consoleGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'No se pudo subir: $e';
      });
    }
  }
}

/// Vista previa de la imagen (o un placeholder si no hay).
class _Preview extends StatelessWidget {
  final String url;
  final String placeholder;
  final bool isBanner;

  const _Preview({
    required this.url,
    required this.placeholder,
    required this.isBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isBanner ? 64 : 48,
      height: isBanner ? 40 : 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: DevColors.cardRaised,
        border: Border.all(color: DevColors.border),
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: DevColors.mutedFg,
                size: 20,
              ),
            )
          : Icon(
              isBanner ? Icons.landscape_outlined : Icons.person_outline,
              color: DevColors.mutedFg,
              size: 20,
            ),
    );
  }
}
