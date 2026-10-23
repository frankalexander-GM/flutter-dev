import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'hero_3d_shapes.dart';
import 'hero_video.dart';

/// Piezas compartidas por las pantallas de acceso (login, registro).
///
/// Misma receta visual que los heroes de la app: vídeo de fondo + adorno 3D,
/// y encima una tarjeta de cristal con el formulario.

const String kAuthVideo = 'assets/videos/hero_loop_crystal_loop.mp4';
const String kAuthPoster = 'assets/videos/hero_loop_crystal_loop_poster.jpg';

/// Fondo: vídeo del hero + velo + viñeta. Todo lo demás va encima.
class AuthBackdrop extends StatelessWidget {
  final Widget child;

  const AuthBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: HeroVideo(
            videoAsset: kAuthVideo,
            posterAsset: kAuthPoster,
            shapeStyle: Hero3DStyle.discover,
            shapeOpacity: 0.28,
            scrimOpacity: 0.42,
            enablePointerInterceptor: false,
          ),
        ),
        // Viñeta: oscurece bordes para que la tarjeta respire.
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [Color(0x00060B14), Color(0xCC060B14)],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Tarjeta de cristal con el formulario.
class AuthPanel extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AuthPanel({super.key, required this.child, this.maxWidth = 430});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
            decoration: BoxDecoration(
              color: DevColors.card.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: DevColors.accentCyan.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: DevColors.accentCyan.withValues(alpha: 0.06),
                  blurRadius: 60,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Campo de texto con etiqueta arriba (más legible que el label flotante).
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DevTheme.body(
            size: 12,
            w: FontWeight.w600,
            color: DevColors.mutedFg,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          cursorColor: DevColors.accentCyan,
          style: DevTheme.body(size: 14, color: DevColors.foreground),
          decoration: authInputDecoration(
            hint: hint,
            icon: icon,
            suffix: suffix,
          ),
        ),
      ],
    );
  }
}

InputDecoration authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: DevTheme.body(size: 13.5, color: DevColors.disabled),
    prefixIcon: Icon(icon, size: 19, color: DevColors.mutedFg),
    suffixIcon: suffix,
    filled: true,
    fillColor: DevColors.background.withValues(alpha: 0.55),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border(DevColors.border, 1),
    enabledBorder: border(DevColors.border, 1),
    focusedBorder: border(DevColors.accentCyan.withValues(alpha: 0.7), 1.6),
    errorBorder: border(DevColors.destructive.withValues(alpha: 0.6), 1.2),
    focusedErrorBorder: border(DevColors.destructive, 1.6),
    errorStyle: DevTheme.body(size: 11.5, color: DevColors.destructive),
  );
}

/// Botón principal con degradado (o secundario con borde).
class AuthButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool primary;
  final double height;

  const AuthButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.primary = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    if (!primary) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
          label: Text(
            label,
            style: DevTheme.body(size: 13.5, w: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: DevColors.foreground,
            side: BorderSide(
              color: DevColors.accentCyan.withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            backgroundColor: DevColors.cardRaised.withValues(alpha: 0.45),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF00C8E0), Color(0xFF3B82F6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : DevColors.muted,
          borderRadius: BorderRadius.circular(13),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: DevColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(13),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: DevTheme.body(
                            size: 14.5,
                            w: FontWeight.w700,
                            color: Colors.white,
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

/// Aviso de error con fondo tenue (en vez de texto suelto).
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DevColors.destructive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: DevColors.destructive.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: DevColors.destructive,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: DevTheme.body(size: 12.5, color: DevColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador "o" entre el formulario y las alternativas.
class AuthOr extends StatelessWidget {
  final String label;

  const AuthOr({super.key, this.label = 'o'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: DevColors.border.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: DevTheme.bodySecondary(size: 11.5),
          ),
        ),
        Expanded(
          child: Divider(
            color: DevColors.border.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Marca compacta (logo + nombre) reutilizable.
class AuthBrandMark extends StatelessWidget {
  final double size;

  const AuthBrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            gradient: const LinearGradient(
              colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: DevColors.accentCyan.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.sports_esports_rounded,
            size: size * 0.52,
            color: const Color(0xFF04121A),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'DevPlay',
          style: DevTheme.display(size: size * 0.58).copyWith(letterSpacing: -0.6),
        ),
      ],
    );
  }
}
