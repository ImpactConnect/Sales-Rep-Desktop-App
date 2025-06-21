import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/stock_model.dart';
import '../constants/app_constants.dart';

class StockService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<StockItem>? _cachedStockItems;

  Future<void> loadStockItems({String? outletId}) async {
    try {
      _cachedStockItems = await getStockItems(outletId: outletId);
    } catch (e) {
      throw Exception('Failed to load stock items: ${e.toString()}');
    }
  }

  Future<List<StockItem>> getStockItems({String? outletId}) async {
    try {
      var query = _supabaseClient.from(AppTables.stock).select();

      if (outletId != null) {
        query = query.eq('outlet_id', outletId);
      }

      final response = await query.order('date_added', ascending: false);
      return (response as List)
          .map((item) => StockItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock items: ${e.toString()}');
    }
  }

  Future<StockItem> getStockItemById(String id) async {
    try {
      final response = await _supabaseClient
          .from(AppTables.stock)
          .select()
          .eq('id', id)
          .single();
      return StockItem.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch stock item: ${e.toString()}');
    }
  }

  Future<List<StockItem>> searchStockItems(String query,
      {String? outletId}) async {
    try {
      var supabaseQuery = _supabaseClient
          .from(AppTables.stock)
          .select()
          .ilike('product_name', '%$query%');

      if (outletId != null) {
        supabaseQuery = supabaseQuery.eq('outlet_id', outletId);
      }

      final response =
          await supabaseQuery.order('date_added', ascending: false);
      return (response as List)
          .map((item) => StockItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search stock items: ${e.toString()}');
    }
  }

  Future<void> updateStockQuantity(
    String id,
    double newQuantity,
  ) async {
    try {
      await _supabaseClient
          .from(AppTables.stock)
          .update({'quantity': newQuantity}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update stock quantity: ${e.toString()}');
    }
  }
}
