import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/beta.dart';
import '../services/beta_service.dart';
import '../theme.dart';
import '../widgets/beta_compose_sheet.dart';

/// Vista de Betas: laboratorio de builds tempranas de la comunidad.
class BetasScreen extends StatefulWidget {
  /// Cambia cuando se crea una beta desde fuera de esta vista (drawer/crear).
  final int refreshToken;

  const BetasScreen({super.key, this.refreshToken = 0});

  @override
  State<BetasScreen> createState() => _BetasScreenState();
}

class _BetasScreenState extends State<BetasScreen> {
  List<Beta> _betas = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BetasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final betas = await BetaService.getBetas(limit: 50);
      betas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      final statuses = betas.map((b) => b.betaStatus).toSet();
      final nextFilter =
          _filter == 'all' || statuses.contains(_filter) ? _filter : 'all';
      setState(() {
        _betas = betas;
        _filter = nextFilter;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Beta> get _filtered => _filter == 'all'
      ? _betas
      : _betas.where((b) => b.betaStatus == _filter).toList();

  List<String> get _statuses {
    final present = _betas.map((b) => b.betaStatus).toSet();
    const order = [
      'open_beta',
      'coming_soon',
      'alpha',
      'tech_test',
      'early_access',
      'closed_beta',
      'ended',
    ];
    final list = <String>['all'];
    for (final status in order) {
      if (present.contains(status)) list.add(status);
    }
    for (final status in present) {
      if (!list.contains(status)) list.add(status);
    }
    return list;
  }

  Future<void> _createBeta() async {
    final created = await showBetaComposeSheet(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Beta publicada!')),
      );
      await _load();
    }
  }

  Future<void> _download(Beta beta) async {
    if (_busyId != null) return;
    setState(() => _busyId = beta.id);
    try {
      final result = await BetaService.registerDownload(beta.id);
      final url = (result['url'] ?? '').toString();
      if (url.isNotEmpty) {
        var opened = false;
        final uri = Uri.tryParse(url);
        if (uri != null) {
          try {
            opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            opened = false;
          }
        }
        if (!opened) {
          await Clipboard.setData(ClipboardData(text: url));
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? 'Abriendo la descarga...'
                  : 'Enlace de descarga copiado',
            ),
          ),
        );
      }
      final downloads = result['downloads'];
      final index = _betas.indexWhere((b) => b.id == beta.id);
      if (downloads is int && index >= 0) {
        setState(() {
          _betas[index] = _betas[index].copyWith(downloads: downloads);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showDetails(Beta beta) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: DevColors.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (beta.coverImage != null && beta.coverImage!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    beta.coverImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => _betaCoverFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    beta.title,
                    style: DevTheme.display(size: 20, w: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DevColors.mutedFg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  label: betaStatusLabel(beta.betaStatus),
                  color: betaStatusColor(beta.betaStatus),
                ),
                if (beta.version != null && beta.version!.isNotEmpty)
                  _Pill(label: beta.version!, color: DevColors.goldSoft),
                if (beta.genre != null && beta.genre!.isNotEmpty)
                  _Pill(label: beta.genre!, color: DevColors.mutedFg),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              beta.description,
              style: DevTheme.body(size: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: DevColors.mutedFg,
                ),
                const SizedBox(width: 6),
                Text(
                  '${beta.downloads} descargas',
                  style: DevTheme.bodySecondary(size: 12),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.event_rounded,
                  size: 16,
                  color: DevColors.mutedFg,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(beta.createdAt),
                  style: DevTheme.bodySecondary(size: 12),
                ),
              ],
            ),
            if (beta.externalUrl != null && beta.externalUrl!.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: beta.externalUrl!),
                    );
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado')),
                    );
                  },
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copiar enlace'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DevColors.goldSoft,
                    side: const BorderSide(color: DevColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHowItWorks() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DevColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DevColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.science_rounded, color: DevColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cómo funcionan las betas',
                style: DevTheme.display(size: 17, w: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Step(
              number: '1',
              text: 'Publica tu build con versión y enlace de descarga.',
            ),
            SizedBox(height: 12),
            _Step(
              number: '2',
              text: 'Los testers la prueban y dejan feedback en el post.',
            ),
            SizedBox(height: 12),
            _Step(
              number: '3',
              text: 'Itera, actualiza la versión y vuelve a compartir.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendido',
              style: DevTheme.body(
                size: 13,
                w: FontWeight.w700,
                color: DevColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: _load,
      color: DevColors.primary,
      backgroundColor: DevColors.card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: _BetasHero(
                count: _betas.length,
                onCreateBeta: _createBeta,
                onHowItWorks: _showHowItWorks,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DevColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      size: 18,
                      color: DevColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Betas de la comunidad',
                      style: DevTheme.display(size: 18, w: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_loading && _betas.isNotEmpty)
                    Text(
                      '${filtered.length}',
                      style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                    ),
                ],
              ),
            ),
          ),
          if (!_loading && _betas.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _filters(),
              ),
            ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: DevColors.primary),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _errorCard(),
              ),
            )
          else if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _emptyState(),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1020
                        ? 3
                        : (constraints.maxWidth >= 660 ? 2 : 1);
                    const gap = 14.0;
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: filtered
                          .map((beta) => SizedBox(
                                width: cardWidth,
                                child: _BetaCard(
                                  beta: beta,
                                  busy: _busyId == beta.id,
                                  onDownload: () => _download(beta),
                                  onDetails: () => _showDetails(beta),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statuses.map((status) {
          final selected = _filter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _filterLabel(status),
                style: DevTheme.body(
                  size: 12,
                  w: FontWeight.w600,
                  color: selected ? DevColors.primaryFg : DevColors.mutedFg,
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filter = status),
              backgroundColor: DevColors.card,
              selectedColor: DevColors.primary,
              side: BorderSide(
                color: selected ? DevColors.primary : DevColors.border,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DevColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_rounded,
              size: 30,
              color: DevColors.gold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _filter == 'all'
                ? 'Todavía no hay betas publicadas'
                : 'No hay betas en este estado',
            style: DevTheme.display(size: 16, w: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _filter == 'all'
                ? 'Sé el primero en compartir una build y encontrar testers para tu juego.'
                : 'Prueba con otro filtro o publica una nueva beta.',
            style: DevTheme.body(
              size: 12.5,
              color: DevColors.mutedFg,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createBeta,
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Subir mi beta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DevColors.primary,
                foregroundColor: DevColors.primaryFg,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showHowItWorks,
            child: Text(
              'Cómo funciona',
              style: DevTheme.body(
                size: 12.5,
                w: FontWeight.w600,
                color: DevColors.goldSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 30,
            color: DevColors.mutedFg,
          ),
          const SizedBox(height: 10),
          Text(
            'No se pudieron cargar las betas',
            style: DevTheme.body(size: 14, w: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _error!,
            style: DevTheme.bodySecondary(size: 11.5),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DevColors.primary,
              side: const BorderSide(color: DevColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero de la vista Betas.
class _BetasHero extends StatelessWidget {
  final int count;
  final VoidCallback onCreateBeta;
  final VoidCallback onHowItWorks;

  const _BetasHero({
    required this.count,
    required this.onCreateBeta,
    required this.onHowItWorks,
  });

  static Widget _pixel(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF45271C), Color(0xFF2E1F19), Color(0xFF1F1714)],
        ),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: DevColors.gold.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Resplandor cálido
          Positioned(
            top: -90,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DevColors.wine.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Marca de agua de laboratorio
          Positioned(
            right: -24,
            bottom: -34,
            child: Transform.rotate(
              angle: -0.15,
              child: Icon(
                Icons.science_rounded,
                size: 180,
                color: DevColors.gold.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Trama de píxeles
          Positioned(
            top: 26,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _pixel(DevColors.gold, 10, 0.45),
                    const SizedBox(width: 6),
                    _pixel(DevColors.primary, 10, 0.5),
                    const SizedBox(width: 6),
                    _pixel(DevColors.gold, 6, 0.3),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pixel(DevColors.primary, 6, 0.35),
                    const SizedBox(width: 6),
                    _pixel(DevColors.gold, 10, 0.5),
                    const SizedBox(width: 6),
                    _pixel(DevColors.primary, 10, 0.35),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pixel(DevColors.gold, 6, 0.25),
                    const SizedBox(width: 6),
                    _pixel(DevColors.primary, 6, 0.3),
                    const SizedBox(width: 6),
                    _pixel(DevColors.gold, 10, 0.4),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 560;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DevColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: DevColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: DevColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LABORATORIO DE BETAS',
                            style: DevTheme.labelCaps(
                              size: 10,
                              color: DevColors.goldSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [DevColors.foreground, DevColors.goldSoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'Prueba antes\nque nadie',
                        style: DevTheme.display(
                          size: wide ? 40 : 28,
                          w: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        'Comparte builds tempranas de tu juego y encuentra testers '
                        'que te ayuden a pulirlo antes del lanzamiento.',
                        style: DevTheme.body(
                          size: wide ? 15 : 13.5,
                          color: DevColors.mutedFg,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroPill(
                          icon: Icons.science_rounded,
                          label: 'Builds tempranas',
                        ),
                        _HeroPill(
                          icon: Icons.forum_rounded,
                          label: 'Feedback real',
                        ),
                        _HeroPill(
                          icon: Icons.people_alt_rounded,
                          label: 'Testers',
                        ),
                      ],
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: DevColors.consoleGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: DevColors.consoleGreen.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: DevColors.consoleGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$count ${count == 1 ? 'beta publicada' : 'betas publicadas'}',
                              style: DevTheme.body(
                                size: 12,
                                w: FontWeight.w600,
                                color: DevColors.consoleGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (wide)
                      Row(
                        children: [
                          _primaryCta(),
                          const SizedBox(width: 12),
                          _secondaryCta(),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(width: double.infinity, child: _primaryCta()),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _secondaryCta(),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta() {
    return ElevatedButton.icon(
      onPressed: onCreateBeta,
      icon: const Icon(Icons.rocket_launch_rounded, size: 19),
      label: Text(
        'Subir mi beta',
        style: DevTheme.body(
          size: 14,
          w: FontWeight.w700,
          color: DevColors.primaryFg,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: DevColors.primary,
        foregroundColor: DevColors.primaryFg,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Widget _secondaryCta() {
    return OutlinedButton.icon(
      onPressed: onHowItWorks,
      icon: const Icon(Icons.help_outline_rounded, size: 19),
      label: Text(
        'Cómo funciona',
        style: DevTheme.body(
          size: 14,
          w: FontWeight.w700,
          color: DevColors.goldSoft,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: DevColors.goldSoft,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        side: BorderSide(color: DevColors.gold.withValues(alpha: 0.6), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DevColors.white08,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DevColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DevColors.gold),
          const SizedBox(width: 7),
          Text(
            label,
            style: DevTheme.body(
              size: 12,
              w: FontWeight.w600,
              color: DevColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _BetaCard extends StatelessWidget {
  final Beta beta;
  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onDetails;

  const _BetaCard({
    required this.beta,
    required this.busy,
    required this.onDownload,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasDownload =
        (beta.externalUrl != null && beta.externalUrl!.isNotEmpty) ||
            (beta.fileUrl != null && beta.fileUrl!.isNotEmpty);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DevColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DevColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (beta.coverImage != null && beta.coverImage!.isNotEmpty)
                  Image.network(
                    beta.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _betaCoverFallback(),
                  )
                else
                  _betaCoverFallback(),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Pill(
                    label: betaStatusLabel(beta.betaStatus),
                    color: betaStatusColor(beta.betaStatus),
                  ),
                ),
                if (beta.version != null && beta.version!.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DevColors.background.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: DevColors.border),
                      ),
                      child: Text(
                        beta.version!,
                        style: DevTheme.mono(
                          size: 11,
                          color: DevColors.goldSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beta.title,
                  style: DevTheme.display(size: 16.5, w: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (beta.genre != null && beta.genre!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    beta.genre!,
                    style: DevTheme.bodySecondary(size: 11.5),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  beta.description,
                  style: DevTheme.body(
                    size: 12.5,
                    color: DevColors.mutedFg,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.download_rounded,
                      size: 15,
                      color: DevColors.mutedFg,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${beta.downloads}',
                      style: DevTheme.bodySecondary(size: 12),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: DevColors.mutedFg,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Detalles',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (hasDownload) ...[
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: busy ? null : onDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DevColors.primary,
                          foregroundColor: DevColors.primaryFg,
                          disabledBackgroundColor:
                              DevColors.primary.withValues(alpha: 0.4),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Descargar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _betaCoverFallback() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A261C), Color(0xFF241A15)],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.science_rounded,
        size: 42,
        color: DevColors.gold.withValues(alpha: 0.35),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: DevTheme.body(size: 11, w: FontWeight.w700, color: color),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DevColors.gold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: DevColors.gold.withValues(alpha: 0.5)),
          ),
          child: Text(
            number,
            style: DevTheme.body(
              size: 11,
              w: FontWeight.w700,
              color: DevColors.goldSoft,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: DevTheme.body(
              size: 12.5,
              color: DevColors.mutedFg,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

String betaStatusLabel(String status) {
  switch (status) {
    case 'open_beta':
      return 'Beta abierta';
    case 'closed_beta':
      return 'Beta cerrada';
    case 'coming_soon':
      return 'Próximamente';
    case 'alpha':
      return 'Alpha';
    case 'tech_test':
      return 'Prueba técnica';
    case 'early_access':
      return 'Acceso anticipado';
    case 'ended':
      return 'Finalizada';
    default:
      return status.replaceAll('_', ' ');
  }
}

Color betaStatusColor(String status) {
  switch (status) {
    case 'open_beta':
      return DevColors.consoleGreen;
    case 'coming_soon':
      return DevColors.gold;
    case 'alpha':
    case 'tech_test':
    case 'early_access':
      return DevColors.primary;
    case 'closed_beta':
    case 'ended':
      return DevColors.mutedFg;
    default:
      return DevColors.mutedFg;
  }
}

String _filterLabel(String status) {
  switch (status) {
    case 'all':
      return 'Todas';
    case 'open_beta':
      return 'Abiertas';
    case 'closed_beta':
      return 'Cerradas';
    case 'coming_soon':
      return 'Próximamente';
    case 'alpha':
      return 'Alpha';
    case 'tech_test':
      return 'Prueba técnica';
    case 'early_access':
      return 'Acceso anticipado';
    case 'ended':
      return 'Finalizadas';
    default:
      return status.replaceAll('_', ' ');
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
