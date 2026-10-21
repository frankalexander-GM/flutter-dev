import '../models/store.dart';
import 'api_service.dart';

/// Servicio de tienda — endpoints `/store/*`.
class StoreService {
  /// `GET /store/items` → catálogo completo.
  static Future<StoreItemsResponse> getItems() async {
    final data = await ApiService.getJson('/store/items', auth: false);
    return StoreItemsResponse.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /store/balance` → DevCoins + transacciones recientes.
  static Future<BalanceResponse> getBalance() async {
    final data = await ApiService.getJson('/store/balance');
    return BalanceResponse.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /store/buy` → compra un item.
  static Future<BuyResponse> buyItem(String itemId) async {
    final data = await ApiService.postJson('/store/buy', body: {'item_id': itemId});
    return BuyResponse.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /store/my-items` → items comprados.
  static Future<MyItemsResponse> getMyItems() async {
    final data = await ApiService.getJson('/store/my-items');
    return MyItemsResponse.fromJson(data as Map<String, dynamic>);
  }
}