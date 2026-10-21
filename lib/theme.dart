import 'package:flutter/material.dart';

/// Tokens de diseño de DevPlay — Paleta PRD "Descubrir" actualizada.
///
/// Paleta oficial:
/// - Primary (Terracota):     #C66E41 — Botones principales, chips activos, acentos
/// - Background:              #1C1411 — Scaffold principal
/// - Surface/Card:            #2A1F1A — Contenedores, tarjetas, paneles
/// - Border:                  #3C2B23 — Bordes, divisores, chips inactivos
/// - Text Primary:            #FBF3E4 — Títulos, cuerpo principal
/// - Text Secondary:          #B6A69B — Subtítulos, metadata, hints
/// - Alert/Activity:          #E06C75 — Rojo suave para alertas y actividad en vivo
/// - Gold/Accent (legacy):    #D9A441 — Badges, gradientes secundarios
abstract final class DevColors {
  // ── Paleta semántica (dark) ────────────────────────────────
  static const background     = Color(0xFF1C1411); // Scaffold / fondo principal
  static const foreground     = Color(0xFFFBF3E4); // Texto principal
  static const card           = Color(0xFF2A1F1A); // Contenedores y tarjetas
  static const cardRaised     = Color(0xFF32261F); // Superficies elevadas / hover
  static const primary        = Color(0xFFC66E41); // Terracota — botones, chips activos
  static const primaryFg      = Color(0xFFFFFFFF); // Texto sobre primary
  static const secondary      = Color(0xFF3C2B23); // Secundario / bordes activos
  static const secondaryFg    = Color(0xFFB6A69B); // Texto sobre secondary
  static const muted          = Color(0xFF2E221B); // Elementos sutiles
  static const mutedFg        = Color(0xFFB6A69B); // Texto secundario / subtítulos
  static const accent         = Color(0xFF3A2E27); // Acento terciario
  static const accentFg       = Color(0xFFD1C7C1);
  static const destructive    = Color(0xFFE06C75); // Rojo suave — alertas, actividad
  static const likedRed       = Color(0xFFE06C75); // Like rojo suave
  static const border         = Color(0xFF3C2B23); // Bordes y divisores

  // ── Acentos de marca (para badges, gradientes, chips) ──
  static const gold           = Color(0xFFD9A441); // Dorado suave (badges, gradientes)
  static const goldSoft       = Color(0xFFF0D9A8);
  static const cream          = Color(0xFFF6EFDE);
  static const amber          = Color(0xFFD9A441);
  static const wine           = Color(0xFF8E3B47);
  static const olive          = Color(0xFF7A7A3E);

  // ── Consola CRT (estado vacío) ──
  static const consoleBg      = Color(0xFF12100C);
  static const consoleGreen   = Color(0xFF7EF29A);
  static const consoleFrame   = Color(0xFF59371F);

  // Fill con alpha (píldoras, chips, badges)
  static const white08        = Color(0x14FFFFFF);
  static const white15        = Color(0x26FFFFFF);
  static const black14        = Color(0x24000000);
  static const gold20         = Color(0x33D9A441);
  static const gold25         = Color(0x40D9A441);
  static const gold35         = Color(0x59D9A441);
  static const gold40         = Color(0x66D9A441);
  static const gold50         = Color(0x80D9A441);

