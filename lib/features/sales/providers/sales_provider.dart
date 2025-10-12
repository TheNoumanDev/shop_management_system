import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../models/sale_model.dart';

class SalesProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get today's sales
  List<Sale> get todaysSales {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _sales.where((sale) =>
      sale.saleDate.isAfter(startOfDay) &&
      sale.saleDate.isBefore(endOfDay)
    ).toList();
  }

  // Get current month's sales (1st to last day of current month)
  List<Sale> get currentMonthSales {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));

    return _sales.where((sale) =>
      sale.saleDate.isAfter(startOfMonth.subtract(const Duration(microseconds: 1))) &&
      sale.saleDate.isBefore(endOfMonth.add(const Duration(microseconds: 1)))
    ).toList();
  }
  
  // Get total sales amount (all time)
  double get totalSalesAmount {
    return _sales.fold<double>(0, (total, sale) => total + sale.totalAmount);
  }

  // Get total profit (all time)
  double get totalProfit {
    return _sales.fold<double>(0, (total, sale) => total + sale.profit);
  }

  // Get current month sales amount
  double get currentMonthSalesAmount {
    return currentMonthSales.fold<double>(0, (total, sale) => total + sale.totalAmount);
  }

  // Get current month profit
  double get currentMonthProfit {
    return currentMonthSales.fold<double>(0, (total, sale) => total + sale.profit);
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Load sales for current month only (default)
  Future<void> loadSales() async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    await loadSalesForDateRange(currentMonth, nextMonth.subtract(const Duration(days: 1)));
  }

  // Load sales for specific date range
  Future<void> loadSalesForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _setError(null);

      List<Sale> allSales = [];
      final start = DateTime(startDate.year, startDate.month, 1);
      final end = DateTime(endDate.year, endDate.month + 1, 1);

      // Load all months in the date range
      for (DateTime date = start; date.isBefore(end); date = DateTime(date.year, date.month + 1, 1)) {
        final monthYear = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        try {
          final querySnapshot = await _firebaseService.firestore
              .collection('sales')
              .doc(monthYear)
              .collection('transactions')
              .orderBy('saleDate', descending: true)
              .get();

          final monthSales = querySnapshot.docs
              .map((doc) => Sale.fromFirestore(doc))
              .where((sale) =>
                sale.saleDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                sale.saleDate.isBefore(endDate.add(const Duration(days: 1)))
              )
              .toList();

          allSales.addAll(monthSales);
        } catch (e) {
          // If month doesn't exist, continue to next month
          continue;
        }
      }

      _sales = allSales;

    } catch (e) {
      _setError('Failed to load sales: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add new sale (using month/year organization)
  Future<bool> addSale(Sale sale) async {
    try {
      _setLoading(true);
      _setError(null);

      final saleDate = sale.saleDate;
      final monthYear = '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}';

      // Add sale to month/year collection
      await _firebaseService.firestore
          .collection('sales')
          .doc(monthYear)
          .collection('transactions')
          .add(sale.toFirestore());

      // Update monthly metadata
      await _updateMonthlyMetadata(monthYear, sale);

      await loadSales(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to add sale: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update monthly metadata for analytics
  Future<void> _updateMonthlyMetadata(String monthYear, Sale sale) async {
    try {
      final monthDoc = _firebaseService.firestore
          .collection('sales')
          .doc(monthYear);

      await _firebaseService.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(monthDoc);

        if (snapshot.exists) {
          // Update existing metadata
          final data = snapshot.data() as Map<String, dynamic>;
          transaction.update(monthDoc, {
            'totalSales': (data['totalSales'] ?? 0.0) + sale.totalAmount,
            'totalProfit': (data['totalProfit'] ?? 0.0) + sale.profit,
            'salesCount': (data['salesCount'] ?? 0) + 1,
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          // Create new metadata
          transaction.set(monthDoc, {
            'month': monthYear,
            'totalSales': sale.totalAmount,
            'totalProfit': sale.profit,
            'salesCount': 1,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } catch (e) {
      // Don't throw error for metadata updates
      debugPrint('Failed to update monthly metadata: $e');
    }
  }
  
  // Update sale
  Future<bool> updateSale(Sale sale) async {
    try {
      _setLoading(true);
      _setError(null);

      final saleDate = sale.saleDate;
      final monthYear = '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}';

      // Update sale in month/year collection
      await _firebaseService.firestore
          .collection('sales')
          .doc(monthYear)
          .collection('transactions')
          .doc(sale.id)
          .update(sale.toFirestore());

      await loadSales(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to update sale: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete sale
  Future<bool> deleteSale(String saleId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Find the sale in the current sales list to get its date
      final sale = _sales.firstWhere((s) => s.id == saleId);
      final saleDate = sale.saleDate;
      final monthYear = '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}';

      // Delete from the correct month/year collection
      await _firebaseService.firestore
          .collection('sales')
          .doc(monthYear)
          .collection('transactions')
          .doc(saleId)
          .delete();

      await loadSales(); // Refresh the list
      return true;
    } catch (e) {
      _setError('Failed to delete sale: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get sales by date range
  List<Sale> getSalesByDateRange(DateTime start, DateTime end) {
    return _sales.where((sale) => 
      sale.saleDate.isAfter(start.subtract(const Duration(days: 1))) &&
      sale.saleDate.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }
  
  // Add dummy data for testing
  Future<void> addDummyData() async {
    final dummySales = [
      Sale(
        id: '',
        productId: 'dummy1',
        productName: 'iPhone 14 Case',
        quantity: 2,
        purchasePrice: 150,
        sellingPrice: 200,
        totalAmount: 400,
        profit: 100,
        customerName: 'Ahmad Ali',
        saleDate: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now(),
      ),
      Sale(
        id: '',
        productId: 'dummy2',
        productName: 'USB-C Charger',
        quantity: 1,
        purchasePrice: 300,
        sellingPrice: 450,
        totalAmount: 450,
        profit: 150,
        customerName: 'Fatima Khan',
        saleDate: DateTime.now().subtract(const Duration(hours: 5)),
        createdAt: DateTime.now(),
      ),
      Sale(
        id: '',
        productId: 'dummy3',
        productName: 'Power Bank',
        quantity: 1,
        purchasePrice: 800,
        sellingPrice: 1200,
        totalAmount: 1200,
        profit: 400,
        saleDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
      ),
    ];
    
    for (final sale in dummySales) {
      await addSale(sale);
    }
  }
}