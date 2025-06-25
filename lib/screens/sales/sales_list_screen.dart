import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/sale_model.dart';
import '../../../models/sale_item_model.dart';
import '../../../models/stock_model.dart';
import '../../../models/user_profile.dart';
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
  final _supabase = Supabase.instance.client;
  late SalesService _salesService;
  late StockService _stockService;
  late AuthService _authService;

  bool _isLoading = true;
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  UserProfile? _userProfile;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedProduct;
  String? _selectedRepId;

  final List<String> _filterOptions = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month'
  ];
  String? _selectedFilter;

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
    _salesService = provider.Provider.of<SalesService>(context, listen: false);
    _stockService = provider.Provider.of<StockService>(context, listen: false);
    _authService = provider.Provider.of<AuthService>(context, listen: false);
    _loadUserProfileAndSales();
  }

  Future<void> _loadUserProfileAndSales() async {
    setState(() => _isLoading = true);
    try {
      _userProfile = await _authService.getCurrentUserProfile();
      if (_userProfile == null) {
        throw Exception('User profile not found');
      }

      final sales = await _salesService.getAllSales();
      setState(() {
        _sales = sales.cast<Sale>();
        _filteredSales = _sales; // Initialize filtered sales with all sales
        _applyFilters(); // Apply any existing filters
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMetricsCard() {
    final int salesCount = _filteredSales.length;
    final int totalCustomers =
        _filteredSales.where((s) => s.customerName?.isNotEmpty ?? false).length;
    final int totalItemsSold =
        _filteredSales.fold<int>(0, (sum, sale) => sum + (sale as Sale).totalQuantity);
    final double totalRevenue =
        _filteredSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);

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
                  const SizedBox(height: 0),
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
                              child: Text(_formatNumber(
                                  item.quantity * item.unitPrice)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(_formatNumber(sale.vatAmount)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatNumber(sale.totalAmount),
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
                      Text(
                          '${item.quantity} × ${_currencyFormat.format(item.unitPrice)}'),
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

  void _applyFilters() {
    List<Sale> filtered = List.from(_sales);

    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((sale) {
        final saleDate =
            DateTime(sale.date.year, sale.date.month, sale.date.day);
        final startDate =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final endDate =
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return (saleDate.isAtSameMomentAs(startDate) ||
                saleDate.isAfter(startDate)) &&
            (saleDate.isAtSameMomentAs(endDate) || saleDate.isBefore(endDate));
      }).toList();
    }

    if (_selectedProduct != null) {
      filtered = filtered
          .where((sale) =>
              sale.items.any((item) => item.productId == _selectedProduct))
          .toList();
    }

    if (_selectedRepId != null) {
      filtered =
          filtered.where((sale) => sale.repId == _selectedRepId).toList();
    }

    setState(() => _filteredSales = filtered);
  }

  void _applyDateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      switch (filter) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(
              yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case 'Last 7 Days':
          _startDate = DateTime(now.year, now.month, now.day - 7);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
      }
      _applyFilters();
    });
  }

  Widget _buildFilterSection() {
    if (_userProfile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 8,
              children: _filterOptions
                  .map((filter) => FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          if (selected) {
                            _applyDateFilter(filter);
                          } else {
                            setState(() {
                              _selectedFilter = null;
                              _startDate = null;
                              _endDate = null;
                              _applyFilters();
                            });
                          }
                        },
                        selectedColor: const Color(0xFF4A90E2).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF4A90E2),
                      ))
                  .toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTimeRange? dateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                currentDate: DateTime.now(),
                saveText: 'Apply',
              );
              if (dateRange != null) {
                setState(() {
                  _selectedFilter = null;
                  _startDate = dateRange.start;
                  _endDate = dateRange.end;
                  _applyFilters();
                });
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear all filters',
            onPressed: () {
              setState(() {
                _selectedFilter = null;
                _startDate = null;
                _endDate = null;
                _selectedProduct = null;
                _selectedRepId = null;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: FutureBuilder<List<StockItem>>(
              future:
                  _stockService.getStockItems(outletId: _userProfile?.outletId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final products = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedProduct,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Filter by Product',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Products'),
                    ),
                    ...products.map((product) => DropdownMenuItem<String>(
                          value: product.id,
                          child: Text(product.productName),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProduct = value;
                      _applyFilters();
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: FutureBuilder<List<UserProfile>>(
              future: _supabase
                  .from('profiles')
                  .select()
                  .eq('outlet_id', _userProfile?.outletId)
                  .then(
                (response) {
                  if (response == null) return <UserProfile>[];
                  final List<dynamic> data = response;
                  return data
                      .where((json) => json != null)
                      .map((json) {
                        try {
                          final Map<String, dynamic> profileData = {
                            ...json as Map<String, dynamic>,
                            'email': json['email'] ?? '',
                          };
                          return UserProfile.fromJson(profileData);
                        } catch (e) {
                          print('Error parsing user profile: $e');
                          return null;
                        }
                      })
                      .whereType<UserProfile>()
                      .toList();
                },
              ).catchError((error) {
                print('Error fetching sales reps: $error');
                return <UserProfile>[];
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DropdownButtonFormField<String>(
                    value: null,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Loading Sales Reps...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                if (snapshot.hasError) {
                  return DropdownButtonFormField<String>(
                    value: null,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Error Loading Sales Reps',
                      errorText: 'Please try refreshing the page',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return DropdownButtonFormField<String>(
                    value: null,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'No Sales Reps Available',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: const [],
                    onChanged: null,
                  );
                }

                final reps = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedRepId,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Filter by Sales Rep',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Sales Reps'),
                    ),
                    ...reps.map((rep) => DropdownMenuItem<String>(
                          value: rep.id,
                          child: Text(rep.fullName ?? rep.email),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRepId = value;
                      _applyFilters();
                    });
                  },
                );
              },
            ),
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
            onPressed: _loadUserProfileAndSales,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricsCard(),
          _buildFilterSection(),
          _buildSalesListHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadUserProfileAndSales();
                if (widget.onRefresh != null) await widget.onRefresh!();
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) =>
                          _buildSaleItemTile(_filteredSales[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
