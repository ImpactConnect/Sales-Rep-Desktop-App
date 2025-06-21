import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../../models/sale_model.dart';
import '../../models/sale_item_model.dart';
import 'database_service.dart';

class SalesDbService {
  final DatabaseService _databaseService;

  SalesDbService(this._databaseService);

  Future<void> insertSale(Sale sale) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      // Insert the sale
      await txn.insert(
        AppTables.sales,
        {
          'id': sale.id,
          'outlet_id': sale.outletId,
          'rep_id': sale.repId,
          'customer_id': sale.customerId,
          'vat': sale.vat,
          'total_amount': sale.totalAmount,
          'created_at': DateTime.now().toIso8601String(),
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert all sale items
      for (var item in sale.items) {
        await txn.insert(
          AppTables.saleItems,
          {
            'id': item.id,
            'sale_id': sale.id,
            'product_id': item.productId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query(AppTables.sales);
    
    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        AppTables.saleItems,
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      final items = itemMaps.map((item) => SaleItem.fromMap(item)).toList();
      sales.add(Sale.fromMap({...saleMap, 'items': items}));
    }
    return sales;
  }

  Future<List<Sale>> getUnsyncedSales() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      AppTables.sales,
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        AppTables.saleItems,
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      final items = itemMaps.map((item) => SaleItem.fromMap(item)).toList();
      sales.add(Sale.fromMap({...saleMap, 'items': items}));
    }
    return sales;
  }

  Future<void> markSaleAsSynced(String saleId) async {
    final db = await _databaseService.database;
    await db.update(
      AppTables.sales,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      AppTables.sales,
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    
    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        AppTables.saleItems,
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      final items = itemMaps.map((item) => SaleItem.fromMap(item)).toList();
      sales.add(Sale.fromMap({...saleMap, 'items': items}));
    }
    return sales;
  }

  Future<List<Sale>> getSalesByProductId(String productId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleItemMaps = await db.query(
      AppTables.saleItems,
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    
    final saleIds = saleItemMaps.map((item) => item['sale_id'] as String).toSet();
    
    List<Sale> sales = [];
    for (var saleId in saleIds) {
      final List<Map<String, dynamic>> saleMaps = await db.query(
        AppTables.sales,
        where: 'id = ?',
        whereArgs: [saleId],
      );
      
      if (saleMaps.isNotEmpty) {
        final saleMap = saleMaps.first;
        final List<Map<String, dynamic>> itemMaps = await db.query(
          AppTables.saleItems,
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );
        
        final items = itemMaps.map((item) => SaleItem.fromMap(item)).toList();
        sales.add(Sale.fromMap({...saleMap, 'items': items}));
      }
    }
    return sales;
  }

  Future<List<Sale>> getSalesByOutletId(String outletId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      AppTables.sales,
      where: 'outlet_id = ?',
      whereArgs: [outletId],
    );
    
    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        AppTables.saleItems,
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      final items = itemMaps.map((item) => SaleItem.fromMap(item)).toList();
      sales.add(Sale.fromMap({...saleMap, 'items': items}));
    }
    return sales;
  }

  Future<double> getTotalSalesAmount(DateTime start, DateTime end) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT SUM(total_amount) as total
      FROM ${AppTables.sales}
      WHERE created_at BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}