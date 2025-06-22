import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/sale_model.dart';
import '../../../models/sale_item_model.dart';
import '../../../models/stock_model.dart';
import '../../core/services/sales_service.dart';
import '../../core/services/stock_service.dart';
import '../../core/services/auth_service.dart';

class SalesListScreen extends StatefulWidget {
  static const String routeName = '/sales';

  final Future<void> Function()? onRefresh;

  const SalesListScreen({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  late SalesService _salesService;
  late StockService _stockService;
  late AuthService _authService;

  bool _isLoading = true;
  List<Sale> _sales = [];

  final _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
  final _dateFormat = DateFormat('MMM dd, yyyy – hh:mm a');

  String _formatNumber(num value) {
    return _currencyFormat.format(value);
  }

  String _formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  @override
  void initState() {
    super.initState();
    _salesService = Provider.of<SalesService>(context, listen: false);
    _stockService = Provider.of<StockService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _salesService.getAllSales();
      setState(() => _sales = sales.cast<Sale>());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMetricsCard() {
    final int salesCount = _sales.length;
    final int totalCustomers =
        _sales.where((s) => s.customerName?.isNotEmpty ?? false).length;
    final int totalItemsSold =
        _sales.fold<int>(0, (sum, sale) => sum + (sale as Sale).totalQuantity);
    final double totalRevenue =
        _sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('Sales', salesCount.toString()),
          _buildMetric('Customers', totalCustomers.toString()),
          _buildMetric('Items', totalItemsSold.toString()),
          _buildMetric('Revenue', _currencyFormat.format(totalRevenue)),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSaleDetailsDialog(Sale sale) {
    return AlertDialog(
      title: const Text('Sale Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Customer: ${sale.customerName ?? "N/A"}'),
          Text('Date: ${_formatDate(sale.date)}'),
          const Divider(),
          ...sale.items.map((item) => ListTile(
                title: Text(item.productName ?? 'Unknown Product'),
                subtitle: Text(
                    '${item.quantity} × ${_currencyFormat.format(item.unitPrice)}'),
                trailing: Text(_currencyFormat.format(item.total)),
              )),
          const Divider(),
          Text('VAT: ${_currencyFormat.format(sale.vat)}'),
          Text('Total: ${_currencyFormat.format(sale.totalAmount)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Add print logic
          },
          child: const Text('Print Receipt'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => _buildSaleDetailsDialog(sale),
    );
  }

  Widget _buildSalesListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Row(
        children: const [
          Expanded(
              flex: 2,
              child:
                  Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Customer',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Product',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child:
                  Text('VAT', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child:
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSaleItemTile(Sale sale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(_formatDate(sale.date)),
            ),
            Expanded(
              flex: 3,
              child: Text(sale.customerName ?? 'N/A'),
            ),
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('Item',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Qty',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Total',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...sale.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: FutureBuilder<StockItem>(
                                future: StockService()
                                    .getStockItemById(item.productId),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(snapshot.data!.productName);
                                  }
                                  return const Text('Loading...');
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(item.quantity.toString()),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                  '₦${_formatNumber(item.quantity * item.unitPrice)}'),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('₦${_formatNumber(sale.vatAmount)}'),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₦${_formatNumber(sale.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        onTap: () => _showSaleDetails(sale),
        title: Text(sale.customerName ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(sale.date),
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(item.productName ?? 'Unknown Product')),
                      Text('${item.quantity} × ₦${item.unitPrice}'),
                      Text(_currencyFormat.format(item.total)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currencyFormat.format(sale.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            const Text("Total"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last Push: ${_dateFormat.format(DateTime.now())}'),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('PDF'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('CSV'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoCard('Pending Push', '0'),
              const SizedBox(width: 16),
              _buildInfoCard('Total Pushed', '${_sales.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search sales...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoSection(),
          _buildFilterSection(),
          _buildMetricsCard(),
          _buildSalesListHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadSales();
                if (widget.onRefresh != null) await widget.onRefresh!();
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _sales.length,
                      itemBuilder: (context, index) =>
                          _buildSaleItemTile(_sales[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
