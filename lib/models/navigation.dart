import 'package:flutter/material.dart';

/// Vistas principales de la app (equivalentes a `ViewId` en Next.js).
enum ViewId {
  discover, // Descubrir / trending
  explore, // Inicio / Feed principal
  betas, // Centro de betas
  chat, // Chat Mundial
  store, // Tienda
  profile, // Perfil (se abre como sheet/modal)
  reportes, // Reportes
  about, // Acerca de
  settings, // Configuración
}

/// Datos de un item de navegación principal.
class NavItem {
  final ViewId id;
  final String label;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  const NavItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

/// Items de navegación principal — orden y estilos calcados del Next.js.
const List<NavItem> kMainNav = [
  // Descubrir SIEMPRE arriba — nada la baja de la primera posición
  NavItem(
    id: ViewId.discover,
    label: 'Descubrir',
    description: 'Novedades y trending',
    icon: Icons.auto_awesome_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFDC7A44), Color(0xFFB85F3A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  NavItem(
    id: ViewId.explore,
    label: 'Inicio',
    description: 'Feed principal',
    icon: Icons.home_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFDC7A44), Color(0xFFB85F3A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  NavItem(
    id: ViewId.betas,
    label: 'Betas',
    description: 'Centro de betas',
    icon: Icons.sports_esports_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFD9A441), Color(0xFFB8862E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  NavItem(
    id: ViewId.chat,
    label: 'Chat Mundial',
    description: 'Chatea con la comunidad',
    icon: Icons.chat_bubble_outline_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFD9A441), Color(0xFFB8862E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  NavItem(
    id: ViewId.store,
    label: 'Tienda',
    description: 'No disponible · En construcción',
    icon: Icons.storefront_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFB8862E), Color(0xFF9D6B1F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

/// Items de "Crear contenido" (solo usuarios logueados no invitados).
const List<NavItem> kCreateItems = [
  NavItem(
    id: ViewId.betas, // reutilizamos id, la acción es abrir create beta
    label: 'Subir beta',
    description: 'Publicar una beta nueva',
    icon: Icons.sports_esports_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFD9A441), Color(0xFFB8862E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  NavItem(
    id: ViewId.chat, // reutilizamos, acción: crear encuesta
    label: 'Crear encuesta',
    description: 'Nueva encuesta para la comunidad',
    icon: Icons.poll_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFF8FAF4A), Color(0xFF6B8E3A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

/// Items de "Ayuda" (ocultable).
const List<NavItem> kHelpItems = [
  NavItem(
    id: ViewId.discover, // acción: tour guiado
    label: 'Tour guiado',
    description: 'Recorrido por la app',
    icon: Icons.tour_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFFDC7A44), Color(0xFFB8862E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  NavItem(
    id: ViewId.about,
    label: 'Acerca de DevPlay',
    description: 'Info de la app y créditos',
    icon: Icons.info_outline_rounded,
    gradient: const LinearGradient(
      colors: [Color(0xFF8E9BA8), Color(0xFF6B7A8A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];
