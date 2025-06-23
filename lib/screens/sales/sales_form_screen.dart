import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sales_service.dart';
import '../../core/services/stock_service.dart';
import '../../models/sale_model.dart';
import '../../models/sale_item_model.dart';
import '../../models/customer_model.dart';
import '../../models/stock_model.dart';
import '../../models/user_profile.dart';

class SalesFormScreen extends StatefulWidget {
  final Function? onSaleComplete;

  const SalesFormScreen({Key? key, this.onSaleComplete}) : super(key: key);

  @override
  State<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends State<SalesFormScreen> {
  late final SalesService _salesService;
  late final StockService _stockService;
  late final AuthService _authService;

  final _formKey = GlobalKey<FormState>();
  final _customerFormKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _saleItems = [];

  String? _customerName;
  String? _customerPhone;
  double _totalAmount = 0;
  double _vat = 0;
  bool _isLoading = false;
  UserProfile? _userProfile;

  final _currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _salesService = provider.Provider.of<SalesService>(context, listen: false);
    _stockService = provider.Provider.of<StockService>(context, listen: false);
    _authService = provider.Provider.of<AuthService>(context, listen: false);
    _loadUserProfile();
    _addNewSaleItem(); // Add first item row by default
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _addNewSaleItem() {
    setState(() {
      _saleItems.add({
        'product': null,
        'quantity': 1,
        'controller': TextEditingController(text: '1'),
      });
    });
  }

  void _removeSaleItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
      _updateTotals();
    });
  }

  void _updateTotals() {
    double subtotal = 0;
    for (var item in _saleItems) {
      final product = item['product'] as StockItem?;
      final quantity = double.tryParse(item['controller'].text) ?? 0;
      if (product != null) {
        subtotal += product.costPerUnit * quantity;
      }
    }
    setState(() {
      _vat = _salesService.calculateVAT(subtotal);
      _totalAmount = subtotal + _vat;
    });
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sale'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_customerName != null) ...[
                Text(
                  'Customer: $_customerName',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_customerPhone != null) Text('Phone: $_customerPhone'),
                const SizedBox(height: 16),
              ],
              Text('Items:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...List.generate(_saleItems.length, (index) {
                final item = _saleItems[index];
                final product = item['product'] as StockItem?;
                final quantity = double.tryParse(item['controller'].text) ?? 0;
                if (product == null) return const SizedBox.shrink();
                final total = quantity * product.costPerUnit;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '${product.productName} ${quantity}x${_currencyFormat.format(product.costPerUnit)} = ${_currencyFormat.format(total)}',
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(_currencyFormat.format(_totalAmount - _vat)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('VAT:'),
                  Text(_currencyFormat.format(_vat)),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    _currencyFormat.format(_totalAmount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      if (_userProfile == null) throw Exception('User profile not found');

      String? customerId;
      if (_customerPhone != null && _customerPhone!.isNotEmpty) {
        // Check if customer exists or create new
        var customer = await _salesService.findCustomerByPhone(_customerPhone!);
        if (customer == null) {
          customer = await _salesService.createCustomer(Customer(
            fullName: _customerName,
            phone: _customerPhone,
          ));
        }
        customerId = customer.id;
      }

      final saleItems = _saleItems.map((item) {
        final product = item['product'] as StockItem;
        final quantity = double.parse(item['controller'].text);
        // Create a temporary ID that will be replaced by the actual sale ID
        const tempSaleId = 'temp';
        return SaleItem(
          productId: product.id,
          saleId: tempSaleId,
          quantity: quantity,
          unitPrice: product.costPerUnit,
        );
      }).toList();

      final sale = Sale(
        outletId: _userProfile!.outletId ?? '',
        repId: _userProfile!.id,
        customerId: customerId,
        vat: _vat,
        totalAmount: _totalAmount,
        items: saleItems,
      );

      await _salesService.addSale(sale);
      widget.onSaleComplete?.call();

      // Ask if user wants to print receipt
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Print Receipt'),
          content:
              const Text('Would you like to print a receipt for this sale?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldPrint == true) {
        await _printReceipt(sale);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded successfully')),
      );

      // Reset form
      setState(() {
        _saleItems.clear();
        _customerName = null;
        _customerPhone = null;
        _totalAmount = 0;
        _vat = 0;
        _addNewSaleItem();
        _formKey.currentState!.reset();
        if (_customerFormKey.currentState != null) {
          _customerFormKey.currentState!.reset();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording sale: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomerSection() {
    return Form(
      key: _customerFormKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Customer Name (Optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _customerName = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Customer Phone (Optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) => _customerPhone = value,
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItemRow(int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: FutureBuilder<List<StockItem>>(
                future: _stockService.getStockItems(
                    outletId: _userProfile?.outletId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Text('No products available');
                  }

                  return DropdownButtonFormField<StockItem>(
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(),
                    ),
                    value: _saleItems[index]['product'],
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.productName} (${item.quantity} ${item.unit} available)',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _saleItems[index]['product'] = value;
                        _updateTotals();
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Please select a product';
                      return null;
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _saleItems[index]['controller'],
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {
                    _saleItems[index]['quantity'] = int.tryParse(value) ?? 1;
                    _updateTotals();
                  });
                },
                validator: (value) {
                  final quantity = int.tryParse(value ?? '') ?? 0;
                  if (quantity <= 0) return 'Invalid quantity';
                  final product = _saleItems[index]['product'] as StockItem?;
                  if (product != null && quantity > product.quantity) {
                    return 'Not enough stock';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  _saleItems.length > 1 ? () => _removeSaleItem(index) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt(Sale sale) async {
    // TODO: Implement receipt printing using a thermal printer library
    // Example receipt format for 80mm paper:
    final receipt = '''\n\n
      COMPANY NAME
      ============
      
      Transaction ID: ${sale.id}
      Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt)}
      ${_customerName != null ? '\nCustomer: $_customerName' : ''}
      ${_customerPhone != null ? 'Phone: $_customerPhone' : ''}
      
      ITEMS
      -----
      ${sale.items.map((item) {
      final product = _saleItems.firstWhere(
        (saleItem) => saleItem['product'].id == item.productId,
        orElse: () => {'product': null},
      )['product'];
      return '${product?.productName ?? 'Unknown'} ${item.quantity}x${_currencyFormat.format(item.unitPrice)} = ${_currencyFormat.format(item.total)}';
    }).join('\n      ')}
      
      =====================
      Subtotal: ${_currencyFormat.format(_totalAmount - _vat)}
      VAT: ${_currencyFormat.format(_vat)}
      Total: ${_currencyFormat.format(_totalAmount)}
      
      Thank you for your business!
      =====================
    ''';

    print(receipt); // For testing purposes
  }

  Widget _buildTotalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sale Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VAT:'),
                Text(_currencyFormat.format(_vat)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _currencyFormat.format(_totalAmount),
                  style: Theme.of(context).textTheme.titleMedium,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerSection(),
            const SizedBox(height: 24),
            Text(
              'Sale Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _saleItems.length,
              (index) => Column(
                children: [
                  _buildSaleItemRow(index),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addNewSaleItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Item'),
            ),
            const SizedBox(height: 24),
            _buildTotalSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitSale,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Record Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
