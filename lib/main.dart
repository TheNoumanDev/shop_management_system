import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/firebase_service.dart';
import 'core/utils/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/services/providers/photocopy_provider.dart';
import 'features/sales/providers/sales_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/expenses/providers/expense_provider.dart';
import 'features/categories/providers/category_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PhotocopyProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SalesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}