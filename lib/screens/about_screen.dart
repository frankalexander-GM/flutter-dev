import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/hero_3d_shapes.dart';
import '../widgets/hero_video.dart';

/// Pantalla "Acerca de DevPlay".
///
/// Además de la información del proyecto, centraliza los documentos legales
/// básicos de la MVP: términos, privacidad, normas de comunidad y cookies.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _updated = '20 de octubre de 2026';

  static const _docs = <_LegalDoc>[
    _LegalDoc(
      title: 'Términos y condiciones',
      icon: Icons.gavel_rounded,
      summary: 'Reglas de uso de la plataforma y del contenido que publicas.',
      sections: [
        _LegalSection(
          heading: '1. Aceptación',
          paragraphs: [
            'Al crear una cuenta, entrar como invitado o utilizar DevPlay aceptas estos términos. Si no estás de acuerdo con ellos, no uses la plataforma.',
            'DevPlay se encuentra en fase MVP. Algunas funciones pueden cambiar, suspenderse o incorporarse más adelante.',
          ],
        ),
        _LegalSection(
          heading: '2. Descripción del servicio',
          paragraphs: [
            'DevPlay es una comunidad para desarrolladores indie y jugadores. Permite publicar novedades, devlogs, betas, encuestas y mensajes, así como descubrir proyectos y conversar con otras personas.',
            'El servicio se ofrece tal como está disponible en cada momento. No garantizamos que todas las funciones estén siempre activas ni que el contenido publicado sea verificado por el equipo.',
          ],
        ),
        _LegalSection(
          heading: '3. Cuentas e invitados',
          paragraphs: [
            'Debes proporcionar información razonablemente veraz y mantener la seguridad de tus credenciales. Eres responsable de la actividad realizada desde tu cuenta.',
            'Las cuentas de invitado son temporales y pueden caducar. Para conservar tu contenido y participar plenamente, crea una cuenta registrada.',
          ],
        ),
        _LegalSection(
          heading: '4. Contenido que publicas',
          paragraphs: [
            'Conservas la titularidad de tus publicaciones, imágenes y demás contenido. Al publicarlo, autorizas a DevPlay a almacenarlo, mostrarlo y distribuirlo dentro de la plataforma con el fin de operar el servicio.',
            'Declaras que tienes los derechos necesarios para publicar ese contenido y que no infringe derechos de terceros. No publiques material ilegal, engañoso, malicioso o que no tengas permiso de compartir.',
          ],
        ),
        _LegalSection(
          heading: '5. Betas, descargas y enlaces externos',
          paragraphs: [
            'Las fichas de betas pueden incluir enlaces a archivos o sitios de terceros. DevPlay no controla esos destinos y no garantiza su disponibilidad, seguridad o funcionamiento.',
            'Descarga y ejecuta software de terceros bajo tu propia responsabilidad. Verifica siempre el origen y los permisos de los archivos antes de abrirlos.',
          ],
        ),
        _LegalSection(
          heading: '6. Conducta y moderación',
          bullets: [
            'Trata a las demás personas con respeto y evita el acoso, las amenazas y los ataques personales.',
            'No publiques spam, malware, contenido ilegal, suplantación de identidad ni material que vulnere la privacidad de otras personas.',
            'Podemos revisar, ocultar o retirar contenido, y limitar o suspender cuentas cuando incumplan estos términos o las normas de la comunidad.',
          ],
        ),
        _LegalSection(
          heading: '7. Propiedad intelectual',
          paragraphs: [
            'La marca, el diseño, los textos propios y el código de DevPlay pertenecen a sus respectivos titulares. No puedes copiarlos, redistribuirlos ni utilizarlos para crear un servicio confundible sin autorización.',
            'Las marcas, capturas y materiales de terceros pertenecen a sus propietarios y se muestran con fines informativos o bajo el permiso de quien los publica.',
            'Si consideras que un contenido infringe tus derechos, envía una notificación por los canales oficiales con la identificación de la obra, la URL del contenido, tus datos de contacto y una declaración de buena fe. Podemos retirar el contenido mientras revisamos el caso y tomar medidas contra las cuentas reincidentes.',
          ],
        ),
        _LegalSection(
          heading: '8. Disponibilidad y responsabilidad',
          paragraphs: [
            'El servicio puede tener interrupciones, errores o pérdida de datos. En la medida permitida por la normativa aplicable, DevPlay no será responsable de daños indirectos derivados del uso de la plataforma o de servicios externos enlazados.',
            'Nada de lo anterior excluye responsabilidades que no puedan limitarse legalmente.',
          ],
        ),
        _LegalSection(
          heading: '9. Naturaleza y gratuidad del servicio',
          paragraphs: [
            'DevPlay es gratuito en su fase MVP. No se procesan pagos ni suscripciones dentro de la aplicación. Si en el futuro se añaden funciones de pago, se informará antes de contratarlas y se mostrarán sus condiciones y precios.',
          ],
        ),
        _LegalSection(
          heading: '10. Edad mínima y capacidad',
          paragraphs: [
            'DevPlay no está dirigido a menores de 13 años. Si la ley de tu país exige una edad superior para usar servicios digitales o consentir el tratamiento de tus datos, debes cumplirla.',
            'Si eres menor de edad, utiliza la plataforma con la autorización y supervisión de tu tutor legal.',
          ],
        ),
        _LegalSection(
          heading: '11. Ley aplicable y resolución de conflictos',
          paragraphs: [
            'Estos términos se rigen por las leyes del país donde el operador de DevPlay tenga su domicilio principal, sin perjuicio de las normas imperativas de protección al consumidor o de protección de datos que resulten aplicables en tu país de residencia.',
            'Antes de acudir a los tribunales, intenta resolver la disputa de buena fe a través de los canales oficiales. Los tribunales competentes serán los que determine la ley aplicable.',
          ],
        ),
        _LegalSection(
          heading: '12. Contacto y notificaciones',
          paragraphs: [
            'Las consultas legales, notificaciones de infracción y solicitudes relacionadas con estos términos pueden enviarse a través de los canales oficiales del proyecto. También podemos publicar avisos en la aplicación o en esta pantalla.',
          ],
        ),
        _LegalSection(
          heading: '13. Cambios',
          paragraphs: [
            'Podemos actualizar estos términos para reflejar cambios en el servicio o en la normativa. La versión vigente será la publicada en esta pantalla. El uso continuado después de una actualización implica su aceptación.',
          ],
        ),
      ],
    ),
    _LegalDoc(
      title: 'Política de privacidad',
      icon: Icons.privacy_tip_rounded,
      summary: 'Qué datos usamos, para qué y qué opciones tienes.',
      sections: [
        _LegalSection(
          heading: '1. Alcance',
          paragraphs: [
            'Esta política explica cómo DevPlay trata la información de las personas que usan la aplicación. Se aplica a la cuenta, al perfil, a las publicaciones y a las interacciones dentro de la plataforma.',
          ],
        ),
        _LegalSection(
          heading: '2. Datos que tratamos',
          bullets: [
            'Datos de cuenta y perfil: nombre de usuario, correo electrónico si te registras, avatar, biografía y enlaces que decidas añadir.',
            'Contenido e interacciones: publicaciones, comentarios, mensajes, betas, encuestas, likes, guardados y reportes.',
            'Datos técnicos necesarios: identificadores de sesión, dirección IP, registros de seguridad y datos básicos del navegador o dispositivo.',
            'Preferencias: ajustes de la interfaz y estado del tour guiado guardados en el almacenamiento local del navegador.',
            'No solicitamos datos sensibles (salud, ideología, origen étnico, datos biométricos). Evita publicarlos en tu perfil o en tus contenidos.',
          ],
        ),
        _LegalSection(
          heading: '3. Para qué los usamos',
          bullets: [
            'Prestar el servicio: autenticación, feed, perfiles, chat, betas y notificaciones.',
            'Moderar la comunidad: revisar reportes, prevenir abuso, spam y actividades fraudulentas.',
            'Mantener la seguridad y la disponibilidad de la plataforma.',
            'Mejorar la experiencia y corregir errores de funcionamiento.',
          ],
        ),
        _LegalSection(
          heading: '4. Conservación',
          paragraphs: [
            'Conservamos la información mientras la cuenta esté activa o mientras sea necesaria para prestar el servicio, cumplir obligaciones legales, resolver disputas o mantener la seguridad.',
            'Los registros técnicos y de seguridad pueden conservarse durante un periodo limitado aunque elimines tu contenido.',
          ],
        ),
        _LegalSection(
          heading: '5. Con quién se comparte',
          paragraphs: [
            'No vendemos datos personales. Podemos compartir información con proveedores de infraestructura que alojan la aplicación y la base de datos, o cuando exista una obligación legal.',
            'El contenido que publicas es visible para otras personas según la configuración de la plataforma. No publiques información privada que no quieras compartir.',
          ],
        ),
        _LegalSection(
          heading: '6. Cookies y almacenamiento local',
          paragraphs: [
            'Usamos almacenamiento local del navegador para mantener la sesión, recordar preferencias y evitar que tengas que iniciar sesión en cada visita. No utilizamos cookies publicitarias propias.',
            'Puedes borrar estos datos desde la configuración de tu navegador. Si lo haces, es posible que se cierre la sesión y se restablezcan tus preferencias.',
          ],
        ),
        _LegalSection(
          heading: '7. Seguridad',
          paragraphs: [
            'Aplicamos medidas razonables para proteger la información, como control de acceso y validación de sesiones. Ningún sistema es completamente infalible, por lo que no podemos garantizar una seguridad absoluta.',
          ],
        ),
        _LegalSection(
          heading: '8. Tus derechos y opciones',
          bullets: [
            'Puedes actualizar los datos de tu perfil desde la configuración de la cuenta.',
            'Puedes eliminar publicaciones y comentarios propios cuando la interfaz lo permita.',
            'Puedes solicitar acceso, rectificación, actualización, eliminación, limitación u oposición al tratamiento, y retirar tu consentimiento cuando la ley lo permita.',
            'Puedes solicitar la portabilidad de los datos que hayas proporcionado, cuando resulte aplicable.',
            'Puedes presentar una reclamación ante la autoridad de protección de datos competente en tu país.',
          ],
        ),
        _LegalSection(
          heading: '9. Menores',
          paragraphs: [
            'DevPlay no está dirigido a menores de 13 años. Si la ley de tu país exige una edad superior para consentir el tratamiento de datos, debes cumplirla. Si eres menor, utiliza la plataforma con la autorización y supervisión de tu tutor legal.',
          ],
        ),
        _LegalSection(
          heading: '10. Cambios',
          paragraphs: [
            'Podemos actualizar esta política cuando cambie el tratamiento de datos o la normativa aplicable. Publicaremos la versión vigente en esta pantalla.',
          ],
        ),
        _LegalSection(
          heading: '11. Base legal del tratamiento',
          paragraphs: [
            'Tratamos los datos para ejecutar el servicio que solicitas (cuenta, publicaciones, chat), con tu consentimiento cuando corresponda, por interés legítimo en mantener la seguridad y prevenir abusos, y para cumplir obligaciones legales.',
            'Puedes retirar tu consentimiento en cualquier momento, sin que ello afecte a la licitud del tratamiento realizado antes de la retirada.',
          ],
        ),
        _LegalSection(
          heading: '12. Transferencias internacionales',
          paragraphs: [
            'La infraestructura y los proveedores tecnológicos pueden estar ubicados en un país distinto al tuyo. Cuando se realicen transferencias internacionales de datos, aplicaremos salvaguardas razonables y las garantías que exija la normativa aplicable.',
          ],
        ),
        _LegalSection(
          heading: '13. Contacto y autoridad de control',
          paragraphs: [
            'Para ejercer tus derechos o resolver dudas sobre privacidad, usa los canales oficiales del proyecto. También puedes presentar una reclamación ante la autoridad de protección de datos competente de tu país.',
          ],
        ),
      ],
    ),
    _LegalDoc(
      title: 'Normas de la comunidad',
      icon: Icons.handshake_rounded,
      summary:
          'Cómo mantener DevPlay un espacio seguro para creadores y jugadores.',
      sections: [
        _LegalSection(
          heading: '1. Respeto ante todo',
          paragraphs: [
            'DevPlay es un espacio para compartir proyectos y aprender. Debate las ideas, no ataques a las personas. No se toleran insultos, acoso, amenazas ni discursos de odio.',
          ],
        ),
        _LegalSection(
          heading: '2. Contenido prohibido',
          bullets: [
            'Contenido ilegal, violento o que sexualice a menores.',
            'Acoso, doxxing o publicación de datos privados de otras personas.',
            'Malware, phishing, enlaces engañosos o software que dañe dispositivos.',
            'Suplantación de identidad o cuentas creadas para evadir sanciones.',
            'Piratería, cracks o material que vulnere derechos de autor.',
          ],
        ),
        _LegalSection(
          heading: '3. Publicaciones y betas',
          bullets: [
            'Describe tu beta con información clara: plataformas, requisitos y estado del proyecto.',
            'No prometas funciones que no existen ni presentes como propio el trabajo de otra persona.',
            'Indica cuando un enlace de descarga sea externo y revisa que el archivo sea seguro.',
          ],
        ),
        _LegalSection(
          heading: '4. Spam y autopromoción',
          paragraphs: [
            'Puedes compartir tus proyectos, pero evita publicar el mismo contenido de forma repetitiva, mencionar a personas sin su consentimiento o usar el chat para enviar promociones masivas.',
          ],
        ),
        _LegalSection(
          heading: '5. Reportes',
          paragraphs: [
            'Si ves contenido que incumple estas normas, usa la opción de reporte disponible en la publicación, el usuario, el comentario o la beta. Incluye el motivo y una descripción útil; los reportes falsos o abusivos también pueden ser sancionados.',
          ],
        ),
        _LegalSection(
          heading: '6. Moderación',
          paragraphs: [
            'El equipo puede ocultar contenido, advertir a una cuenta, limitar funciones o suspender el acceso. La gravedad y la reincidencia determinan la medida aplicada.',
          ],
        ),
        _LegalSection(
          heading: '7. Apelaciones',
          paragraphs: [
            'Si crees que una decisión fue incorrecta, puedes explicar tu caso por los canales oficiales del proyecto. Revisaremos la situación y responderemos cuando sea posible.',
          ],
        ),
        _LegalSection(
          heading: '8. Cumplimiento legal y cooperación',
          paragraphs: [
            'Estas normas se aplican junto con los Términos y condiciones y la legislación aplicable. Podemos conservar y compartir información con autoridades competentes cuando exista una obligación legal o un riesgo grave para la seguridad de las personas.',
            'El incumplimiento de estas normas puede dar lugar a medidas dentro de la plataforma y, cuando corresponda, a las acciones legales que permita la ley.',
          ],
        ),
      ],
    ),
    _LegalDoc(
      title: 'Cookies y almacenamiento local',
      icon: Icons.cookie_rounded,
      summary: 'Qué guardamos en tu navegador y cómo puedes borrarlo.',
      sections: [
        _LegalSection(
          heading: '1. Qué son',
          paragraphs: [
            'Las cookies y el almacenamiento local son mecanismos que permiten a una aplicación web recordar información en tu navegador. DevPlay usa sobre todo almacenamiento local para funcionar.',
          ],
        ),
        _LegalSection(
          heading: '2. Almacenamiento esencial',
          paragraphs: [
            'Guardamos el token de sesión para mantenerte identificado y permitir acciones como publicar, comentar o votar. Sin estos datos, la sesión no puede funcionar correctamente.',
          ],
        ),
        _LegalSection(
          heading: '3. Preferencias',
          paragraphs: [
            'Podemos guardar ajustes de la interfaz, como el estado del tour guiado o preferencias de visualización, para que no tengas que configurarlos de nuevo.',
          ],
        ),
        _LegalSection(
          heading: '4. Analítica y publicidad',
          paragraphs: [
            'DevPlay no utiliza cookies publicitarias propias ni vende datos a anunciantes. Si en el futuro se incorpora analítica, se informará y se pedirá el consentimiento cuando corresponda.',
          ],
        ),
        _LegalSection(
          heading: '5. Servicios de terceros',
          paragraphs: [
            'Los enlaces a sitios externos, archivos de betas o servicios de terceros tienen sus propias políticas de cookies y privacidad. Revisa esas políticas antes de interactuar con ellos.',
          ],
        ),
        _LegalSection(
          heading: '6. Cómo borrarlas',
          paragraphs: [
            'Puedes eliminar las cookies y los datos del sitio desde la configuración de tu navegador. Al hacerlo se cerrará la sesión y se perderán las preferencias guardadas localmente.',
          ],
        ),
        _LegalSection(
          heading: '7. Consentimiento y control',
          paragraphs: [
            'Las cookies estrictamente necesarias para la sesión y la seguridad pueden utilizarse sin consentimiento cuando la ley lo permita. Cualquier cookie no esencial se activará solo con tu consentimiento.',
            'Puedes cambiar tus preferencias o revocar el consentimiento desde la configuración del navegador o los mecanismos que habilite la aplicación.',
          ],
        ),
        _LegalSection(
          heading: '8. Cambios y contacto',
          paragraphs: [
            'Si cambiamos el uso de cookies o almacenamiento local, actualizaremos esta información y, cuando sea necesario, solicitaremos tu consentimiento.',
            'Para dudas sobre cookies o privacidad, usa los canales oficiales del proyecto.',
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Volver',
        ),
        title: Text('Acerca de DevPlay', style: DevTheme.display(size: 18)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: DevColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                const SizedBox(height: 26),
                Text(
                  'Legal y comunidad',
                  style: DevTheme.display(size: 18, w: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta las reglas de uso, el tratamiento de tus datos y las normas de convivencia.',
                  style: DevTheme.bodySecondary(size: 12.5),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 640;
                    final tileWidth = wide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final doc in _docs)
                          SizedBox(
                            width: tileWidth,
                            child: _LegalTile(
                              doc: doc,
                              onTap: () => _openLegal(context, doc),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A101D), Color(0xFF0F172A), Color(0xFF0A101D)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: DevColors.primary.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Video 3D en loop como fondo del hero (mismo asset que Inicio).
          Positioned.fill(
            child: HeroVideo(
              videoAsset: 'assets/videos/hero_loop_crystal_loop',
              posterAsset: 'assets/videos/hero_loop_crystal_loop_poster',
              autoPlay: true,
              mute: true,
              shapeOpacity: 0.35,
              shapeStyle: Hero3DStyle.home,
              enablePointerInterceptor: false,
              scrimOpacity: 0.38,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: DevColors.gold35),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        size: 30,
                        color: DevColors.cream,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DevPlay',
                            style: DevTheme.display(
                              size: 26,
                              w: FontWeight.w700,
                            ).copyWith(letterSpacing: -0.6),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'La comunidad para devs indie y jugadores.',
                            style: DevTheme.bodySecondary(size: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hecho con ❤️ para devs indie.',
          style: DevTheme.body(
            size: 13,
            color: DevColors.mutedFg,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'DevPlay está en fase MVP. Esta documentación legal se actualiza junto con el servicio '
          'y no sustituye asesoría legal profesional.',
          style: DevTheme.bodySecondary(size: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Contacto legal: canales oficiales del proyecto.',
          style: DevTheme.bodySecondary(size: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Versión legal 1.0 · Vigente desde $_updated',
          style: DevTheme.bodySecondary(size: 11),
        ),
      ],
    );
  }

  void _openLegal(BuildContext context, _LegalDoc doc) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.86;
        return Dialog(
          backgroundColor: DevColors.card,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: DevColors.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760, maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DevColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          doc.icon,
                          size: 20,
                          color: DevColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          doc.title,
                          style: DevTheme.display(size: 16, w: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: DevColors.mutedFg,
                        ),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                const Divider(color: DevColors.border, height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Última actualización: $_updated',
                            style: DevTheme.bodySecondary(size: 11),
                          ),
                          const SizedBox(height: 16),
                          for (final section in doc.sections)
                            _LegalSectionView(section: section),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(color: DevColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DevColors.primary,
                        foregroundColor: DevColors.primaryFg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Entendido',
                        style: DevTheme.body(
                          size: 13,
                          w: FontWeight.w600,
                          color: DevColors.primaryFg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegalDoc {
  final String title;
  final IconData icon;
  final String summary;
  final List<_LegalSection> sections;

  const _LegalDoc({
    required this.title,
    required this.icon,
    required this.summary,
    required this.sections,
  });
}

class _LegalSection {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;

  const _LegalSection({
    required this.heading,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

class _LegalSectionView extends StatelessWidget {
  final _LegalSection section;

  const _LegalSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: DevTheme.body(size: 14, w: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                paragraph,
                style: DevTheme.body(
                  size: 13,
                  color: DevColors.mutedFg,
                  height: 1.45,
                ),
              ),
            ),
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.circle, size: 5, color: DevColors.gold),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      bullet,
                      style: DevTheme.body(
                        size: 13,
                        color: DevColors.mutedFg,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final _LegalDoc doc;
  final VoidCallback onTap;

  const _LegalTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: DevTheme.glass(radius: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DevColors.primary.withValues(alpha: 0.9),
                      DevColors.gold.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(doc.icon, size: 22, color: DevColors.cream),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doc.summary,
                      style: DevTheme.bodySecondary(size: 11.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Leer documento',
                          style: DevTheme.body(
                            size: 11,
                            w: FontWeight.w600,
                            color: DevColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: DevColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
