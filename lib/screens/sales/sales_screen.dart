import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../core/services/sales_service.dart';
import '../../core/services/stock_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../models/sale_model.dart';
import '../../models/sale_item_model.dart';
import 'sales_form_screen.dart';
import 'sales_list_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _csvDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  late final SalesService _salesService;
  late final StockService _stockService;
  late final AuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _salesService = provider.Provider.of<SalesService>(context, listen: false);
    _stockService = provider.Provider.of<StockService>(context, listen: false);
    _authService = provider.Provider.of<AuthService>(context, listen: false);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile.outletId == null) {
        throw Exception('User is not assigned to any outlet');
      }
      await _stockService.loadStockItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _initializeData();
  }

  Future<void> _handleExport(String format) async {
    try {
      final salesListState = SalesListScreen.screenKey.currentState;
      if (salesListState == null) {
        throw Exception('Could not access sales list state');
      }
      final filteredSales = salesListState.filteredSales;

      if (filteredSales.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sales data to export')),
        );
        return;
      }

      if (format == 'pdf') {
        await _exportToPdf(filteredSales);
      } else if (format == 'csv') {
        await _exportToCsv(filteredSales);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  Future<void> _exportToPdf(List<Sale> sales) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
              level: 0,
              child:
                  pw.Text('Sales Report', style: pw.TextStyle(fontSize: 20))),
          pw.Table.fromTextArray(
            context: context,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 25,
            cellHeight: 40,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headers: ['Date', 'Customer', 'Items', 'VAT', 'Total'],
            data: sales
                .map((sale) => [
                      _dateFormat.format(sale.date),
                      sale.customerName ?? 'N/A',
                      sale.totalQuantity.toString(),
                      _currencyFormat.format(sale.vatAmount),
                      _currencyFormat.format(sale.totalAmount),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await PdfService().printDocument(
      onLayout: (format) async => pdf.save(),
      filename: 'Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _exportToCsv(List<Sale> sales) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv');

    final csvData = [
      ['Date', 'Customer', 'Product', 'Quantity', 'Unit Price', 'VAT', 'Total'],
      ...sales.expand((sale) => sale.items.map((item) => [
            _csvDateFormat.format(sale.date),
            sale.customerName ?? 'N/A',
            item.productName ?? 'Unknown Product',
            item.quantity.toString(),
            _currencyFormat.format(item.unitPrice),
            _currencyFormat.format(sale.vatAmount),
            _currencyFormat.format(item.total),
          ])),
    ];

    final csvContent = csvData.map((row) => row.join(',')).join('\n');
    await file.writeAsString(csvContent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Sales History',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1F1F1F)),
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF1F1F1F)),
            onSelected: _handleExport,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SalesListScreen(
              key: SalesListScreen.screenKey, onRefresh: _refreshData),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: SalesFormScreen(
                    onSaleComplete: () {
                      Navigator.pop(context);
                      _refreshData();
                    },
                  ),
                ),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF4A90E2),
        child: const Icon(Icons.add),
      ),
    );
  }
}
