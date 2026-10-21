import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar de usuario: iniciales sobre gradiente cálido, como la web
/// (gradientes wine/sepia/amber/olive) con anillo claro.
class UserAvatar extends StatelessWidget {
  final String username;
  final String? avatar;
  final double size;
  const UserAvatar({
    super.key,
    required this.username,
    this.avatar,
    this.size = 40,
  });

  /// Gradientes de la web (AVATAR_GRADIENTS) aproximados a sRGB.
  static const _grads = [
    [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
    [Color(0xFF1D4ED8), Color(0xFF6D28D9)],
    [Color(0xFF38BDF8), Color(0xFF8B5CF6)],
    [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
    [Color(0xFF1D4ED8), Color(0xFF6D28D9)],
    [Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
  ];

  @override
  Widget build(BuildContext context) {
    var hash = 0;
    for (final c in username.codeUnits) {
      hash += c;
    }
    final grad = _grads[hash % _grads.length];
    final initials = username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : username.toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: DevColors.white15, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}