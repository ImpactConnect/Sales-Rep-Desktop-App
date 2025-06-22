import 'package:flutter/material.dart';
import '../../core/services/stock_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/stock_model.dart';
import '../../models/user_profile.dart';
import '../../core/constants/app_constants.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final StockService _stockService = StockService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<StockItem> _stockItems = [];
  List<StockItem> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  UserProfile? _userProfile;
  String _selectedUnit = 'All';
  String _selectedDateFilter = 'All';
  bool _showOutOfStock = false;
  bool _showLowStock = false;
  double _lowStockThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndStock();
  }

  Future<void> _loadUserProfileAndStock() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _userProfile = await _authService.getCurrentUserProfile();
      final items =
          await _stockService.getStockItems(outletId: _userProfile?.outletId);
      setState(() {
        _stockItems = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorMessages.stockFetchError;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStockItems(String query) async {
    if (query.isEmpty) {
      _loadUserProfileAndStock();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final items = await _stockService.searchStockItems(query,
          outletId: _userProfile?.outletId);
      setState(() {
        _stockItems = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorMessages.stockFetchError;
        _isLoading = false;
      });
    }
  }

  void _viewStockDetails(StockItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 8),
            Text('Cost per unit: \$${item.costPerUnit.toStringAsFixed(2)}'),
            if (!item.synced)
              Row(
                children: [
                  const Icon(Icons.sync_problem,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  const Text(
                    'Not Synced',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
                'Total Value: \$${(item.quantity * item.costPerUnit).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
                'Added on: ${item.dateAdded.toLocal().toString().split('.')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    var filtered = List<StockItem>.from(_stockItems);

    if (_selectedUnit != 'All') {
      filtered = filtered.where((item) => item.unit == _selectedUnit).toList();
    }

    if (_selectedDateFilter != 'All') {
      final now = DateTime.now();
      switch (_selectedDateFilter) {
        case 'Today':
          filtered = filtered
              .where((item) => item.dateAdded
                  .isAfter(DateTime(now.year, now.month, now.day)))
              .toList();
          break;
        case 'Last 7 Days':
          filtered = filtered
              .where((item) =>
                  item.dateAdded.isAfter(now.subtract(const Duration(days: 7))))
              .toList();
          break;
        case 'Last 30 Days':
          filtered = filtered
              .where((item) => item.dateAdded
                  .isAfter(now.subtract(const Duration(days: 30))))
              .toList();
          break;
      }
    }

    if (_showOutOfStock) {
      filtered = filtered.where((item) => item.quantity == 0).toList();
    }

    if (_showLowStock) {
      filtered = filtered
          .where((item) =>
              item.quantity > 0 && item.quantity <= _lowStockThreshold)
          .toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  Widget _buildMetricsBar() {
    final totalProducts = _stockItems.length;
    final totalQuantity =
        _stockItems.fold<double>(0, (sum, item) => sum + item.quantity);
    final totalValue = _stockItems.fold<double>(
        0, (sum, item) => sum + (item.quantity * item.costPerUnit));
    final lowStockCount = _stockItems
        .where(
            (item) => item.quantity > 0 && item.quantity <= _lowStockThreshold)
        .length;
    final outOfStockCount =
        _stockItems.where((item) => item.quantity == 0).length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        children: [
          _buildMetricCard('Total Products', totalProducts.toString()),
          _buildMetricCard('Total Quantity', totalQuantity.toStringAsFixed(2)),
          _buildMetricCard('Total Value', '\$${totalValue.toStringAsFixed(2)}'),
          _buildMetricCard('Low Stock', lowStockCount.toString(),
              color: Colors.orange),
          _buildMetricCard('Out of Stock', outOfStockCount.toString(),
              color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, {Color? color}) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
        title: const Text('Available Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) => _searchStockItems(value),
            ),
          ),
          _buildMetricsBar(),
          Expanded(
            child: _buildStockList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfileAndStock,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stockItems.isEmpty) {
      return const Center(
        child: Text(
          'No stock items found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfileAndStock,
      child: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            elevation: 2,
            child: ListTile(
              leading: Container(
                width: 8,
                decoration: BoxDecoration(
                  color: item.quantity == 0
                      ? Colors.red
                      : item.quantity <= _lowStockThreshold
                          ? Colors.orange
                          : Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              title: Text(
                item.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Quantity: ${item.quantity} ${item.unit}'),
                  Text(
                    'Cost per unit: \$${item.costPerUnit.toStringAsFixed(2)}',
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _viewStockDetails(item),
              ),
              onTap: () => _viewStockDetails(item),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Stock'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unit'),
                DropdownButton<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  items: ['All', ...Set.from(_stockItems.map((e) => e.unit))]
                      .map((unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Date Added'),
                DropdownButton<String>(
                  value: _selectedDateFilter,
                  isExpanded: true,
                  items: ['All', 'Today', 'Last 7 Days', 'Last 30 Days']
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _showOutOfStock,
                      onChanged: (value) {
                        setState(() {
                          _showOutOfStock = value!;
                          if (value) {
                            _showLowStock = false;
                          }
                        });
                      },
                    ),
                    const Text('Show Out of Stock Only'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _showLowStock,
                      onChanged: (value) {
                        setState(() {
                          _showLowStock = value!;
                          if (value) {
                            _showOutOfStock = false;
                          }
                        });
                      },
                    ),
                    const Text('Show Low Stock Only'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
