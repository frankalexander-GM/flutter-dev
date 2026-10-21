import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/media_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'avatar.dart';

/// Hoja de edición del perfil propio.
///
/// Permite modificar nombre visible, bio, enlaces, avatar, portada e intereses.
/// Los cambios se guardan con `PATCH /users/me/profile`.
///
/// En pantallas anchas se muestra como diálogo centrado; en móvil, como hoja
/// inferior a pantalla completa. Devuelve `true` si se guardó, `null` si se
/// canceló.
Future<bool?> showProfileEditSheet(
  BuildContext context, {
  required ProfileUser profile,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 720;

  if (isWide) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
          child: ProfileEditSheet(profile: profile, isDialog: true),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ProfileEditSheet(profile: profile),
    ),
  );
}

class ProfileEditSheet extends StatefulWidget {
  final ProfileUser profile;
  final bool isDialog;

  const ProfileEditSheet({
    super.key,
    required this.profile,
    this.isDialog = false,
  });

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
  late final TextEditingController _website = TextEditingController(
    text: widget.profile.website ?? '',
  );
  final TextEditingController _tagInput = TextEditingController();

  late final List<String> _tagList = List.of(widget.profile.tags ?? const []);

  late String _avatar = widget.profile.avatar ?? '';
  late String _banner = widget.profile.banner ?? '';

  late final _InitialState _initial;

  bool _saving = false;
  String? _error;

  bool get _dirty => _initial.differs(
    fullName: _fullName.text,
    bio: _bio.text,
    website: _website.text,
    tags: _tagList,
    avatar: _avatar,
    banner: _banner,
  );

  @override
  void initState() {
    super.initState();
    _initial = _InitialState(
      fullName: _fullName.text,
      bio: _bio.text,
      website: _website.text,
      tags: List.of(_tagList),
      avatar: _avatar,
      banner: _banner,
    );
    _bio.addListener(_onTextChanged);
    _fullName.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _bio.dispose();
    _website.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Solo repinta la vista previa cuando cambia algo visible en ella.
    if (mounted) setState(() {});
  }

