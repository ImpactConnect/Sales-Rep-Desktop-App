import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/sales_service.dart';
import '../../core/services/stock_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/sale_model.dart';
import '../../models/stock_model.dart';
import '../../models/user_profile.dart';
import '../../models/customer_model.dart';

class SalesListScreen extends StatefulWidget {
  final Function? onRefresh;

  const SalesListScreen({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  late final SalesService _salesService;
  late final StockService _stockService;
  late final AuthService _authService;
  late String _currentOutletId;
  final _supabaseClient = Supabase.instance.client;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  StockItem? _selectedProduct;
  String? _selectedCustomerId;
  bool _isLoading = false;
  bool _isSyncing = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');

  @override
  void initState() {
    super.initState();
    _salesService = provider_pkg.Provider.of<SalesService>(context, listen: false);
    _stockService = provider_pkg.Provider.of<StockService>(context, listen: false);
    _authService = provider_pkg.Provider.of<AuthService>(context, listen: false);
    _initializeOutletId();
  }

  Future<void> _initializeOutletId() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile.outletId == null) {
        throw Exception('User is not assigned to any outlet');
      }
      setState(() {
        _currentOutletId = userProfile.outletId!;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _syncSales() async {
    setState(() => _isSyncing = true);
    try {
      await _salesService.syncUnsynced();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales synced successfully')),
      );
      widget.onRefresh?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing sales: $e')),
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String? _selectedDatePreset;
  String? _selectedSalesRep;

  List<String> _datePresets = ['Yesterday', 'Last 7 Days', 'Last 30 Days', 'Custom'];

  void _applyDatePreset(String? preset) {
    if (preset == null) return;
    
    setState(() {
      _selectedDatePreset = preset;
      switch (preset) {
        case 'Yesterday':
          _startDate = DateTime.now().subtract(const Duration(days: 1));
          _endDate = DateTime.now();
          break;
        case 'Last 7 Days':
          _startDate = DateTime.now().subtract(const Duration(days: 7));
          _endDate = DateTime.now();
          break;
        case 'Last 30 Days':
          _startDate = DateTime.now().subtract(const Duration(days: 30));
          _endDate = DateTime.now();
          break;
        case 'Custom':
          _selectDateRange();
          break;
      }
    });
  }

  Widget _buildMetricsCard(List<Sale> sales) {
    double totalSales = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    int totalItems = sales.fold(0, (sum, sale) => sum + sale.items.length);
    int totalSalesCount = sales.length;
    Set<String?> uniqueCustomers = sales.map((sale) => sale.customerId).toSet();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              'Total Items Sold',
              totalItems,
              icon: Icons.inventory,
              isAmount: false,
              backgroundColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              'Sales Count',
              totalSalesCount,
              icon: Icons.receipt_long,
              isAmount: false,
              backgroundColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              'Total Customers',
              uniqueCustomers.length,
              icon: Icons.people,
              isAmount: false,
              backgroundColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              'Total Revenue',
              totalSales,
              icon: Icons.money,
              backgroundColor: const Color(0xFFF5F5F5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, dynamic value, {bool isAmount = true, IconData? icon, Color? backgroundColor}) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 24, color: const Color(0xFF4A90E2)),
            const SizedBox(height: 8),
            Text(
              isAmount ? _currencyFormat.format(value) : value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sale Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: Color(0xFF4A90E2)),
                              onPressed: () {
                                // TODO: Implement print functionality
                              },
                              tooltip: 'Print Receipt',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF666666)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFEEEEEE)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${DateFormat('MMM d, y HH:mm').format(sale.createdAt)}',
                            style: const TextStyle(color: Color(0xFF666666)),
                          ),
                          if (sale.customerId != null)
                            FutureBuilder<Map<String, dynamic>>(
                              future: _supabaseClient
                                  .from('customers')
                                  .select()
                                  .eq('id', sale.customerId)
                                  .single()
                                  .then((response) => response as Map<String, dynamic>),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final customer = Customer.fromMap(snapshot.data!);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        'Customer: ${customer.fullName ?? 'N/A'}',
                                        style: const TextStyle(color: Color(0xFF666666)),
                                      ),
                                      Text(
                                        'Phone: ${customer.phone ?? 'N/A'}',
                                        style: const TextStyle(color: Color(0xFF666666)),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Items',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: sale.items.length,
                        itemBuilder: (context, index) {
                          final item = sale.items[index];
                          return FutureBuilder<StockItem>(
                            future: _stockService.getStockItemById(item.productId),
                            builder: (context, snapshot) {
                              final product = snapshot.data;
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                                child: ListTile(
                                  title: Text(
                                    product?.productName ?? 'Loading...',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Quantity: ${item.quantity} × ${_currencyFormat.format(item.unitPrice)}',
                                    style: const TextStyle(color: Color(0xFF666666)),
                                  ),
                                  trailing: Text(
                                    _currencyFormat.format(item.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A90E2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'VAT:',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(sale.vat),
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              Text(
                                _currencyFormat.format(sale.totalAmount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Date Range',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _selectedDatePreset,
                        items: _datePresets.map((preset) => DropdownMenuItem(
                          value: preset,
                          child: Text(preset),
                        )).toList(),
                        onChanged: _applyDatePreset,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _selectDateRange().then((_) {
                        setState(() {
                          _selectedDatePreset = 'Custom';
                        });
                      }),
                      icon: const Icon(Icons.calendar_today),
                      tooltip: 'Select Date Range',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSyncing ? null : _syncSales,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<StockItem>>(
                        future: _stockService.getStockItems(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          return DropdownButtonFormField<StockItem?>(
                            decoration: const InputDecoration(
                              labelText: 'Filter by Product',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: _selectedProduct,
                            items: [
                              const DropdownMenuItem<StockItem?>(
                                value: null,
                                child: Text('All Products'),
                              ),
                              ...snapshot.data!.map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.productName),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedProduct = value);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<List<UserProfile>>(
                        future: _authService.getCurrentUserProfile().then((profile) =>
                          _supabaseClient.from('profiles')
                            .select()
                            .eq('outlet_id', profile.outletId)
                            .then((response) => (response as List)
                              .map((data) => UserProfile.fromJson(data))
                              .toList())
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          return DropdownButtonFormField<String?>(
                            decoration: const InputDecoration(
                              labelText: 'Filter by Sales Rep',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: _selectedSalesRep,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Reps'),
                              ),
                              ...snapshot.data!.map((user) => DropdownMenuItem(
                                value: user.id,
                                child: Text(user.fullName ?? 'Unknown'),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSalesRep = value);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Sale>>(
              future: _salesService.getFilteredSales(
                startDate: _startDate,
                endDate: _endDate,
                productId: _selectedProduct?.id,
                repId: _selectedSalesRep,
                customerId: _selectedCustomerId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sales = snapshot.data ?? [];

                if (sales.isEmpty) {
                  return const Center(child: Text('No sales found'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMetricsCard(sales),
                    const SizedBox(height: 16),
                    ...sales.map((sale) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _showSaleDetails(sale),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM d, y HH:mm').format(sale.createdAt),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (!sale.synced)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5A623),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Not Synced',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${sale.items.length} items',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                      if (sale.customerId != null)
                                        FutureBuilder<Map<String, dynamic>>(
                                          future: _supabaseClient
                                              .from('customers')
                                              .select()
                                              .eq('id', sale.customerId)
                                              .single()
                                              .then((response) => response as Map<String, dynamic>),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              final customer = Customer.fromMap(snapshot.data!);
                                              return Text(
                                                customer.fullName ?? 'N/A',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _currencyFormat.format(sale.totalAmount),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'VAT: ${_currencyFormat.format(sale.vat)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to view details',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/sales/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}