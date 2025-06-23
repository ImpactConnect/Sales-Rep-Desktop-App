import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../../core/services/sales_service.dart';
import '../../core/services/stock_service.dart';
import '../../core/services/auth_service.dart';
import 'sales_form_screen.dart';
import 'sales_list_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SalesListScreen(onRefresh: _refreshData),
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
