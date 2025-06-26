import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/sales_db_service.dart';
import '../../models/sale_model.dart';
import '../../models/sale_item_model.dart';
import '../../models/customer_model.dart';
import '../../models/stock_model.dart';
import 'stock_service.dart';
import 'sync_service.dart';

class SalesService {
  final SalesDbService _salesDbService;
  final SupabaseClient _supabaseClient;
  final StockService _stockService;
  late final SyncService _syncService;
  static const double _vatRate = 0.0; // 16% VAT rate

  SalesService(
    this._salesDbService,
    this._supabaseClient,
    this._stockService,
  ) {
    _syncService = SyncService(_salesDbService);
  }

  Future<void> addSale(Sale sale) async {
    // Validate all items have sufficient stock
    for (var item in sale.items) {
      final stockItem = await _stockService.getStockItemById(item.productId);
      if (stockItem == null) {
        throw Exception('Product not found: ${item.productId}');
      }
      if (stockItem.quantity < item.quantity) {
        throw Exception('Insufficient stock for ${stockItem.productName}');
      }
    }

    // Update stock quantities
    for (var item in sale.items) {
      final stockItem = await _stockService.getStockItemById(item.productId);
      await _stockService.updateStockQuantity(
        item.productId,
        stockItem!.quantity - item.quantity,
      );
    }

    // Save sale and items locally
    try {
      await _salesDbService.insertSale(sale);
    } catch (e) {
      print('Local database error: $e');
      throw Exception('Failed to save sale locally: ${e.toString()}');
    }

    // Try to sync with Supabase immediately if possible
    try {
      final saleData = {
        'id': sale.id,
        'outlet_id': sale.outletId,
        'rep_id': sale.repId,
        'customer_id': sale.customerId,
        'vat': sale.vat,
        'total_amount': sale.totalAmount,
        'created_at': DateTime.now().toIso8601String(),
        'items': sale.items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                })
            .toList(),
      };

      // Start a transaction
      final response = await _supabaseClient.rpc('create_sale_with_items', params: {
        'sale_data': saleData,
      });
      
      final serverSaleId = response['id'] as String;

      await _salesDbService.markSaleAsSynced(sale.id, serverSaleId);
    } catch (e) {
      print('Failed to sync sale with Supabase: $e');
    }
  }

  Future<Customer?> findCustomerByPhone(String phone) async {
    try {
      final response = await _supabaseClient
          .from('customers')
          .select()
          .eq('phone', phone)
          .single();
      return Customer.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await _supabaseClient
        .from('customers')
        .insert(customer.toMap())
        .select()
        .single();
    return Customer.fromMap(response);
  }

  Future<List<Sale>> getAllSales() async {
    return await _salesDbService.getAllSales();
  }

  Future<void> resetDatabase() async {
    await _salesDbService.resetDatabase();
  }

  Future<List<Sale>> getUnsyncedSales() async {
    return await _syncService.getUnsyncedSales();
  }

  Future<SyncResult> syncAllPendingSales() async {
    return await _syncService.syncAllPendingSales();
  }

  Future<List<Sale>> getFilteredSales({
    required DateTime startDate,
    required DateTime endDate,
    String? productId,
    String? repId,
    String? customerId,
  }) async {
    List<Sale> sales =
        await _salesDbService.getSalesByDateRange(startDate, endDate);

    if (productId != null) {
      sales = sales
          .where(
              (sale) => sale.items.any((item) => item.productId == productId))
          .toList();
    }

    if (repId != null) {
      sales = sales.where((sale) => sale.repId == repId).toList();
    }

    if (customerId != null) {
      sales = sales.where((sale) => sale.customerId == customerId).toList();
    }

    return sales;
  }

  Future<List<Sale>> getSalesByOutlet(String outletId) async {
    return await _salesDbService.getSalesByOutletId(outletId);
  }

  Future<double> getTotalSalesAmount(DateTime start, DateTime end) async {
    return await _salesDbService.getTotalSalesAmount(start, end);
  }

  Future<void> syncUnsynced() async {
    final unsyncedSales = await _salesDbService.getUnsyncedSales();

    for (final sale in unsyncedSales) {
      try {
        final saleData = sale.toMap();
        final itemsData = sale.items.map((item) => item.toMap()).toList();

        final response = await _supabaseClient.rpc('create_sale_with_items', params: {
          'sale_data': saleData,
          'items_data': itemsData,
        });
        
        final serverSaleId = response['id'] as String;

        await _salesDbService.markSaleAsSynced(sale.id, serverSaleId);
      } catch (e) {
        print('Failed to sync sale ${sale.id}: $e');
        continue;
      }
    }
  }

  // Calculate VAT for a given amount using fixed rate
  double calculateVAT(double amount) {
    return amount * (_vatRate / 100);
  }

  // Calculate total with VAT
  double calculateTotalWithVAT(double amount) {
    return amount + calculateVAT(amount);
  }
}
