import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme.dart';

/// Pantalla de Reportes — moderación comunitaria (solo usuarios logueados).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _myReports = [];
  List<Map<String, dynamic>> _pendingReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) return;

      // TODO: endpoints reales /reports/mine y /reports/pending (moderadores)
      // Mock data para demo
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _myReports = [
          {
            'id': 'r1',
            'postId': 'p1',
            'reason': 'spam',
            'description': 'Contenido promocional no solicitado',
            'status': 'PENDING',
            'createdAt': DateTime.now().subtract(const Duration(days: 2)),
            'postPreview': 'Comprá mi curso de Unity barato...',
          },
          {
            'id': 'r2',
            'postId': 'p2',
            'reason': 'offensive',
            'description': 'Lenguaje inapropiado',
            'status': 'RESOLVED',
            'action': 'Post eliminado',
            'createdAt': DateTime.now().subtract(const Duration(days: 5)),
            'postPreview': 'Este juego es una mierda total...',
          },
        ];
        _pendingReports = [
          {
            'id': 'r3',
            'postId': 'p3',
            'reporterId': 'u1',
            'reporterName': 'gamer123',
            'reason': 'spam',
            'description': 'Bots promocionando crypto',
            'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
            'postPreview': 'GANA DINERO FÁCIL CON CRYPTO!!!',
          },
          {
            'id': 'r4',
            'postId': 'p4',
            'reporterId': 'u2',
            'reporterName': 'dev_ana',
            'reason': 'bug_report',
            'description': 'Beta crashea al iniciar',
            'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
            'postPreview': 'La beta v0.3 no arranca en Windows 11...',
          },
        ];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isMod = auth.user?.role == 'DEV' || auth.user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.card,
        elevation: 0,
        title: Text('Reportes', style: DevTheme.display(size: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DevColors.gold,
          labelColor: DevColors.gold,
          unselectedLabelColor: DevColors.mutedFg,
          labelStyle: DevTheme.body(size: 13, w: FontWeight.w600),
          tabs: [
            const Tab(icon: Icon(Icons.assignment_rounded, size: 20), text: 'Mis reportes'),
            if (isMod) const Tab(icon: Icon(Icons.gavel_rounded, size: 20), text: 'Moderar'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyReports(),
                if (isMod) _buildPendingReports() else _buildNotMod(),
              ],
            ),
    );
  }

  Widget _buildMyReports() {
    if (_myReports.isEmpty) {
      return _emptyState(
        icon: Icons.assignment_rounded,
        title: 'Sin reportes',
        subtitle: 'Aquí verás el estado de tus reportes enviados',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myReports.length,
      itemBuilder: (_, i) => _ReportCard(report: _myReports[i], isMod: false),
    );
  }

  Widget _buildPendingReports() {
    if (_pendingReports.isEmpty) {
      return _emptyState(
        icon: Icons.gavel_rounded,
        title: 'Cola vacía',
        subtitle: 'No hay reportes pendientes de moderar',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReports.length,
      itemBuilder: (_, i) => _ModerationCard(report: _pendingReports[i], onAction: _resolveReport),
    );
  }

  Widget _buildNotMod() {
    return _emptyState(
      icon: Icons.lock_rounded,
      title: 'Solo moderadores',
      subtitle: 'Esta sección es para el equipo de moderación',
      action: TextButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacta a un admin si quieres moderar')),
        ),
        child: Text('Solicitar acceso', style: DevTheme.body(color: DevColors.primary)),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: DevColors.muted),
            const SizedBox(height: 16),
            Text(title, style: DevTheme.display(size: 18)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: DevTheme.body(size: 14, color: DevColors.mutedFg)),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  void _resolveReport(String reportId, String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Resolver reporte', style: DevTheme.display(size: 16)),
        content: Text('Aplicar: $action', style: DevTheme.body(size: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: DevTheme.body(color: DevColors.mutedFg))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _pendingReports.removeWhere((r) => r['id'] == reportId));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reporte $action'), backgroundColor: DevColors.consoleGreen));
            },
            style: ElevatedButton.styleFrom(backgroundColor: DevColors.primary, foregroundColor: DevColors.primaryFg),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool isMod;

  const _ReportCard({required this.report, required this.isMod});

  @override
  Widget build(BuildContext context) {
    final status = report['status'] as String;
    final statusColor = status == 'PENDING' ? DevColors.amber : (status == 'RESOLVED' ? DevColors.consoleGreen : DevColors.destructive);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DevTheme.glassStrong(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                child: Text(status, style: DevTheme.body(size: 10, w: FontWeight.w700, color: statusColor)),
              ),
              const Spacer(),
              Text(_formatDate(report['createdAt'] as DateTime), style: DevTheme.body(size: 11, color: DevColors.mutedFg)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Motivo: ${_reasonLabel(report['reason'] as String)}', style: DevTheme.body(size: 13, w: FontWeight.w600)),
          if (report['description'] != null) ...[
            const SizedBox(height: 4),
            Text(report['description'] as String, style: DevTheme.body(size: 12, color: DevColors.mutedFg)),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DevColors.cardRaised, borderRadius: BorderRadius.circular(8), border: Border.all(color: DevColors.border)),
            child: Text(report['postPreview'] as String, style: DevTheme.body(size: 12, color: DevColors.foreground)),
          ),
          if (report['action'] != null) ...[
            const SizedBox(height: 8),
            Text('Acción: ${report['action']}', style: DevTheme.body(size: 11, color: DevColors.consoleGreen, w: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'spam': return 'Spam / Promocional';
      case 'offensive': return 'Ofensivo / Tóxico';
      case 'bug_report': return 'Bug en beta';
      case 'misinfo': return 'Información falsa';
      case 'nsfw': return 'Contenido NSFW';
      default: return reason;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}min';
  }
}

class _ModerationCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final Function(String, String) onAction;

  const _ModerationCard({required this.report, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DevTheme.glassStrong(radius: 12).copyWith(
        border: Border.all(color: DevColors.wine.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: DevColors.wine.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                child: Text('PENDIENTE', style: DevTheme.body(size: 10, w: FontWeight.w700, color: DevColors.wine)),
              ),
              const Spacer(),
              Text(_formatDate(report['createdAt'] as DateTime), style: DevTheme.body(size: 11, color: DevColors.mutedFg)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: DevColors.mutedFg),
              const SizedBox(width: 6),
              Text('Reportado por: ${report['reporterName']}', style: DevTheme.body(size: 13, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Motivo: ${_reasonLabel(report['reason'] as String)}', style: DevTheme.body(size: 13, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(report['description'] as String, style: DevTheme.body(size: 12, color: DevColors.mutedFg)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DevColors.cardRaised, borderRadius: BorderRadius.circular(8), border: Border.all(color: DevColors.border)),
            child: Text(report['postPreview'] as String, style: DevTheme.body(size: 12, color: DevColors.foreground)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => onAction(report['id'] as String, 'Eliminar post'), icon: const Icon(Icons.delete_rounded, size: 16), label: Text('Eliminar post', style: DevTheme.body(size: 12)), style: OutlinedButton.styleFrom(foregroundColor: DevColors.destructive, side: const BorderSide(color: DevColors.destructive)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => onAction(report['id'] as String, 'Advertir usuario'), icon: const Icon(Icons.warning_rounded, size: 16), label: Text('Advertir', style: DevTheme.body(size: 12)), style: OutlinedButton.styleFrom(foregroundColor: DevColors.amber, side: const BorderSide(color: DevColors.amber)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => onAction(report['id'] as String, 'Descartar'), icon: const Icon(Icons.check_circle_rounded, size: 16), label: Text('Descartar', style: DevTheme.body(size: 12)))),
            ],
          ),
        ],
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'spam': return 'Spam / Promocional';
      case 'offensive': return 'Ofensivo / Tóxico';
      case 'bug_report': return 'Bug en beta';
      case 'misinfo': return 'Información falsa';
      case 'nsfw': return 'Contenido NSFW';
      default: return reason;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}min';
  }
}