  Future<void> _confirmClose() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DevColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DevColors.border),
        ),
        title: Text('¿Descartar cambios?', style: DevTheme.display(size: 17)),
        content: Text(
          'Tienes cambios sin guardar en tu perfil. Si sales ahora se perderán.',
          style: DevTheme.body(size: 13.5, color: DevColors.mutedFg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Seguir editando',
              style: DevTheme.body(color: DevColors.mutedFg),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.destructive,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  void _addTag([String? raw]) {
    final value = (raw ?? _tagInput.text).trim().replaceAll(RegExp(r'^#+'), '');
    if (value.isEmpty) return;
    final exists = _tagList.any((t) => t.toLowerCase() == value.toLowerCase());
    if (exists) {
      _tagInput.clear();
      return;
    }
    if (_tagList.length >= 30) {
      setState(() => _error = 'Puedes añadir hasta 30 intereses');
      return;
    }
    setState(() {
      _tagList.add(value);
      _tagInput.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    // Validación local antes de tocar la red.
    final fullName = _fullName.text.trim();
    final bio = _bio.text.trim();
    if (fullName.isNotEmpty && fullName.length < 3) {
      setState(
        () => _error = 'El nombre visible debe tener al menos 3 caracteres',
      );
      return;
    }
    if (bio.length > 500) {
      setState(() => _error = 'La bio no puede superar los 500 caracteres');
      return;
    }
    final tags = _tagList
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tags.length > 30) {
      setState(() => _error = 'Máximo 30 intereses');
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
        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
        tags: tags,
      );
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
    final radius = BorderRadius.vertical(
      top: const Radius.circular(24),
      bottom: Radius.circular(widget.isDialog ? 24 : 0),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: BoxDecoration(
          color: DevColors.background,
          borderRadius: radius,
          border: Border.all(color: DevColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _PreviewHeader(
              profile: widget.profile,
              fullName: _fullName.text,
              avatar: _avatar,
              banner: _banner,
              onClose: _confirmClose,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                children: [
                  _Section(
                    title: 'Imágenes',
                    icon: Icons.image_outlined,
                    subtitle: 'Foto de perfil y portada de tu perfil.',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ImagePickerRow(
                            label: 'Foto de perfil',
                            value: _avatar,
                            placeholder: widget.profile.username,
                            onChanged: (v) => setState(() => _avatar = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImagePickerRow(
                            label: 'Portada',
                            value: _banner,
                            placeholder: 'portada',
                            isBanner: true,
                            onChanged: (v) => setState(() => _banner = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Información personal',
                    icon: Icons.badge_outlined,
                    subtitle: 'Así te verán los demás en DevPlay.',
                    child: Column(
                      children: [
                        _Field(
                          controller: _fullName,
                          label: 'Nombre visible',
                          hint: 'Tu nombre o alias público',
                          icon: Icons.person_outline_rounded,
                          maxLength: 30,
                        ),
                        _Field(
                          controller: _bio,
                          label: 'Bio',
                          hint: 'Cuéntanos qué haces y qué te gusta…',
                          icon: Icons.info_outline_rounded,
                          maxLines: 4,
                          maxLength: 500,
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Enlaces',
                    icon: Icons.link_rounded,
                    subtitle: 'Tu web, GitHub o portafolio.',
                    child: _Field(
                      controller: _website,
                      label: 'Web / GitHub',
                      hint: 'https://…',
                      icon: Icons.public_rounded,
                      maxLength: 255,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  _Section(
                    title: 'Intereses',
                    icon: Icons.interests_outlined,
                    subtitle:
                        'Elige los que quieras o escribe los tuyos. Máximo 30.',
                    child: _TagEditor(
                      tags: _tagList,
                      input: _tagInput,
                      onAdd: _addTag,
                      onRemove: (tag) => setState(() => _tagList.remove(tag)),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            _Footer(
              saving: _saving,
              error: _error,
              onCancel: _confirmClose,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------- Vista previa -------------------------------

class _PreviewHeader extends StatelessWidget {
  final ProfileUser profile;
  final String fullName;
  final String avatar;
  final String banner;
  final VoidCallback onClose;

  const _PreviewHeader({
    required this.profile,
    required this.fullName,
    required this.avatar,
    required this.banner,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = banner.isNotEmpty;
    final name = fullName.trim().isEmpty ? profile.username : fullName.trim();
    final bio = _bioPreview(profile.bio);

    return Container(
      height: 158,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A101D), Color(0xFF7C3AED), Color(0xFF3B82F6)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBanner)
            Image.network(
              banner,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          // Oscurece la parte inferior para que el texto siempre se lea.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xCC060B14)],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: DevColors.black14,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: DevColors.cream,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 14,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DevColors.btnGradient(),
                  ),
                  child: UserAvatar(
                    username: profile.username,
                    avatar: avatar.isEmpty ? null : avatar,
                    size: 62,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: DevTheme.display(size: 19, w: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '@${profile.username}',
                        style: DevTheme.bodySecondary(size: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          bio,
                          style: DevTheme.body(
                            size: 11.5,
                            color: DevColors.foreground.withValues(alpha: 0.82),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: Text(
              'VISTA PREVIA',
              style: DevTheme.labelCaps(size: 9.5, color: DevColors.cream),
            ),
          ),
        ],
      ),
    );
  }

  static String _bioPreview(String? bio) {
    if (bio == null) return '';
    final clean = bio.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length > 70 ? '${clean.substring(0, 70)}…' : clean;
  }
}

// --------------------------------- Sección ----------------------------------

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: DevColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: DevColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: DevTheme.bodySecondary(size: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------- Campos ----------------------------------

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final int maxLines;
  final int maxLength;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.maxLength = 255,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: DevTheme.body(size: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: DevTheme.body(size: 12.5, color: DevColors.mutedFg),
          labelStyle: DevTheme.body(size: 13, color: DevColors.mutedFg),
          floatingLabelStyle: DevTheme.body(
            size: 12.5,
            color: DevColors.primary,
          ),
          prefixIcon: Icon(icon, color: DevColors.mutedFg, size: 19),
          filled: true,
          fillColor: DevColors.cardRaised,
          counterStyle: DevTheme.bodySecondary(size: 10),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DevColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DevColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DevColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}

// ------------------------------- Intereses ----------------------------------

class _TagEditor extends StatelessWidget {
  final List<String> tags;
  final TextEditingController input;
  final ValueChanged<String?> onAdd;
  final ValueChanged<String> onRemove;

  const _TagEditor({
    required this.tags,
    required this.input,
    required this.onAdd,
    required this.onRemove,
  });

  static const Map<String, List<String>> categories = {
    'Desarrollo': [
      'Flutter',
      'Unity',
      'Godot',
      'Unreal Engine',
      'Python',
      'C#',
      'Web Dev',
    ],
    'Arte y diseño': [
      'Pixel Art',
      'Ilustración',
      '3D',
      'UI/UX',
      'Animación',
      'Música',
    ],
    'Géneros': ['RPG', 'Indie', 'Horror', 'Plataformas', 'Shooter', 'Aventura'],
    'Comunidad': [
      'Game Jams',
      'Open Source',
      'Streaming',
      'Modding',
      'Testing',
      'Narrativa',
    ],
  };

  bool _isSelected(String tag) =>
      tags.any((t) => t.toLowerCase() == tag.toLowerCase());

  void _toggle(String tag) {
    if (_isSelected(tag)) {
      final current = tags.firstWhere(
        (t) => t.toLowerCase() == tag.toLowerCase(),
        orElse: () => tag,
      );
      onRemove(current);
      return;
    }
    onAdd(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.only(left: 10, right: 4),
                      decoration: BoxDecoration(
                        color: DevColors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: DevColors.accentCyan.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: DevTheme.body(
                              size: 12,
                              color: DevColors.accentCyan,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar $tag',
                            onPressed: () => onRemove(tag),
                            icon: const Icon(Icons.close_rounded, size: 14),
                            color: DevColors.accentCyan,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        TextField(
          controller: input,
          maxLength: 30,
          textInputAction: TextInputAction.done,
          onSubmitted: onAdd,
          style: DevTheme.body(size: 14),
          decoration: InputDecoration(
            hintText: 'Escribe un interés y pulsa Enter',
            hintStyle: DevTheme.body(size: 12.5, color: DevColors.mutedFg),
            prefixIcon: const Icon(
              Icons.tag_rounded,
              color: DevColors.mutedFg,
              size: 19,
            ),
            suffixIcon: IconButton(
              tooltip: 'Añadir interés',
              onPressed: () => onAdd(null),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: DevColors.accentCyan,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: DevColors.cardRaised,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DevColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DevColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: DevColors.accentCyan,
                width: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sugerencias para ti',
          style: DevTheme.labelCaps(size: 9.5, color: DevColors.mutedFg),
        ),
        const SizedBox(height: 10),
        ...categories.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: DevTheme.body(
                    size: 12,
                    w: FontWeight.w700,
                    color: DevColors.foreground,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: entry.value
                      .map(
                        (tag) => _SuggestionChip(
                          label: tag,
                          selected: _isSelected(tag),
                          onTap: () => _toggle(tag),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DevColors.accentCyan.withValues(alpha: 0.12)
          : DevColors.cardRaised,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        hoverColor: DevColors.accentCyan.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? DevColors.accentCyan.withValues(alpha: 0.55)
                  : DevColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: DevColors.accentCyan,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: DevTheme.body(
                  size: 11.5,
                  w: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? DevColors.accentCyan : DevColors.mutedFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------- Footer ----------------------------------

class _Footer extends StatelessWidget {
  final bool saving;
  final String? error;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Footer({
    required this.saving,
    required this.error,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(top: BorderSide(color: DevColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
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
                        error!,
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : onCancel,
                    style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return DevColors.disabled;
                        }
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused)) {
                          return Colors.white;
                        }
                        return DevColors.mutedFg;
                      }),
                      side: WidgetStateProperty.resolveWith((states) {
                        final hovered =
                            states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused);
                        return BorderSide(
                          color: hovered
                              ? DevColors.mutedFg.withValues(alpha: 0.5)
                              : const Color(0xFF334155),
                        );
                      }),
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return DevColors.mutedFg.withValues(alpha: 0.06);
                        }
                        return Colors.transparent;
                      }),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 14),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _GradientSaveButton(
                    saving: saving,
                    onPressed: saving ? null : onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de guardado con gradiente neón y glow al pasar el cursor.
class _GradientSaveButton extends StatefulWidget {
  final bool saving;
  final VoidCallback? onPressed;

  const _GradientSaveButton({required this.saving, required this.onPressed});

  @override
  State<_GradientSaveButton> createState() => _GradientSaveButtonState();
}

class _GradientSaveButtonState extends State<_GradientSaveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.saving && widget.onPressed != null;
    final glowing = _hovered && enabled;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: widget.saving || enabled
              ? DevColors.cyanGradient()
              : const LinearGradient(
                  colors: [DevColors.muted, DevColors.muted],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: glowing
              ? [
                  BoxShadow(
                    color: DevColors.accentCyan.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.saving ? 'Guardando…' : 'Guardar cambios',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DevTheme.body(
                        size: 13.5,
                        w: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------ Selector imagen -----------------------------

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
  bool _hovered = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.value.isNotEmpty;
    final borderColor = _hovered
        ? DevColors.accentCyan.withValues(alpha: 0.75)
        : DevColors.accentCyan.withValues(alpha: hasImage ? 0.45 : 0.3);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: borderColor),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (context, animated, child) => CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: animated ?? borderColor,
          ),
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              DevColors.accentCyan.withValues(alpha: _hovered ? 0.06 : 0.03),
              DevColors.cardRaised,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 78,
                child: Center(
                  child: SizedBox(
                    width: widget.isBanner ? 116 : 78,
                    height: widget.isBanner ? 72 : 78,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _uploading ? null : _pick,
                            child: MouseRegion(
                              cursor: _uploading
                                  ? SystemMouseCursors.basic
                                  : SystemMouseCursors.click,
                              child: _Preview(
                                url: widget.value,
                                placeholder: widget.placeholder,
                                isBanner: widget.isBanner,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _CameraBadge(
                            loading: _uploading,
                            onTap: _uploading ? null : _pick,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: DevTheme.body(size: 12.5, w: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              Text(
                _uploading
                    ? 'Subiendo imagen…'
                    : hasImage
                    ? 'Toca la cámara para cambiar'
                    : 'Toca la cámara para elegir',
                style: DevTheme.bodySecondary(size: 10.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              if (!_uploading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _pick,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        hasImage ? 'Cambiar' : 'Elegir',
                        style: DevTheme.body(
                          size: 12,
                          w: FontWeight.w600,
                          color: DevColors.accentCyan,
                        ),
                      ),
                    ),
                    if (hasImage)
                      IconButton(
                        tooltip: 'Quitar imagen',
                        onPressed: () => widget.onChanged(''),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                        ),
                        color: DevColors.mutedFg,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error!,
                    style: DevTheme.body(
                      size: 10.5,
                      color: DevColors.destructive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
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

/// Borde punteado cian para las zonas de subida de imágenes.
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.2;
    const radius = 14.0;
    const dash = 6.0;
    const gap = 4.0;

    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash > metric.length
            ? metric.length
            : distance + dash;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Botón flotante de cámara sobre la vista previa de cada imagen.
class _CameraBadge extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _CameraBadge({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DevColors.accentCyan,
            border: Border.all(color: DevColors.background, width: 2),
            boxShadow: DevColors.cyanGlow(alpha: 0.45),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DevColors.background,
                  ),
                )
              : const Icon(
                  Icons.photo_camera_rounded,
                  size: 15,
                  color: DevColors.background,
                ),
        ),
      ),
    );
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
      width: isBanner ? 104 : 64,
      height: isBanner ? 58 : 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isBanner ? 8 : 99),
        color: DevColors.background,
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
          : Center(
              child: Icon(
                isBanner ? Icons.landscape_outlined : Icons.person_outline,
                color: DevColors.mutedFg,
                size: 22,
              ),
            ),
    );
  }
}

// ------------------------------ Cambios sin guardar -------------------------

class _InitialState {
  final String fullName;
  final String bio;
  final String website;
  final List<String> tags;
  final String avatar;
  final String banner;

  const _InitialState({
    required this.fullName,
    required this.bio,
    required this.website,
    required this.tags,
    required this.avatar,
    required this.banner,
  });

  bool differs({
    required String fullName,
    required String bio,
    required String website,
    required List<String> tags,
    required String avatar,
    required String banner,
  }) {
    return this.fullName != fullName ||
        this.bio != bio ||
        this.website != website ||
        this.avatar != avatar ||
        this.banner != banner ||
        !_sameTags(this.tags, tags);
  }

  static bool _sameTags(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
