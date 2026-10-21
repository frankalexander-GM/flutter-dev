import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../services/store_service.dart';
import '../../theme.dart';

/// Pantalla de la Tienda — power-ups, avatar items, DevCoins (conectada a API real).
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StoreItemsResponse? _catalog;
  BalanceResponse? _balance;
  MyItemsResponse? _myItems;
  bool _loading = true;
  String? _error;

  static const _tabs = [
    ('Power-ups', Icons.flash_on_rounded),
    ('Avatar', Icons.face_rounded),
    ('Premium', Icons.workspace_premium_rounded),
    ('Mis items', Icons.inventory_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        StoreService.getItems(),
        StoreService.getBalance(),
        StoreService.getMyItems(),
      ]);
      setState(() {
        _catalog = results[0] as StoreItemsResponse;
        _balance = results[1] as BalanceResponse;
        _myItems = results[2] as MyItemsResponse;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      appBar: AppBar(
        backgroundColor: DevColors.card,
        elevation: 0,
        title: Text('Tienda DevPlay', style: DevTheme.display(size: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DevColors.gold,
          labelColor: DevColors.gold,
          unselectedLabelColor: DevColors.mutedFg,
          labelStyle: DevTheme.body(size: 13, w: FontWeight.w600),
          isScrollable: true,
          tabs: _tabs
              .map((t) => Tab(icon: Icon(t.$2, size: 20), text: t.$1))
              .toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: DevColors.foreground,
            ),
            onPressed: _loadAll,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorState()
          : Column(
              children: [
                // Header con DevCoins
                _buildCoinsHeader(),
                // Contenido por tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryTab('powerup'),
                      _buildCategoryTab('avatar'),
                      _buildPremiumTab(),
                      _buildMyItemsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: DevColors.mutedFg,
            ),
            const SizedBox(height: 16),
            Text('Error cargando tienda', style: DevTheme.display(size: 16)),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: DevTheme.body(size: 13, color: DevColors.destructive),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAll,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: DevColors.card,
        border: Border(bottom: BorderSide(color: DevColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DevCoins',
                  style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                ),
                Text(
                  '${_balance?.devCoins ?? 0}',
                  style: DevTheme.display(
                    size: 24,
                    w: FontWeight.w700,
                    color: DevColors.gold,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showBuyCoinsDialog,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('Comprar', style: DevTheme.body(size: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DevColors.gold),
              foregroundColor: DevColors.gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String categoryId) {
    final category = _catalog?.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => StoreCategory(id: '', name: '', icon: '', items: []),
    );

    if (category == null || category.items.isEmpty) {
      return Center(
        child: Text(
          'Sin items',
          style: DevTheme.body(color: DevColors.mutedFg),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: category.items.length,
      itemBuilder: (_, i) => _StoreItemCard(
        item: category.items[i],
        devCoins: _balance?.devCoins ?? 0,
        isOwned: category.items[i].isOwned,
        onBuy: () => _buyItem(category.items[i]),
      ),
    );
  }

  Widget _buildPremiumTab() {
    // Items de categoría "premium" o "subscription"
    final premiumItems =
        _catalog?.categories
            .expand((c) => c.items)
            .where(
              (item) =>
                  item.category == 'premium' || item.category == 'subscription',
            )
            .toList() ??
        [];

    if (premiumItems.isEmpty) {
      // Fallback a tiers hardcodeados si no hay en API
      return _buildPremiumTiersFallback();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: premiumItems.length,
      itemBuilder: (_, i) => _StoreItemCard(
        item: premiumItems[i],
        devCoins: _balance?.devCoins ?? 0,
        isOwned: premiumItems[i].isOwned,
        onBuy: () => _buyItem(premiumItems[i]),
      ),
    );
  }

  Widget _buildPremiumTiersFallback() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PremiumTierCard(
          name: 'DevPlay Pro',
          price: '4,99€/mes',
          description: 'Sin límites, sin anuncios, todo desbloqueado',
          features: [
            'DevCoins mensuales: 500',
            'Todos los marcos y fondos',
            'Analytics de tus posts',
            'Soporte prioritario',
            'Badge "Pro" en perfil',
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFF00F0FF), Color(0xFF3B82F6)],
          ),
          onSubscribe: () => _subscribe('Pro'),
        ),
        const SizedBox(height: 16),
        _PremiumTierCard(
          name: 'DevPlay Indie',
          price: '12,99€/mes',
          description: 'Para creadores serios + herramientas de dev',
          features: [
            'Todo lo de Pro +',
            'DevCoins mensuales: 2000',
            'Subir betas ilimitadas',
            'Streaming nativo (pronto)',
            'API access para bots',
            'Badge "Indie Dev"',
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          onSubscribe: () => _subscribe('Indie'),
        ),
      ],
    );
  }

  Widget _buildMyItemsTab() {
    final items = _myItems?.items ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: DevColors.disabled,
            ),
            const SizedBox(height: 16),
            Text('Sin items comprados', style: DevTheme.display(size: 16)),
            const SizedBox(height: 8),
            Text(
              'Tus compras aparecerán aquí',
              style: DevTheme.body(size: 13, color: DevColors.mutedFg),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _MyItemCard(item: items[i]),
    );
  }

  void _showBuyCoinsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DevColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comprar DevCoins', style: DevTheme.display(size: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CoinPack(coins: 500, price: '0,99€', bonus: '+50'),
                _CoinPack(coins: 1200, price: '1,99€', bonus: '+200'),
                _CoinPack(coins: 3000, price: '4,99€', bonus: '+800'),
                _CoinPack(coins: 7000, price: '9,99€', bonus: '+2000'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _buyItem(StoreItem item) async {
    if ((_balance?.devCoins ?? 0) < item.price && !item.isOwned) {
      _showInsufficientCoins();
      return;
    }
    if (item.isOwned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya tienes "${item.name}"'),
          backgroundColor: DevColors.amber,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Comprar ${item.name}', style: DevTheme.display(size: 16)),
        content: Text(
          'Cuesta ${item.price} DevCoins. ¿Confirmas?',
          style: DevTheme.body(size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: DevTheme.body(color: DevColors.mutedFg),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.primary,
              foregroundColor: DevColors.primaryFg,
            ),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await StoreService.buyItem(item.id);
      if (result.success) {
        setState(
          () => _balance = BalanceResponse(
            devCoins: result.newBalance,
            recentTransactions: _balance!.recentTransactions,
          ),
        );
        await _loadAll(); // recargar catálogo para actualizar isOwned
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '${item.name} comprado!'),
              backgroundColor: DevColors.consoleGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Error en la compra'),
              backgroundColor: DevColors.destructive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: DevColors.destructive),
        );
      }
    }
  }

  void _subscribe(String tier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DevColors.card,
        title: Text('Suscribirse a $tier', style: DevTheme.display(size: 16)),
        content: Text(
          'Redirigiendo a Stripe... (demo)',
          style: DevTheme.body(size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: DevTheme.body(color: DevColors.mutedFg),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Suscripción $tier activada (demo)'),
                  backgroundColor: DevColors.consoleGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DevColors.primary,
              foregroundColor: DevColors.primaryFg,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientCoins() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('DevCoins insuficientes'),
        backgroundColor: DevColors.destructive,
      ),
    );
  }
}

/// Card de item en la tienda (catálogo).
class _StoreItemCard extends StatelessWidget {
  final StoreItem item;
  final int devCoins;
  final bool isOwned;
  final VoidCallback onBuy;

  const _StoreItemCard({
    required this.item,
    required this.devCoins,
    required this.isOwned,
    required this.onBuy,
  });

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFE8A838);
      case 'epic':
        return const Color(0xFF9B59E8);
      case 'rare':
        return const Color(0xFF4A9F9A);
      default:
        return DevColors.mutedFg;
    }
  }

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'flash_on':
        return Icons.flash_on_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  LinearGradient _gradientForRarity(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const LinearGradient(
          colors: [Color(0xFFE8A838), Color(0xFFC88818)],
        );
      case 'epic':
        return const LinearGradient(
          colors: [Color(0xFF9B59E8), Color(0xFF7B39C8)],
        );
      case 'rare':
        return const LinearGradient(
          colors: [Color(0xFF4A9F9A), Color(0xFF3A7A7A)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF00F0FF), Color(0xFF3B82F6)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = devCoins >= item.price;
    final rarityColor = _rarityColor(item.rarity);
    final gradient = _gradientForRarity(item.rarity);
    final iconData = _iconFromString(item.icon);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DevTheme.glassStrong(radius: 12).copyWith(
        border: isOwned
            ? Border.all(color: DevColors.consoleGreen, width: 1.5)
            : Border.all(color: DevColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: gradient,
            ),
            child: Icon(iconData, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: DevTheme.body(size: 15, w: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: DevTheme.body(
                          size: 9,
                          w: FontWeight.w700,
                          color: rarityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                ),
                if (isOwned) ...[
                  const SizedBox(height: 4),
                  Text(
                    '✓ Ya poseído',
                    style: DevTheme.body(
                      size: 11,
                      w: FontWeight.w600,
                      color: DevColors.consoleGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    size: 16,
                    color: DevColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.price}',
                    style: DevTheme.body(
                      size: 15,
                      w: FontWeight.w700,
                      color: DevColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: (canAfford || isOwned) ? onBuy : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOwned
                      ? DevColors.consoleGreen
                      : DevColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  disabledBackgroundColor: DevColors.muted,
                ),
                child: Text(
                  isOwned ? 'Poseído' : 'Comprar',
                  style: DevTheme.body(size: 12, w: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de item ya comprado (pestaña "Mis items").
class _MyItemCard extends StatelessWidget {
  final StoreItem item;

  const _MyItemCard({required this.item});

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFE8A838);
      case 'epic':
        return const Color(0xFF9B59E8);
      case 'rare':
        return const Color(0xFF4A9F9A);
      default:
        return DevColors.mutedFg;
    }
  }

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'flash_on':
        return Icons.flash_on_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(item.rarity);
    final iconData = _iconFromString(item.icon);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: DevTheme.glassStrong(radius: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [rarityColor, rarityColor.withValues(alpha: 0.7)],
              ),
            ),
            child: Icon(iconData, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: DevTheme.body(size: 14, w: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: DevTheme.body(
                          size: 9,
                          w: FontWeight.w700,
                          color: rarityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  item.description,
                  style: DevTheme.body(size: 11, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DevColors.consoleGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'POSEÍDO',
              style: DevTheme.body(
                size: 9,
                w: FontWeight.w700,
                color: DevColors.consoleGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPack extends StatelessWidget {
  final int coins;
  final String price;
  final String bonus;

  const _CoinPack({
    required this.coins,
    required this.price,
    required this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final total = coins + int.parse(bonus.replaceAll('+', ''));
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: DevTheme.glassStrong(radius: 12),
        child: Column(
          children: [
            Text(
              '$total',
              style: DevTheme.display(
                size: 24,
                w: FontWeight.w700,
                color: DevColors.gold,
              ),
            ),
            Text(
              'DevCoins',
              style: DevTheme.body(size: 12, color: DevColors.mutedFg),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DevColors.consoleGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                bonus,
                style: DevTheme.body(
                  size: 10,
                  w: FontWeight.w700,
                  color: DevColors.consoleGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(price, style: DevTheme.display(size: 16, w: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: DevColors.primary,
                foregroundColor: DevColors.primaryFg,
                minimumSize: const Size.fromHeight(36),
              ),
              child: Text(
                'Comprar',
                style: DevTheme.body(size: 12, w: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumTierCard extends StatelessWidget {
  final String name;
  final String price;
  final String description;
  final List<String> features;
  final LinearGradient gradient;
  final VoidCallback onSubscribe;

  const _PremiumTierCard({
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    required this.gradient,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DevTheme.glassStrong(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: gradient,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: DevTheme.display(size: 20, w: FontWeight.w700),
                    ),
                    Text(
                      price,
                      style: DevTheme.body(
                        size: 14,
                        w: FontWeight.w600,
                        color: DevColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: DevTheme.body(size: 13, color: DevColors.mutedFg),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: DevColors.consoleGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: DevTheme.body(size: 13))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: gradient.colors.first,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Suscribirse a $name',
                style: DevTheme.body(size: 14, w: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
