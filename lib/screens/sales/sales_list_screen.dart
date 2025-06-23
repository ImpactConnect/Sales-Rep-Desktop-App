import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
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
  List<Sale> _filteredSales = [];

  // Filter states
  String? _selectedSalesRep;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedProduct;
  String _dateFilterType = 'week'; // 'yesterday', 'week', 'month', 'custom'

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

  void _applyDateFilter(String filterType) {
    setState(() {
      _dateFilterType = filterType;
      final now = DateTime.now();

      switch (filterType) {
        case 'yesterday':
          _startDate = now.subtract(const Duration(days: 1));
          _endDate = now;
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month - 1, now.day);
          _endDate = now;
          break;
        case 'custom':
          // Don't update dates for custom range
          break;
      }

      _filterSales();
    });
  }

  void _filterSales() {
    setState(() {
      _filteredSales = _sales.where((sale) {
        // Date filter
        if (_startDate != null && _endDate != null) {
          final saleDate = sale.date;
          if (saleDate.isBefore(_startDate!) || saleDate.isAfter(_endDate!)) {
            return false;
          }
        }

        // Sales rep filter
        if (_selectedSalesRep != null && _selectedSalesRep!.isNotEmpty) {
          if (sale.repId != _selectedSalesRep) {
            return false;
          }
        }

        // Product filter
        if (_selectedProduct != null && _selectedProduct!.isNotEmpty) {
          if (!sale.items.any((item) => item.productId == _selectedProduct)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sales = await _salesService.getAllSales();
      setState(() {
        _sales = sales.cast<Sale>();
        _filteredSales = sales.cast<Sale>();
        _isLoading = false;
      });

      // Apply initial filter
      _applyDateFilter(_dateFilterType);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load sales')),
      );
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

  Widget _buildSalesListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(flex: 1, child: Text('')),
          Expanded(flex: 2, child: Text('Date')),
          Expanded(flex: 3, child: Text('Customer Name')),
          Expanded(flex: 3, child: Text('Item(s)')),
          Expanded(flex: 3, child: Text('Quantity')),
          Expanded(flex: 3, child: Text('Total/Item')),
          Expanded(flex: 2, child: Text('VAT')),
          Expanded(flex: 2, child: Text('Grand Total')),
        ],
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sale Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${_formatDate(sale.date)}'),
              Text('Customer: ${sale.customerName ?? 'N/A'}'),
              const SizedBox(height: 16),
              Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...sale.items.map((item) => FutureBuilder<StockItem>(
                    future: StockService().getStockItemById(item.productId),
                    builder: (context, snapshot) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(snapshot.data?.productName ??
                                      'Loading...'),
                                  Text(
                                    '${item.quantity} × ₦${_formatNumber(item.unitPrice)}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                                '₦${_formatNumber(item.quantity * item.unitPrice)}'),
                          ],
                        ),
                      );
                    },
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('VAT:'),
                  Text('₦${_formatNumber(sale.vatAmount)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₦${_formatNumber(sale.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing receipt...')),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItemTile(Sale sale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Sale Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Date: ${_formatDate(sale.date)}'),
                    Text('Customer: ${sale.customerName ?? "N/A"}'),
                    const SizedBox(height: 16),
                    Text('Items:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...sale.items.map((item) => FutureBuilder<StockItem>(
                          future:
                              StockService().getStockItemById(item.productId),
                          builder: (context, snapshot) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(snapshot.data?.productName ??
                                            'Loading...'),
                                        Text(
                                          '${item.quantity} × ₦${_formatNumber(item.unitPrice)}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                      '₦${_formatNumber(item.quantity * item.unitPrice)}'),
                                ],
                              ),
                            );
                          },
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('VAT:'),
                        Text('₦${_formatNumber(sale.vatAmount)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₦${_formatNumber(sale.totalAmount)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement print functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printing receipt...')),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(_formatDate(sale.date)),
              ),
              Expanded(
                flex: 2,
                child: Text(sale.customerName ?? 'N/A'),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sale.items
                      .map((item) => FutureBuilder<StockItem>(
                            future:
                                StockService().getStockItemById(item.productId),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(snapshot.data!.productName);
                              }
                              return const Text('Loading...');
                            },
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sale.items
                      .map((item) => Text(item.quantity.toString()))
                      .toList(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sale.items
                      .map((item) => Text(
                          '₦${_formatNumber(item.quantity * item.unitPrice)}'))
                      .toList(),
                ),
              ),
              Expanded(
                flex: 1,
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: _authService.getCurrentLocation().then((location) =>
                        _salesService
                            .getSalesRepsByLocation(location['id'] as String)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final salesReps = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Sales Representative',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSalesRep,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Sales Reps')),
                          ...salesReps.map((rep) =>
                              DropdownMenuItem(value: rep, child: Text(rep))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSalesRep = value;
                            _filterSales();
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: _salesService.getUniqueProductNames(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final products = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Product',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProduct,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Products')),
                          ...products.map((product) => DropdownMenuItem(
                              value: product, child: Text(product))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProduct = value;
                            _filterSales();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var filter in [
                  {'label': 'Yesterday', 'value': 'yesterday'},
                  {'label': 'Last 7 Days', 'value': 'week'},
                  {'label': 'Last Month', 'value': 'month'},
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter['label']!),
                      selected: _dateFilterType == filter['value'],
                      onSelected: (selected) {
                        if (selected) {
                          _applyDateFilter(filter['value']!);
                        }
                      },
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTimeRange? dateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                    );
                    if (dateRange != null) {
                      setState(() {
                        _startDate = dateRange.start;
                        _endDate = dateRange.end;
                        _dateFilterType = 'custom';
                        _filterSales();
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? _loadSales,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildMetricsCard(),
                  _buildFilterSection(),
                  _buildSalesListHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) =>
                          _buildSaleItemTile(_filteredSales[index]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
