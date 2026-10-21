import 'package:flutter/material.dart';

/// Tokens de diseño de DevPlay — Paleta "Degradado Sci-Fi".
///
/// Paleta oficial:
/// - Background:              #060B14 — Azul noche ultra oscuro
/// - Surface (sidebar/nav):   #0A101D — Paneles y barras
/// - Card:                    #0F172A — Contenedores, tarjetas, paneles
/// - Border:                  rgba(56,189,248,0.15) — Bordes fríos con tinte cyan
/// - Primary (azul):          #3B82F6 — Botones y estados activos
/// - Accent cyan:             #00F0FF — Íconos activos, bordes glowing
/// - Accent orange (CTA):     #FF5E00 — Crear publicación / acciones de impacto
/// - Gradiente Sci-Fi:        #00F0FF → #3B82F6 → #8B5CF6
/// - Text Primary:            #F8FAFC — Títulos y cuerpo
/// - Text Secondary:          #94A3B8 — Subtítulos, metadata, hints
/// - Muted/Disabled:          #64748B
/// - Destructive:             #F87171 — Alertas y actividad
abstract final class DevColors {
  // ── Paleta semántica (dark) ────────────────────────────────
  static const background = Color(0xFF060B14); // Scaffold / fondo principal
  static const foreground = Color(0xFFF8FAFC); // Texto principal
  static const surface = Color(0xFF0A101D); // Sidebar / navbar
  static const card = Color(0xFF0F172A); // Contenedores y tarjetas
  static const cardRaised = Color(0xFF16213A); // Superficies elevadas / hover
  static const primary = Color(0xFF3B82F6); // Azul — botones, chips activos
  static const primaryFg = Color(0xFFFFFFFF); // Texto sobre primary
  static const secondary = Color(0xFF1E293B); // Secundario / bordes activos
  static const secondaryFg = Color(0xFF94A3B8); // Texto sobre secondary
  static const muted = Color(0xFF1B2740); // Superficies sutiles
  static const mutedFg = Color(0xFF94A3B8); // Texto secundario / subtítulos
  static const disabled = Color(0xFF64748B); // Texto/íconos deshabilitados
  static const accent = Color(0xFF312E81); // Acento terciario (violeta)
  static const accentFg = Color(0xFFC7D2FE);
  static const destructive = Color(
    0xFFF87171,
  ); // Rojo suave — alertas, actividad
  static const likedRed = Color(0xFFF87171); // Like rojo suave
  static const border = Color(0x2638BDF8); // rgba(56,189,248,0.15)

  // ── Acentos de marca (para badges, gradientes, chips) ──
  static const accentCyan = Color(0xFF00F0FF); // Neón cyan
  static const accentOrange = Color(0xFFFF5E00); // CTA naranja
  static const gold = Color(0xFF8B5CF6); // Violeta (antes dorado)
  static const goldSoft = Color(0xFFC4B5FD);
  static const cream = Color(0xFFF8FAFC);
  static const amber = Color(0xFFFF5E00);
  static const wine = Color(0xFF7C3AED);
  static const olive = Color(0xFF22D3EE);

  // ── Consola CRT (estado vacío) ──
  static const consoleBg = Color(0xFF05070D);
  static const consoleGreen = Color(0xFF00F0FF);
  static const consoleFrame = Color(0xFF1E3A5F);

  // Fill con alpha (píldoras, chips, badges)
  static const white08 = Color(0x14FFFFFF);
  static const white15 = Color(0x26FFFFFF);
  static const black14 = Color(0x24000000);
  static const gold20 = Color(0x338B5CF6);
  static const gold25 = Color(0x408B5CF6);
  static const gold35 = Color(0x598B5CF6);
  static const gold40 = Color(0x668B5CF6);
  static const gold50 = Color(0x808B5CF6);

  // ── Gradientes predefinidos ──
  static LinearGradient btnGradient() => const LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente reducido (cyan → azul) para piezas pequeñas.
  static LinearGradient cyanGradient() => const LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glow suave de neón para botones y elementos activos.
  static List<BoxShadow> cyanGlow({double alpha = 0.35}) => [
    BoxShadow(
      color: accentCyan.withValues(alpha: alpha),
      blurRadius: 16,
      offset: const Offset(0, 0),
    ),
  ];

  /// Glow naranja para los CTA de alto impacto.
  static List<BoxShadow> orangeGlow({double alpha = 0.4}) => [
    BoxShadow(
      color: accentOrange.withValues(alpha: alpha),
      blurRadius: 12,
      offset: const Offset(0, 0),
    ),
  ];

  // Gradiente para cards trending
  static LinearGradient trendingCardGradient() => const LinearGradient(
    colors: [Color(0xFF111C33), Color(0xFF0F172A)],
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
  }) => TextStyle(
    fontSize: size,
    fontWeight: w,
    color: color,
    fontFamily: 'Georgia',
  );

  static TextStyle body({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color color = DevColors.foreground,
    double? height,
    FontStyle? fontStyle,
  }) => TextStyle(
    fontSize: size,
    fontWeight: w,
    color: color,
    height: height,
    fontStyle: fontStyle,
    fontFamily: 'Segoe UI',
  );

  static TextStyle bodySecondary({
    double size = 13,
    FontWeight w = FontWeight.w400,
    Color color = DevColors.mutedFg,
  }) => TextStyle(
    fontSize: size,
    fontWeight: w,
    color: color,
    fontFamily: 'Segoe UI',
  );

  static TextStyle mono({
    double size = 11,
    FontWeight w = FontWeight.w400,
    Color color = DevColors.consoleGreen,
  }) => TextStyle(
    fontSize: size,
    fontWeight: w,
    color: color,
    fontFamily: 'Consolas',
  );

  static TextStyle labelCaps({
    double size = 10,
    FontWeight w = FontWeight.w700,
    Color color = DevColors.mutedFg,
  }) => TextStyle(
    fontSize: size,
    fontWeight: w,
    color: color,
    letterSpacing: 1.2,
    fontFamily: 'Segoe UI',
  );

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
            color: DevColors.accentCyan.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      );

  static BoxDecoration glassStrong({double radius = 16}) => BoxDecoration(
    color: DevColors.card,
    border: Border.all(color: DevColors.border),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 4)),
    ],
  );

  // Card específica para trending games
  static BoxDecoration trendingCard({double radius = 16}) => BoxDecoration(
    color: DevColors.card,
    border: Border.all(color: DevColors.border),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 3)),
    ],
  );

  /// Botón "degradado" primario → acento terracota.
  static LinearGradient btnGradient() => DevColors.btnGradient();
}

/// ThemeData de DevPlay — Paleta "Degradado Sci-Fi".
///
/// Background #060B14, Surface #0A101D, Card #0F172A,
/// Primary #3B82F6, Cyan #00F0FF, Violeta #8B5CF6,
/// Text Primary #F8FAFC, Text Secondary #94A3B8.
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: DevTheme.body(size: 16, w: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DevColors.cardRaised,
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
      hintStyle: DevTheme.bodySecondary(
        color: DevColors.mutedFg.withValues(alpha: 0.6),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: DevColors.surface,
      foregroundColor: DevColors.foreground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: DevTheme.display(size: 20),
      iconTheme: const IconThemeData(color: DevColors.foreground),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: DevColors.surface,
      selectedItemColor: DevColors.accentCyan,
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
