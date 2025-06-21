import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Use provider.Provider instead of Provider in the widget tree

import 'core/services/auth_service.dart';
import 'core/services/sales_service.dart';
import 'core/services/stock_service.dart';
import 'core/database/database_service.dart';
import 'core/services/outlet_service.dart';
import 'core/database/sales_db_service.dart';

// Import screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/stock/stock_screen.dart';
import 'screens/stock/stock_detail_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for Windows
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final authService = AuthService();
    final stockService = StockService();
    final salesDbService = SalesDbService(databaseService);
    final outletService = OutletService();
    final supabaseClient = Supabase.instance.client;
    final salesService = SalesService(salesDbService, supabaseClient, stockService);

    return provider.MultiProvider(
      providers: [
        provider.Provider<DatabaseService>(create: (_) => databaseService),
        provider.Provider<AuthService>(create: (_) => authService),
        provider.Provider<StockService>(create: (_) => stockService),
        provider.Provider<SalesService>(create: (_) => salesService),
        provider.Provider<OutletService>(create: (_) => outletService),
      ],
      child: MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.dashboard: (context) => DashboardScreen(),
        AppRoutes.stock: (context) => const StockScreen(),
        AppRoutes.sales: (context) => const SalesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.stockDetail) {
          final String stockId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => StockDetailScreen(stockId: stockId),
          );
        }
        return null;
      },
    ),
    );
  }
}
