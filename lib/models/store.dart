/// Modelos de tienda — claves idénticas a `app/schemas/store.py` del backend.
library;

/// Respuesta de `GET /store/items` — catálogo agrupado por categoría.
class StoreItemsResponse {
  final List<StoreCategory> categories;

  const StoreItemsResponse({required this.categories});

  factory StoreItemsResponse.fromJson(Map<String, dynamic> json) =>
      StoreItemsResponse(
        categories: (json['categories'] as List? ?? [])
            .map((e) => StoreCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Categoría de items en la tienda.
class StoreCategory {
  final String id;
  final String name;
  final String icon;
  final List<StoreItem> items;

  const StoreCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.items,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) => StoreCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        items: (json['items'] as List? ?? [])
            .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Item individual de la tienda.
class StoreItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String icon;
  final String rarity; // common, rare, epic, legendary
  final bool isOwned;

  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
    required this.rarity,
    required this.isOwned,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        price: json['price'] as int,
        category: json['category'] as String,
        icon: json['icon'] as String,
        rarity: json['rarity'] as String? ?? 'common',
        isOwned: json['is_owned'] as bool? ?? false,
      );
}

/// Respuesta de `GET /store/balance` — DevCoins + transacciones.
class BalanceResponse {
  final int devCoins;
  final List<Transaction> recentTransactions;

  const BalanceResponse({
    required this.devCoins,
    required this.recentTransactions,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) =>
      BalanceResponse(
        devCoins: json['dev_coins'] as int? ?? 0,
        recentTransactions: (json['recent_transactions'] as List? ?? [])
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Transacción de DevCoins.
class Transaction {
  final String id;
  final int amount;
  final String type; // earn, spend, purchase, reward
  final String description;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        amount: json['amount'] as int,
        type: json['type'] as String,
        description: json['description'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Respuesta de `POST /store/buy`.
class BuyResponse {
  final bool success;
  final String? message;
  final int newBalance;
  final StoreItem? item;

  const BuyResponse({
    required this.success,
    this.message,
    required this.newBalance,
    this.item,
  });

  factory BuyResponse.fromJson(Map<String, dynamic> json) => BuyResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String?,
        newBalance: json['new_balance'] as int? ?? 0,
        item: json['item'] != null
            ? StoreItem.fromJson(json['item'] as Map<String, dynamic>)
            : null,
      );
}

/// Respuesta de `GET /store/my-items`.
class MyItemsResponse {
  final List<StoreItem> items;

  const MyItemsResponse({required this.items});

  factory MyItemsResponse.fromJson(Map<String, dynamic> json) =>
      MyItemsResponse(
        items: (json['items'] as List? ?? [])
            .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}