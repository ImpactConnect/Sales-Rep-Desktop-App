class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String outlets = '/outlets';
  static const String stock = '/stock';
  static const String stockDetail = '/stock/detail';
  static const String sales = '/sales';
  static const String reports = '/reports';
}

class AppTables {
  static const String profiles = 'profiles';
  static const String outlets = 'outlets';
  static const String stock = 'products';
  static const String sales = 'sales';
  static const String saleItems = 'sale_items';
  static const String repOutlets = 'rep_outlets';
}

class AppConfig {
  static const String appName = 'Sales Rep App';
  static const int syncIntervalMinutes = 15; // Sync interval for offline data
  static const int maxOfflineDays = 7; // Maximum days to keep offline data
}

class ErrorMessages {
  static const String noInternet = 'No internet connection';
  static const String unauthorized = 'Unauthorized access';
  static const String serverError = 'Server error occurred';
  static const String invalidCredentials = 'Invalid email or password';
  static const String noUserProfile = 'User profile not found';
  static const String syncError = 'Error syncing data';
  static const String stockNotFound = 'Stock item not found';
  static const String stockUpdateFailed = 'Failed to update stock item';
  static const String invalidQuantity = 'Invalid quantity value';
  static const String stockFetchError = 'Failed to fetch stock items';
}
