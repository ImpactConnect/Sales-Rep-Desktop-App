import 'package:flutter/material.dart';
import '../../core/services/stock_service.dart';
import '../../models/stock_model.dart';
import '../../core/constants/app_constants.dart';

class StockDetailScreen extends StatefulWidget {
  final String stockId;

  const StockDetailScreen({Key? key, required this.stockId}) : super(key: key);

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final StockService _stockService = StockService();
  bool _isLoading = true;
  String? _error;
  StockItem? _stockItem;

  @override
  void initState() {
    super.initState();
    _loadStockItem();
  }

  Future<void> _loadStockItem() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final item = await _stockService.getStockItemById(widget.stockId);
      setState(() {
        _stockItem = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorMessages.stockNotFound;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Details'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStockItem,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stockItem == null) {
      return const Center(
        child: Text('Stock item not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: _getStockStatusColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    _getStockStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stockItem!.productName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Quantity',
                          '${_stockItem!.quantity} ${_stockItem!.unit}'),
                      _buildInfoRow('Cost per unit',
                          '\$${_stockItem!.costPerUnit.toStringAsFixed(2)}'),
                      _buildInfoRow('Total Value',
                          '\$${(_stockItem!.quantity * _stockItem!.costPerUnit).toStringAsFixed(2)}'),
                      _buildInfoRow(
                          'Added on',
                          _stockItem!.dateAdded
                              .toLocal()
                              .toString()
                              .split('.')[0]),
                      if (_stockItem!.lastUpdated != null)
                        _buildInfoRow(
                            'Last Updated',
                            _stockItem!.lastUpdated!
                                .toLocal()
                                .toString()
                                .split('.')[0]),
                      if (_stockItem!.description?.isNotEmpty ?? false)
                        _buildInfoRow('Description', _stockItem!.description!),
                      _buildInfoRow(
                        'Sync Status',
                        _stockItem!.synced ? 'Synced' : 'Not Synced',
                        valueColor:
                            _stockItem!.synced ? Colors.green : Colors.orange,
                        icon: _stockItem!.synced
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 16)
                            : const Icon(Icons.sync_problem,
                                color: Colors.orange, size: 16),
                      ),
                      if (!_stockItem!.synced && _stockItem!.syncError != null)
                        _buildInfoRow('Sync Error', _stockItem!.syncError!,
                            valueColor: Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStockStatusColor() {
    if (_stockItem!.quantity == 0) {
      return Colors.red;
    } else if (_stockItem!.quantity <= 10.0) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStockStatusText() {
    if (_stockItem!.quantity == 0) {
      return 'Out of Stock';
    } else if (_stockItem!.quantity <= 10.0) {
      return 'Low Stock';
    }
    return 'Well Stocked';
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, Widget? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[icon, const SizedBox(width: 4)],
                Text(
                  value,
                  style: TextStyle(color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