  // ── Gradientes predefinidos ──
  static LinearGradient btnGradient() => LinearGradient(
        colors: [Color(0xFFD47A4A), Color(0xFFC66E41)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Gradiente para cards trending
  static LinearGradient trendingCardGradient() => LinearGradient(
        colors: [Color(0xFF2E221B), Color(0xFF2A1F1A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Helpers de estilo compartidos por todos los widgets.
abstract final class DevTheme {
  // ── Tipografías (fuentes del sistema para evitar errores de Noto en release) ──
  static TextStyle display({
    double size = 20,
    FontWeight w = FontWeight.w700,
    Color color = DevColors.foreground,
  }) =>
      TextStyle(fontSize: size, fontWeight: w, color: color, fontFamily: 'Georgia');

  static TextStyle body({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color color = DevColors.foreground,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(fontSize: size, fontWeight: w, color: color, height: height, fontStyle: fontStyle, fontFamily: 'Segoe UI');

  static TextStyle bodySecondary({
    double size = 13,
    FontWeight w = FontWeight.w400,
    Color color = DevColors.mutedFg,
  }) =>
      TextStyle(fontSize: size, fontWeight: w, color: color, fontFamily: 'Segoe UI');

  static TextStyle mono({
    double size = 11,
    FontWeight w = FontWeight.w400,
    Color color = DevColors.consoleGreen,
  }) =>
      TextStyle(fontSize: size, fontWeight: w, color: color, fontFamily: 'Consolas');

  static TextStyle labelCaps({
    double size = 10,
    FontWeight w = FontWeight.w700,
    Color color = DevColors.mutedFg,
  }) =>
      TextStyle(
          fontSize: size,
          fontWeight: w,
          color: color,
          letterSpacing: 1.2,
          fontFamily: 'Segoe UI');

  // ── Superficies (glass-card / glass-strong de la web) ─────
  // Radio 16 por defecto: cards más suaves y modernas.
  static BoxDecoration glass({double radius = 16, Color? color}) =>
      BoxDecoration(
        color: color ?? DevColors.card,
        border: Border.all(color: DevColors.border),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: DevColors.gold.withValues(alpha: 0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      );

  static BoxDecoration glassStrong({double radius = 16}) => BoxDecoration(
        color: DevColors.card,
        border: Border.all(color: DevColors.border),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      );

  // Card específica para trending games
  static BoxDecoration trendingCard({double radius = 16}) => BoxDecoration(
        color: DevColors.card,
        border: Border.all(color: DevColors.border),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      );

  /// Botón "degradado" primario → acento terracota.
  static LinearGradient btnGradient() => DevColors.btnGradient();
}

/// ThemeData de DevPlay — Paleta PRD "Descubrir".
///
/// Background #1C1411, Card #2A1F1A, Primary #C66E41,
/// Text Primary #FBF3E4, Text Secondary #B6A69B, Border #3C2B23.
ThemeData buildDevPlayTheme() {
  final scheme = ColorScheme.dark(
    primary: DevColors.primary,
    onPrimary: DevColors.primaryFg,
    secondary: DevColors.secondary,
    onSecondary: DevColors.secondaryFg,
    error: DevColors.destructive,
    onError: Colors.white,
    surface: DevColors.card,
    onSurface: DevColors.foreground,
    surfaceContainerHighest: DevColors.muted,
    onSurfaceVariant: DevColors.mutedFg,
    outline: DevColors.border,
    outlineVariant: DevColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: DevColors.background,
    canvasColor: DevColors.background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: DevColors.foreground,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: DevColors.foreground,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: DevColors.foreground,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 16,
        height: 1.5,
        color: DevColors.foreground,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 14,
        height: 1.5,
        color: DevColors.foreground,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 13,
        color: DevColors.mutedFg,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DevColors.foreground,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: DevColors.mutedFg,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: DevColors.mutedFg,
      ),
    ),
    dividerTheme: const DividerThemeData(color: DevColors.border, thickness: 1),
    cardTheme: CardThemeData(
      color: DevColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DevColors.border),
      ),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DevColors.primary,
        foregroundColor: DevColors.primaryFg,
        elevation: 2,
        shadowColor: DevColors.primary.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: DevTheme.body(size: 16, w: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DevColors.muted,
      labelStyle: DevTheme.body(size: 12),
      side: const BorderSide(color: DevColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DevColors.cardRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      labelStyle: DevTheme.bodySecondary(),
      hintStyle: DevTheme.bodySecondary(color: DevColors.mutedFg.withValues(alpha: 0.6)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: DevColors.card,
      foregroundColor: DevColors.foreground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: DevTheme.display(size: 20),
      iconTheme: const IconThemeData(color: DevColors.foreground),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: DevColors.card,
      selectedItemColor: DevColors.gold,
      unselectedItemColor: DevColors.mutedFg,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: DevTheme.labelCaps(size: 10),
      unselectedLabelStyle: DevTheme.labelCaps(size: 10),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DevColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: DevTheme.display(size: 18),
      contentTextStyle: DevTheme.body(size: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: DevColors.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      modalBarrierColor: Colors.black.withValues(alpha: 0.6),
    ),
  );
}