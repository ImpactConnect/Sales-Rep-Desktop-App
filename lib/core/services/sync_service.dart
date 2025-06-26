import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/sales_db_service.dart';
import '../../models/sale_model.dart';
import '../../models/sale_item_model.dart';
import '../constants/app_constants.dart';

class SyncService {
  final SalesDbService _salesDbService;
  final SupabaseClient _supabaseClient;

  SyncService(this._salesDbService) : _supabaseClient = Supabase.instance.client;

  Future<List<Sale>> getUnsyncedSales() async {
    try {
      return await _salesDbService.getUnsyncedSales();
    } catch (e) {
      throw Exception('Failed to get unsynced sales: ${e.toString()}');
    }
  }

  Future<void> syncSale(Sale sale) async {
    try {
      // First, ensure customer exists in Supabase
      String? customerId;
      if (sale.customerName != null) {
        final customerResponse = await _supabaseClient
            .from('customers')
            .insert({
              'full_name': sale.customerName,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        customerId = customerResponse['id'];
      }

      // Insert the sale record
      final saleResponse = await _supabaseClient
          .from('sales')
          .insert({
            'outlet_id': sale.outletId,
            'rep_id': sale.repId,
            'customer_id': customerId,
            'vat': sale.vat,
            'total_amount': sale.totalAmount,
            'created_at': sale.createdAt.toIso8601String(),
          })
          .select()
          .single();

      final serverSaleId = saleResponse['id'];

      // Insert all sale items
      for (var item in sale.items) {
        await _supabaseClient.from('sale_items').insert({
          'sale_id': serverSaleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'created_at': item.createdAt.toIso8601String(),
        });
      }

      // Update local sale record with sync status
      await _salesDbService.markSaleAsSynced(sale.id, serverSaleId);
    } catch (e) {
      throw Exception('Failed to sync sale ${sale.id}: ${e.toString()}');
    }
  }

  Future<SyncResult> syncAllPendingSales() async {
    try {
      final unsyncedSales = await getUnsyncedSales();
      int successCount = 0;
      List<String> failedIds = [];

      for (final sale in unsyncedSales) {
        try {
          await syncSale(sale);
          successCount++;
        } catch (e) {
          failedIds.add(sale.id);
          print('Failed to sync sale ${sale.id}: $e');
        }
      }

      return SyncResult(
        totalAttempted: unsyncedSales.length,
        successCount: successCount,
        failedIds: failedIds,
      );
    } catch (e) {
      throw Exception('Failed to sync pending sales: ${e.toString()}');
    }
  }
}

class SyncResult {
  final int totalAttempted;
  final int successCount;
  final List<String> failedIds;

  SyncResult({
    required this.totalAttempted,
    required this.successCount,
    required this.failedIds,
  });

  int get failureCount => failedIds.length;
  bool get hasFailures => failedIds.isNotEmpty;
  bool get isFullSuccess => totalAttempted == successCount;
}