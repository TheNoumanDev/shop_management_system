class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main Routes
  static const String dashboard = '/';
  static const String profile = '/profile';
  
  // Inventory Routes
  static const String inventory = '/inventory';
  static const String addProduct = '/inventory/add';
  static const String editProduct = '/inventory/edit';
  static const String productDetails = '/inventory/details';
  
  // Sales Routes
  static const String sales = '/sales';
  static const String newSale = '/sales/new';
  static const String saleDetails = '/sales/details';
  static const String salesHistory = '/sales/history';
  
  // Services Routes
  static const String services = '/services';
  static const String newService = '/services/new';
  static const String serviceDetails = '/services/details';
  static const String servicesHistory = '/services/history';
  
  // Customer Routes
  static const String customers = '/customers';
  static const String addCustomer = '/customers/add';
  static const String customerDetails = '/customers/details';
  static const String udhar = '/udhar';
  
  // Supplier Routes
  static const String suppliers = '/suppliers';
  static const String addSupplier = '/suppliers/add';
  static const String supplierDetails = '/suppliers/details';
  
  // Expenses Routes
  static const String expenses = '/expenses';

  // Reports Routes
  static const String reports = '/reports';
  static const String salesReport = '/reports/sales';
  static const String inventoryReport = '/reports/inventory';
  static const String servicesReport = '/reports/services';
  
  // Settings Routes
  static const String settings = '/settings';
  static const String userManagement = '/settings/users';
  static const String categories = '/settings/categories';
}