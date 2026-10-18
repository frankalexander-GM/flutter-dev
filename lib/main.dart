import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const DevPlayApp());
}

/// Raíz de la app: tema DevPlay (oscuro, "papel, tinta y filetes") y la
/// pantalla principal. El tema aplica la paleta cálida oscura y los glass
/// cards que calcan el diseño web de la rama `visual` del backend.
class DevPlayApp extends StatelessWidget {
  const DevPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevPlay',
      debugShowCheckedModeBanner: false,
      // Tema aplicado desde theme.dart — paleta y tipografía del diseño web.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DevColors.background,
        colorScheme: const ColorScheme.dark(
          primary: DevColors.primary,
          onPrimary: DevColors.primaryFg,
          secondary: DevColors.secondary,
          onSecondary: DevColors.foreground,
          surface: DevColors.card,
          onSurface: DevColors.foreground,
          error: DevColors.destructive,
          onError: Colors.white,
          outline: DevColors.border,
        ),
        // Tipografía sin GoogleFonts para evitar el error de Noto fonts en release.
        // Usamos las fuentes del sistema (serif para display, sans para body).
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: DevColors.foreground,
            fontFamily: 'Georgia',
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: DevColors.foreground,
            fontFamily: 'Georgia',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: DevColors.foreground,
            fontFamily: 'Segoe UI',
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: DevColors.mutedFg,
            fontFamily: 'Segoe UI',
          ),
          labelMedium: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: DevColors.mutedFg,
            fontFamily: 'Consolas',
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}