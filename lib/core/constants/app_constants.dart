class AppConstants {
  static const String appName = 'Mashallah Mobile Center';
  static const String appVersion = '1.0.0';
  
  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String salesCollection = 'sales';
  static const String customersCollection = 'customers';
  static const String suppliersCollection = 'suppliers';
  
  // Service Collections
  static const String photocopyServiceCollection = 'photocopy_service';
  static const String photocopyExpensesCollection = 'photocopy_expenses';
  static const String photocopyIncomeCollection = 'photocopy_income';
  
  // General
  static const String categoriesCollection = 'categories';
  static const String transactionsCollection = 'transactions';
  
  // User Roles
  static const String adminRole = 'admin';
  static const String managerRole = 'manager';
  static const String employeeRole = 'employee';
  
  // Product Categories
  static const List<String> mobileAccessoryCategories = [
    'Phone Cases',
    'Screen Protectors',
    'Chargers',
    'Cables',
    'Power Banks',
    'Headphones',
    'Speakers',
    'Car Accessories',
    'Smartwatches',
    'Memory Cards',
  ];
  
  // Service Types (Fixed services - not dynamic)
  static const List<String> serviceTypes = [
    'Photocopy',
    // Add more services here when needed
  ];
  
  // Photocopy Service Constants
  static const List<String> photocopyExpenseTypes = [
    'Machine Purchase',
    'Ink Refill',
    'Paper Purchase',
    'Maintenance',
    'Electricity',
  ];
  
  static const List<int> photocopyRates = [10, 20, 30, 40, 50, 100, 150, 200, 300, 500]; // Available rates
  
  // Currency
  static const String defaultCurrency = 'PKR';
  static const String currencySymbol = '₨';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
}